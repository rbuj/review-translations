#!/bin/bash
# ---------------------------------------------------------------------------
# Copyright 2016, Robert Buj <rbuj@fedoraproject.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License at <http://www.gnu.org/licenses/> for
# more details.
# ---------------------------------------------------------------------------
WORK_PATH=
BASE_PATH=
PROJECT_NAME=
INPUT_FILE=
TRANSLATION_TYPE=
declare -i WIDTH=0

function usage {
    echo "Creates translations stats of ${PROJECT_NAME}"
    echo "    usage : $0 [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -p|--project=PROJECT  Base PROJECT folder for downloaded files"
    echo "   -f|--file=INPUT_FILE  INPUT_FILE that contains the project info"
    echo "   -w|--workpath=W_PATH  Work PATH folder"
    echo "   -t|--type=TYPE        TYPE of translation sorce one of fedora, git, transifex"
    echo -ne "\nOptional arguments:\n"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

function populate_db {
   echo "************************************************"
   echo "* populating DB..."
   echo "************************************************"
   sqlite3 ${DB_PATH} < ${WORK_PATH}/sql/stats_create_tables.sql

   while read -r f; do
      set -- $f
      COMPONENT=
      case $TRANSLATION_TYPE in
         fedora)
            COMPONENT="${1}-${2}"
         ;;
         git|transifex)
            COMPONENT="${1}"
         ;;
         *)
            usage
            exit 1
         ;;
      esac

      if [ ! -d "${BASE_PATH}/${COMPONENT}" ]; then
          continue
      fi
      sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO t_components (name) VALUES ('${COMPONENT}');"
      declare -i id_component=$(sqlite3 ${DB_PATH} "SELECT id FROM t_components WHERE name = '${COMPONENT}';")
      for LOCALE in $(find ${BASE_PATH}/${COMPONENT} -name *.po -exec basename {} .po \; | sort -u); do
         sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO t_locales (name) VALUES ('${LOCALE}');"
         declare -i id_locale=$(sqlite3 ${DB_PATH} "SELECT id FROM t_locales WHERE name = '${LOCALE}';")

         sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO t_updates (id_component,id_locale) VALUES (${id_component},${id_locale});"
         declare -i id_update=$(sqlite3 ${DB_PATH} "SELECT id FROM t_updates WHERE id_component = ${id_component} AND id_locale = ${id_locale};")
         declare -i date_file=$(find ${BASE_PATH}/${COMPONENT} -name ${LOCALE}.po -exec date -r {} "+%Y%m%d" \; | sort | tail -1)
         declare -i date_report=$(sqlite3 ${DB_PATH} "SELECT date_report FROM t_updates WHERE id = ${id_update};")

         if [ "${date_report}" -le ${date_file} ]; then
             stdbuf -oL posieve stats --include-name=${LOCALE}\$  ${BASE_PATH}/${COMPONENT} |
             while read -r o; do
                set -- $o
                   if [ "${1}" != "-" ];then
                      sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO t_states (name) VALUES ('${1}');"
                      declare -i id_state=$(sqlite3 ${DB_PATH} "SELECT id FROM t_states WHERE name = '${1}';")

                      sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO t_stats ('id_update','id_state','msg','msg_div_tot','w_or','w_div_tot_or','w_tr','ch_or','ch_tr') VALUES (${id_update},${id_state},${2},'${3}',${4},'${5}',${6},${7},${8});"
                      declare -i id_stat=$(sqlite3 ${DB_PATH} "SELECT id FROM t_stats WHERE id_update = ${id_update} AND id_state = ${id_state};")
                      sqlite3 ${DB_PATH} "UPDATE t_stats SET msg = ${2}, msg_div_tot = '${3}', w_or = ${4}, w_div_tot_or = '${5}', w_tr = ${6}, ch_or = ${7}, ch_tr = ${8}  WHERE id = ${id_stat};"
                   fi
             done
             declare -i date_file=$(find ${BASE_PATH}/${COMPONENT} -name "${LOCALE}.po" -exec date -r {} "+%Y%m%d" \; | sort | tail -1)
             sqlite3 ${DB_PATH} "UPDATE t_updates SET date_file = ${date_file}, active = 1 WHERE id = ${id_update};"
         else
             sqlite3 ${DB_PATH} "UPDATE t_updates SET active = 1 WHERE id = ${id_update};"
         fi

      done
   done <${INPUT_FILE}
   echo "${DB_PATH}"
}

function png_stat_msg {
   echo "************************************************"
   echo "* message stats..."
   echo "************************************************"
   sqlite3 ${DB_PATH} < ${WORK_PATH}/sql/stats_png_stat_msg_tsv.sql | xargs -n5 | perl ${WORK_PATH}/sql/stats_png_stat_msg_tsv.pl - > ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.tsv

   declare -i NUMPRO=$(($(cat ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.tsv | wc -l)))
   if [ $? -ne 0 ]; then
       return 1
   fi
   if [ -z "${NUMPRO}" ]; then
       return 1
   fi
   if [ "${NUMPRO}" -eq 0 ]; then
       return 1
   fi
   if [ "$(cat ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.tsv | wc -c)" -eq "1" ]; then
       rm -f ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.tsv
       return 0
   fi
   echo "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.tsv"
   WIDTH=$((110+$(($NUMPRO*14))))
   LEGEND=$(($(sqlite3 ${DB_PATH} < ${WORK_PATH}/sql/stats_png_stat_msg_max_total.sql | wc -c)*10))

   echo -ne 'set output "'${DATA_STATS_PATH}/${PROJECT_NAME}'-msg.svg"\n'\
      'set terminal svg size '$(($WIDTH+$LEGEND))',480 noenhanced name "'${PROJECT_NAME//-/_}'"\n'\
      'set boxwidth 0.8\n'\
      'set style fill solid 1.00 border 0\n'\
      'set style data histogram\n'\
      'set style histogram rowstacked\n'\
      'set key outside horizontal center bottom font ",10"\n'\
      'set ylabel "messages"\n'\
      'set xtics rotate font ",10"\n'\
      'plot "'${DATA_STATS_PATH}/${PROJECT_NAME}'-msg.tsv" using 2:xticlabels(1) lt rgb "#406090" title "translated", "" using 3 title "fuzzy", "" using 4 title "untranslated"' | gnuplot
   chmod 644 "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.svg"
   echo "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.svg"
}

function png_stat_msg_locale {
   LOCALE="${1}"

   cat ${WORK_PATH}/sql/stats_png_stat_msg_locale_tsv.sql | sed "s/LOCALE/${LOCALE}/g" | sqlite3 ${DB_PATH} | xargs -n5 | perl -pe 's/^([\w\-\.]*)\|fuzzy\|(\d)*\s[\w\-\.]*\|obsolete\|\d*\s[\w\-\.]*\|total\|\d*\s[\w\-\.]*\|translated\|(\d*)\s[\w\-\.]*\|untranslated\|(\d*).*/$1 $3 $2 $4/g' > ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.tsv

   declare -i NUMPRO=$(($(cat ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.tsv | wc -l)))
   if [ $? -ne 0 ]; then
       return 1
   fi
   if [ -z "${NUMPRO}" ]; then
       return 1
   fi
   if [ "${NUMPRO}" -eq 0 ]; then
       return 1
   fi
   if [ "$(cat ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.tsv | wc -c)" -eq "1" ]; then
       rm -f ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.tsv
       return 0
   fi
   echo "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.tsv"
   WIDTH=$((200+$(($NUMPRO*14))))
   LEGEND=$(($(cat ${WORK_PATH}/sql/stats_png_stat_msg_locale_max_total.sql | sed "s/LOCALE/${LOCALE}/g" | sqlite3 ${DB_PATH} | wc -c)*10))

   echo -ne 'set output "'${DATA_STATS_PATH}/${PROJECT_NAME}'-msg.'${LOCALE}'.svg"\n'\
      'set terminal svg size '$(($WIDTH+$LEGEND))',720 noenhanced name "'${PROJECT_NAME//-/_}'"\n'\
      'set boxwidth 0.8\n'\
      'set title "locale: '${LOCALE}'"\n'\
      'set style fill solid 1.00 border 0\n'\
      'set style data histogram\n'\
      'set style histogram rowstacked\n'\
      'set key outside right vertical font ",10"\n'\
      'set ylabel "messages"\n'\
      'set xtics rotate font ",10"\n'\
      'plot "'${DATA_STATS_PATH}/${PROJECT_NAME}'-msg.'${LOCALE}'.tsv" using 2:xticlabels(1) lt rgb "#406090" title "translated", "" using 3 title "fuzzy", "" using 4 title "untranslated"' | gnuplot
   chmod 644 "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.svg"
   echo "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.svg"
}

function png_stat_w {
   echo "************************************************"
   echo "* word stats..."
   echo "************************************************"
   # LOCALE translated fuzzy untranslated
   sqlite3 ${DB_PATH} < ${WORK_PATH}/sql/stats_png_stat_w_tsv.sql | xargs -n5 | perl ${WORK_PATH}/sql/stats_png_stat_w_tsv.pl - > ${DATA_STATS_PATH}/${PROJECT_NAME}-w.tsv

   declare -i NUMPRO=$(($(cat ${DATA_STATS_PATH}/${PROJECT_NAME}-w.tsv | wc -l)))
   if [ $? -ne 0 ]; then
       return 1
   fi
   if [ -z "${NUMPRO}" ]; then
       return 1
   fi
   if [ "${NUMPRO}" -eq 0 ]; then
       return 1
   fi
   if [ "$(cat ${DATA_STATS_PATH}/${PROJECT_NAME}-w.tsv | wc -c)" -eq "1" ]; then
       rm -f ${DATA_STATS_PATH}/${PROJECT_NAME}-w.tsv
       return 0
   fi
   echo "${DATA_STATS_PATH}/${PROJECT_NAME}-w.tsv"
   WIDTH=$((110+$(($NUMPRO*14))))
   LEGEND=$(($(sqlite3 ${DB_PATH} < ${WORK_PATH}/sql/stats_png_stat_w_max_total.sql | wc -c)*10))

   echo -ne 'set output "'${DATA_STATS_PATH}/${PROJECT_NAME}'-w.svg"\n'\
      'set terminal svg size '$(($WIDTH+$LEGEND))',480 noenhanced name "'${PROJECT_NAME//-/_}'"\n'\
      'set boxwidth 0.8\n'\
      'set style fill solid 1.00 border 0\n'\
      'set style data histogram\n'\
      'set style histogram rowstacked\n'\
      'set key outside horizontal center bottom font ",10"\n'\
      'set ylabel "words"\n'\
      'set xtics rotate font ",10"\n'\
      'plot "'${DATA_STATS_PATH}/${PROJECT_NAME}'-w.tsv" using 2:xticlabels(1) lt rgb "#406090" title "translated", "" using 3 title "fuzzy", "" using 4 title "untranslated"' | gnuplot
   chmod 644 "${DATA_STATS_PATH}/${PROJECT_NAME}-w.svg"
   echo "${DATA_STATS_PATH}/${PROJECT_NAME}-w.svg"
}

for i in "$@"
do
case $i in
    -p=*|--project=*)
    PROJECT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    -f=*|--file=*)
    INPUT_FILE="${i#*=}"
    shift # past argument=value
    ;;
    -w=*|--workpath=*)
    WORK_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -t=*|--type=*)
    TRANSLATION_TYPE="${i#*=}"
    shift # past argument=value
    ;;
    -h|--help)
    usage
    exit 0
    ;;
    *)
    usage
    exit 1
    ;;
esac
done

if [ -z "${INPUT_FILE}" ] || [ -z "${PROJECT_NAME}" ] || [ -z "${WORK_PATH}" ] || [ -z "${TRANSLATION_TYPE}" ]; then
    usage
    exit 1
fi

BASE_PATH="${WORK_PATH}/${PROJECT_NAME}"
STATS_PATH="${BASE_PATH}/stats"
DB_PATH="${STATS_PATH}/${PROJECT_NAME}.db"
DATA_STATS_PATH="${BASE_PATH}/stats/${PROJECT_NAME}"

if [ ! -d "${STATS_PATH}" ]; then
    mkdir -p "${STATS_PATH}"
fi

if [ ! -d "${DATA_STATS_PATH}" ]; then
    mkdir -p "${DATA_STATS_PATH}"
fi

export PYTHONPATH=${WORK_PATH}/pology:$PYTHONPATH
export PATH=${WORK_PATH}/pology/bin:$PATH
if [ ! -d "${BASE_PATH}" ]; then
    exit 1
fi

rpm -q gnuplot sqlite perl ImageMagick &> /dev/null
if [ $? -ne 0 ]; then
    echo "download : installing required packages"
    local VERSION_AUX=( $(cat /etc/fedora-release) )
    if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y gnuplot sqlite perl ImageMagick --nogpgcheck; else sudo dnf install -y gnuplot sqlite perl ImageMagick; fi
fi

populate_db
png_stat_msg
png_stat_w

echo "************************************************"
echo "* message stats by locale..."
echo "************************************************"
for LOCALE in $(sqlite3 ${DB_PATH} "SELECT name from t_locales;"); do
    png_stat_msg_locale $LOCALE
done

date_report=$(date "+%Y%m%d")
sqlite3 ${DB_PATH} "UPDATE t_updates SET date_report = ${date_report} WHERE active = 1;"
