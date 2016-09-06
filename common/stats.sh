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
declare -A LOCALES
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
   if [ -f "${DB_PATH}" ]; then
       rm -f ${DB_PATH}
   fi
   sqlite3 ${DB_PATH}  "create table n (id INTEGER PRIMARY KEY, 'project' TEXT, 'locale' TEXT,'state' TEXT, 'msg' INTEGER, 'msg_div_tot' TEXT, 'w_or' INTEGER, 'w_div_tot_or' TEXT, 'w_tr' INTEGER, 'ch_or' INTEGER, 'ch_tr' INTEGER);"
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
      for LOCALE in $(find ${BASE_PATH}/${COMPONENT} -name *.po -exec basename {} .po \; | sort -u); do
         stdbuf -oL posieve stats --include-name=${LOCALE}\$  ${BASE_PATH}/${COMPONENT} |
         while read -r o; do
            set -- $o
               if [ "${1}" != "-" ];then
                  echo "sqlite3 ${DB_PATH}  \"insert into n ('project','locale','state','msg','msg_div_tot','w_or','w_div_tot_or','w_tr','ch_or','ch_tr') values ('"${COMPONENT}"','"${LOCALE}"','${1}','${2}','${3}','${4}','${5}','${6}','${7}','${8}');\"" | sh
               fi
         done
      done
   done <${INPUT_FILE}
   echo "${DB_PATH}"
}

function png_stat_msg {
   WIDTH=$((110+$(($(sqlite3 ${DB_PATH} "select count(locale) from (select locale, sum(msg) as result from n where state='translated' group by locale) where result>0")*14))))
   echo "************************************************"
   echo "* message stats..."
   echo "************************************************"
   if [ -f "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.tsv" ]; then
      rm -f ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.tsv
   fi

   for LOCALE in $(sqlite3 ${DB_PATH} "select locale from (select locale, sum(msg) as result from n where state='translated' group by locale) where result>0"); do
      translated=$(sqlite3 ${DB_PATH} "select sum(msg) from n where locale='${LOCALE}' and state='translated'";)
      fuzzy=$(sqlite3 ${DB_PATH} "select sum(msg) from n where locale='${LOCALE}' and state='fuzzy'";)
      untranslated=$(sqlite3 ${DB_PATH} "select sum(msg) from n where locale='${LOCALE}' and state='untranslated'";)
      echo "${LOCALE} ${translated} ${fuzzy} ${untranslated}" >> ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.tsv
   done
   echo "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.tsv"

   LEGEND=$(($(sqlite3 ${DB_PATH} "select max(result) from (select sum(msg) as result from n where state='total' group by locale)" | wc -c)*10))
   echo -ne 'set output "'${DATA_STATS_PATH}/${PROJECT_NAME}'-msg.png"\n'\
      'set term png size '$(($WIDTH+$LEGEND))',480 noenhanced\n'\
      'set boxwidth 0.8\n'\
      'set style fill solid 1.00 border 0\n'\
      'set style data histogram\n'\
      'set style histogram rowstacked\n'\
      'set key outside horizontal center bottom font ",10"\n'\
      'set ylabel "messages"\n'\
      'set xtics rotate font ",10"\n'\
      'plot "'${DATA_STATS_PATH}/${PROJECT_NAME}'-msg.tsv" using 2:xticlabels(1) lt rgb "#406090" title "translated", "" using 3 title "fuzzy", "" using 4 title "untranslated"' | gnuplot
   chmod 644 "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.png"
   echo "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.png"
}

function png_stat_msg_locale {
   LOCALE="${1}"
   declare -i NUMPRO=$(($(sqlite3 ${DB_PATH} "select count(result) from (select project as result from n where locale='${LOCALE}' and state='translated' and msg>0)")))
   if [ $NUMPRO -gt 0 ]; then
       WIDTH=$((260+$(($NUMPRO*14))))

       echo "************************************************"
       echo "* message stats..."
       echo "************************************************"
       if [ -f "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.tsv" ]; then
          rm -f ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.tsv
       fi

       for COMPONENT in $(sqlite3 ${DB_PATH} "select project from n where locale='${LOCALE}' and state='translated' and msg>0";); do
          translated=$(sqlite3 ${DB_PATH} "select msg from n where locale='${LOCALE}' and state='translated' and project='$COMPONENT'";)
          fuzzy=$(sqlite3 ${DB_PATH} "select msg from n where locale='${LOCALE}' and state='fuzzy' and project='$COMPONENT'";)
          untranslated=$(sqlite3 ${DB_PATH} "select msg from n where locale='${LOCALE}' and state='untranslated' and project='$COMPONENT'";)
          echo "${COMPONENT} ${translated} ${fuzzy} ${untranslated}" >> ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.tsv
       done
       echo "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.tsv"

       LEGEND=$(($(sqlite3 ${DB_PATH} "select max(msg) from n where state='total' and locale='${LOCALE}'" | wc -c)*10))
       echo -ne 'set output "'${DATA_STATS_PATH}/${PROJECT_NAME}'-msg.'${LOCALE}'.png"\n'\
          'set term png size '$(($WIDTH+$LEGEND))',720 noenhanced\n'\
          'set boxwidth 0.8\n'\
          'set title "locale: '${LOCALE}'"\n'\
          'set style fill solid 1.00 border 0\n'\
          'set style data histogram\n'\
          'set style histogram rowstacked\n'\
          'set key outside right vertical font ",10"\n'\
          'set ylabel "messages"\n'\
          'set xtics rotate font ",10"\n'\
          'plot "'${DATA_STATS_PATH}/${PROJECT_NAME}'-msg.'${LOCALE}'.tsv" using 2:xticlabels(1) lt rgb "#406090" title "translated", "" using 3 title "fuzzy", "" using 4 title "untranslated"' | gnuplot
       chmod 644 "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.png"
       echo "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.png"
   fi
}

function png_stat_w {
   WIDTH=$((110+$(($(sqlite3 ${DB_PATH} "select count(locale) from (select locale, sum(msg) as result from n where state='translated' group by locale) where result>0")*14))))
   echo "************************************************"
   echo "* word stats..."
   echo "************************************************"
   if [ -f "${DATA_STATS_PATH}/${PROJECT_NAME}-w.tsv" ]; then
      rm -f ${DATA_STATS_PATH}/${PROJECT_NAME}-w.tsv
   fi

   for LOCALE in $(sqlite3 ${DB_PATH} "select locale from (select locale, sum(msg) as result from n where state='translated' group by locale) where result>0"); do
      translated=$(sqlite3 ${DB_PATH} "select sum(w_or) from n where locale='${LOCALE}' and state='translated'";)
      fuzzy=$(sqlite3 ${DB_PATH} "select sum(w_or) from n where locale='${LOCALE}' and state='fuzzy'";)
      untranslated=$(sqlite3 ${DB_PATH} "select sum(w_or) from n where locale='${LOCALE}' and state='untranslated'";)
      echo "${LOCALE} ${translated} ${fuzzy} ${untranslated}" >> ${DATA_STATS_PATH}/${PROJECT_NAME}-w.tsv
   done
   echo "${DATA_STATS_PATH}/${PROJECT_NAME}-w.tsv"

   LEGEND=$(($(sqlite3 ${DB_PATH} "select max(result) from (select sum(w_or) as result from n where state='total' group by locale)" | wc -c)*10))
   echo -ne 'set output "'${DATA_STATS_PATH}/${PROJECT_NAME}'-w.png"\n'\
      'set term png size '$(($WIDTH+$LEGEND))',480 noenhanced\n'\
      'set boxwidth 0.8\n'\
      'set style fill solid 1.00 border 0\n'\
      'set style data histogram\n'\
      'set style histogram rowstacked\n'\
      'set key outside horizontal center bottom font ",10"\n'\
      'set ylabel "words"\n'\
      'set xtics rotate font ",10"\n'\
      'plot "'${DATA_STATS_PATH}/${PROJECT_NAME}'-w.tsv" using 2:xticlabels(1) lt rgb "#406090" title "translated", "" using 3 title "fuzzy", "" using 4 title "untranslated"' | gnuplot
   chmod 644 "${DATA_STATS_PATH}/${PROJECT_NAME}-w.png"
   echo "${DATA_STATS_PATH}/${PROJECT_NAME}-w.png"
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
LOCALES=$(find ${BASE_PATH} -name *.po -exec basename {} .po \; | sort -u)

rpm -q gnuplot sqlite &> /dev/null
if [ $? -ne 0 ]; then
    echo "download : installing required packages"
    local VERSION_AUX=( $(cat /etc/fedora-release) )
    if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y gnuplot sqlite --nogpgcheck; else sudo dnf install -y gnuplot sqlite; fi
fi

populate_db
png_stat_msg
png_stat_w

for LOCALE in ${LOCALES[@]}; do
    png_stat_msg_locale $LOCALE
done
