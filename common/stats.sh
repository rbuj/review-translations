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
function populate_db {
   echo "************************************************"
   echo "* populating DB..."
   echo "************************************************"
   sqlite3 ${STATS_DB_PATH} < ${WORK_PATH}/sql/stats_create_tables.sql

   while read -r f; do
      set -- $f
      COMPONENT=
      case $TYPE in
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
      sqlite3 ${STATS_DB_PATH} "INSERT OR IGNORE INTO t_components (name) VALUES ('${COMPONENT}');"
      declare -i id_component=$(sqlite3 ${STATS_DB_PATH} "SELECT id FROM t_components WHERE name = '${COMPONENT}';")
      for LOCALE in $(find ${BASE_PATH}/${COMPONENT} -name *.po -exec basename {} .po \; | sort -u); do
         sqlite3 ${STATS_DB_PATH} "INSERT OR IGNORE INTO t_locales (name) VALUES ('${LOCALE}');"
         declare -i id_locale=$(sqlite3 ${STATS_DB_PATH} "SELECT id FROM t_locales WHERE name = '${LOCALE}';")

         sqlite3 ${STATS_DB_PATH} "INSERT OR IGNORE INTO t_updates (id_component,id_locale) VALUES (${id_component},${id_locale});"
         declare -i id_update=$(sqlite3 ${STATS_DB_PATH} "SELECT id FROM t_updates WHERE id_component = ${id_component} AND id_locale = ${id_locale};")
         declare -i date_file=$(find ${BASE_PATH}/${COMPONENT} -name ${LOCALE}.po -exec date -r {} "+%Y%m%d%H" \; | sort | tail -1)
         declare -i date_report=$(sqlite3 ${STATS_DB_PATH} "SELECT date_report FROM t_updates WHERE id = ${id_update};")

         if [ "${date_report}" -le ${date_file} ]; then
             LC_ALL=en_US.UTF-8 stdbuf -oL posieve stats --include-name=${LOCALE}\$ ${BASE_PATH}/${COMPONENT} |
             while read -r o; do
                set -- $o
                   if [ "${1}" != "-" ];then
                      sqlite3 ${STATS_DB_PATH} "INSERT OR IGNORE INTO t_states (name) VALUES ('${1}');"
                      declare -i id_state=$(sqlite3 ${STATS_DB_PATH} "SELECT id FROM t_states WHERE name = '${1}';")

                      sqlite3 ${STATS_DB_PATH} "INSERT OR IGNORE INTO t_stats ('id_update','id_state','msg','msg_div_tot','w_or','w_div_tot_or','w_tr','ch_or','ch_tr') VALUES (${id_update},${id_state},${2},'${3}',${4},'${5}',${6},${7},${8});"
                      declare -i id_stat=$(sqlite3 ${STATS_DB_PATH} "SELECT id FROM t_stats WHERE id_update = ${id_update} AND id_state = ${id_state};")
                      sqlite3 ${STATS_DB_PATH} "UPDATE t_stats SET msg = ${2}, msg_div_tot = '${3}', w_or = ${4}, w_div_tot_or = '${5}', w_tr = ${6}, ch_or = ${7}, ch_tr = ${8}  WHERE id = ${id_stat};"
                   fi
             done
             declare -i date_file=$(find ${BASE_PATH}/${COMPONENT} -name "${LOCALE}.po" -exec date -r {} "+%Y%m%d%H" \; | sort | tail -1)
             sqlite3 ${STATS_DB_PATH} "UPDATE t_updates SET date_file = ${date_file}, active = 1 WHERE id = ${id_update};"
         else
             sqlite3 ${STATS_DB_PATH} "UPDATE t_updates SET active = 1 WHERE id = ${id_update};"
         fi

      done
   done <${LIST}
   echo "${STATS_DB_PATH}"
}

function png_stat_msg {
   echo "************************************************"
   echo "* message stats..."
   echo "************************************************"
   local PLOT=${DATA_STATS_PATH}/${PROJECT_NAME}-msg.tsv
   local SQL=${WORK_PATH}/sql/stats_png_stat_msg_tsv.sql
   sqlite3 ${STATS_DB_PATH} < ${SQL} | xargs -n5 | perl ${WORK_PATH}/sql/stats_png_stat_msg_tsv.pl - > ${PLOT}
   declare -i NUMPRO=$(($(cat ${PLOT} | wc -l)))
   if [ $? -ne 0 ]; then
       return 1
   fi
   if [ -z "${NUMPRO}" ]; then
       return 1
   fi
   if [ "${NUMPRO}" -eq 0 ]; then
       return 1
   fi
   if [ "$(cat ${PLOT} | wc -c)" -eq "1" ]; then
       rm -f ${PLOT}
       return 0
   fi
   echo "${PLOT}"

   local WIDTH=$((110+$(($NUMPRO*14))))
   local LEGEND=$(($(sqlite3 ${STATS_DB_PATH} < ${WORK_PATH}/sql/stats_png_stat_msg_max_total.sql | wc -c)*10))
   local SIZE=$(($WIDTH+$LEGEND)),480
   local OUTPUT=${DATA_STATS_PATH}/${PROJECT_NAME}-msg.svg
   local NAME=${PROJECT_NAME//-/_}_msg
   sed "s/SIZE/$SIZE/g;s/NAME/$NAME/g;s/OUTPUT/${OUTPUT//\//\\\/}/g;s/PLOT/${PLOT//\//\\\/}/g" ${WORK_PATH}/snippet/gnuplot.project.msg.txt | gnuplot
   chmod 644 "${OUTPUT}"
   echo "${OUTPUT}"
}

function png_stat_msg_locale {
   LOCALE="${1}"

   local PLOT=${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.tsv
   local SQL=${WORK_PATH}/sql/stats_png_stat_msg_locale_tsv.sql
   sed "s/LOCALE/${LOCALE}/g" ${SQL} | sqlite3 ${STATS_DB_PATH} | xargs -n5 | perl -pe 's/^([\w\-\.]*)\|fuzzy\|(\d)*\s[\w\-\.]*\|obsolete\|\d*\s[\w\-\.]*\|total\|\d*\s[\w\-\.]*\|translated\|(\d*)\s[\w\-\.]*\|untranslated\|(\d*).*/$1 $3 $2 $4/g' > ${PLOT}
   declare -i NUMPRO=$(($(cat ${PLOT} | wc -l)))
   if [ $? -ne 0 ]; then
       return 1
   fi
   if [ -z "${NUMPRO}" ]; then
       return 1
   fi
   if [ "${NUMPRO}" -eq 0 ]; then
       return 1
   fi
   if [ "$(cat ${PLOT} | wc -c)" -eq "1" ]; then
       rm -f ${PLOT}.tsv
       return 0
   fi
   echo "${PLOT}"

   local WIDTH=$((200+$(($NUMPRO*14))))
   local LEGEND=$(($(cat ${WORK_PATH}/sql/stats_png_stat_msg_locale_max_total.sql | sed "s/LOCALE/${LOCALE}/g" | sqlite3 ${STATS_DB_PATH} | wc -c)*10))
   local LANGUAGE=$(perl -e "use Locale::Language; print (code2language('${LOCALE:0:2}'));")" ($LOCALE)"
   local SIZE=$(($WIDTH+$LEGEND)),720
   local OUTPUT="${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.svg"
   local NAME=${PROJECT_NAME//-/_}_msg_${LOCALE//-/_}
   sed "s/TITLE/$LANGUAGE/g;s/SIZE/$SIZE/g;s/NAME/$NAME/g;s/OUTPUT/${OUTPUT//\//\\\/}/g;s/PLOT/${PLOT//\//\\\/}/g" ${WORK_PATH}/snippet/gnuplot.language.msg.txt | gnuplot
   chmod 644 "${OUTPUT}"
   echo "${OUTPUT}"
}

function png_stat_w {
   echo "************************************************"
   echo "* word stats..."
   echo "************************************************"
   # LOCALE translated fuzzy untranslated
   local PLOT=${DATA_STATS_PATH}/${PROJECT_NAME}-w.tsv
   sqlite3 ${STATS_DB_PATH} < ${WORK_PATH}/sql/stats_png_stat_w_tsv.sql | xargs -n5 | perl ${WORK_PATH}/sql/stats_png_stat_w_tsv.pl - > ${PLOT}
   declare -i NUMPRO=$(($(cat ${PLOT} | wc -l)))
   if [ $? -ne 0 ]; then
       return 1
   fi
   if [ -z "${NUMPRO}" ]; then
       return 1
   fi
   if [ "${NUMPRO}" -eq 0 ]; then
       return 1
   fi
   if [ "$(cat ${PLOT} | wc -c)" -eq "1" ]; then
       rm -f ${PLOT}
       return 0
   fi
   echo "${PLOT}"

   local WIDTH=$((110+$(($NUMPRO*14))))
   local LEGEND=$(($(sqlite3 ${STATS_DB_PATH} < ${WORK_PATH}/sql/stats_png_stat_w_max_total.sql | wc -c)*10))
   local SIZE=$(($WIDTH+$LEGEND)),480
   local OUTPUT="${DATA_STATS_PATH}/${PROJECT_NAME}-w.svg"
   local NAME=${PROJECT_NAME//-/_}_w

   sed "s/SIZE/$SIZE/g;s/NAME/$NAME/g;s/OUTPUT/${OUTPUT//\//\\\/}/g;s/PLOT/${PLOT//\//\\\/}/g" ${WORK_PATH}/snippet/gnuplot.project.w.txt | gnuplot
   chmod 644 "${OUTPUT}"
   echo "${OUTPUT}"
}

STATS_PATH="${BASE_PATH}/stats"
STATS_DB_PATH="${STATS_PATH}/${PROJECT_NAME}.db"
DATA_STATS_PATH="${BASE_PATH}/stats/${PROJECT_NAME}"

if [ ! -d "${STATS_PATH}" ]; then
    mkdir -p "${STATS_PATH}"
fi

if [ ! -d "${DATA_STATS_PATH}" ]; then
    mkdir -p "${DATA_STATS_PATH}"
fi

if [ ! -d "${BASE_PATH}" ]; then
    exit 1
fi

#########################################
# REQUIRED PACKAGES
#########################################
for REQUIRED_PACKAGE in gnuplot perl-Locale-Codes sqlite pology; do
    rpm -q $REQUIRED_PACKAGE &> /dev/null
    if [ $? -ne 0 ]; then
        echo "report : installing required package : $REQUIRED_PACKAGE"
        VERSION_AUX=( $(cat /etc/fedora-release) )
        set -x
	if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y $REQUIRED_PACKAGE --nogpgcheck; else sudo dnf install -y $REQUIRED_PACKAGE; fi
        set -
    fi
done

populate_db
png_stat_msg
png_stat_w

echo "************************************************"
echo "* message stats by locale..."
echo "************************************************"
for LOCALE in $(sqlite3 ${STATS_DB_PATH} "SELECT name from t_locales;"); do
    png_stat_msg_locale $LOCALE
done

date_report=$(date "+%Y%m%d%H")
sqlite3 ${STATS_DB_PATH} "UPDATE t_updates SET date_report = ${date_report} WHERE active = 1;"
