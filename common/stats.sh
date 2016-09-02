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
   if [ -f "${BASE_PATH}/${PROJECT_NAME}.db" ]; then
       rm -f ${BASE_PATH}/${PROJECT_NAME}.db
   fi
   sqlite3 ${BASE_PATH}/${PROJECT_NAME}.db  "create table n (id INTEGER PRIMARY KEY, 'project' TEXT, 'locale' TEXT,'state' TEXT, 'msg' INTEGER, 'msg_div_tot' TEXT, 'w_or' INTEGER, 'w_div_tot_or' TEXT, 'w_tr' INTEGER, 'ch_or' INTEGER, 'ch_tr' INTEGER);"
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

      for LOCALE in ${LOCALES[@]}; do
         stdbuf -oL posieve stats --include-name=${LOCALE}\$  ${BASE_PATH}/${COMPONENT} |
         while read -r o; do
            set -- $o
               if [ "${1}" != "-" ];then
                  echo "sqlite3 ${BASE_PATH}/${PROJECT_NAME}.db  \"insert into n ('project','locale','state','msg','msg_div_tot','w_or','w_div_tot_or','w_tr','ch_or','ch_tr') values ('"${COMPONENT}"','"${LOCALE}"','${1}','${2}','${3}','${4}','${5}','${6}','${7}','${8}');\"" | sh
               fi
         done
      done
   done <${INPUT_FILE}
   echo "${BASE_PATH}/${PROJECT_NAME}.db"
}

function png_stat_msg {
   echo "************************************************"
   echo "* message stats..."
   echo "************************************************"
   if [ -f "${BASE_PATH}/${PROJECT_NAME}-msg.tsv" ]; then
      rm -f ${BASE_PATH}/${PROJECT_NAME}-msg.tsv
   fi

   for LOCALE in ${LOCALES[@]}; do
      translated=$(sqlite3 ${BASE_PATH}/${PROJECT_NAME}.db "select sum(msg) from n where locale='${LOCALE}' and state='translated'";)
      fuzzy=$(sqlite3 ${BASE_PATH}/${PROJECT_NAME}.db "select sum(msg) from n where locale='${LOCALE}' and state='fuzzy'";)
      untranslated=$(sqlite3 ${BASE_PATH}/${PROJECT_NAME}.db "select sum(msg) from n where locale='${LOCALE}' and state='untranslated'";)
      if [ "${translated}" != "0" ]; then
          echo "${LOCALE} ${translated} ${fuzzy} ${untranslated}" >> ${BASE_PATH}/${PROJECT_NAME}-msg.tsv
      fi
   done
   echo "${BASE_PATH}/${PROJECT_NAME}-msg.tsv"

   LEGEND=$(($(sqlite3 ${BASE_PATH}/${PROJECT_NAME}.db "select max(msg) from n where state='total'" | wc -c)*12))
   echo -ne 'set output "'${BASE_PATH}/${PROJECT_NAME}'-msg.png"\n'\
      'set term png size '$(($WIDTH+$LEGEND))',480 noenhanced\n'\
      'set boxwidth 0.8\n'\
      'set style fill solid 1.00 border 0\n'\
      'set style data histogram\n'\
      'set style histogram rowstacked\n'\
      'set key outside horizontal center bottom font ",10"\n'\
      'set ylabel "messages"\n'\
      'set xtics rotate font ",10"\n'\
      'plot "'${BASE_PATH}/${PROJECT_NAME}'-msg.tsv" using 2:xticlabels(1) lt rgb "#406090" title "translated", "" using 3 title "fuzzy", "" using 4 title "untranslated"' | gnuplot
   chmod 644 "${BASE_PATH}/${PROJECT_NAME}-msg.png"
   echo "${BASE_PATH}/${PROJECT_NAME}-msg.png"
}

function png_stat_w {
   echo "************************************************"
   echo "* word stats..."
   echo "************************************************"
   if [ -f "${BASE_PATH}/${PROJECT_NAME}-w.tsv" ]; then
      rm -f ${BASE_PATH}/${PROJECT_NAME}-w.tsv
   fi

   for LOCALE in ${LOCALES[@]}; do
      translated=$(sqlite3 ${BASE_PATH}/${PROJECT_NAME}.db "select sum(w_or) from n where locale='${LOCALE}' and state='translated'";)
      fuzzy=$(sqlite3 ${BASE_PATH}/${PROJECT_NAME}.db "select sum(w_or) from n where locale='${LOCALE}' and state='fuzzy'";)
      untranslated=$(sqlite3 ${BASE_PATH}/${PROJECT_NAME}.db "select sum(w_or) from n where locale='${LOCALE}' and state='untranslated'";)
      if [ "${translated}" != "0" ]; then
          echo "${LOCALE} ${translated} ${fuzzy} ${untranslated}" >> ${BASE_PATH}/${PROJECT_NAME}-w.tsv
      fi
   done
   echo "${BASE_PATH}/${PROJECT_NAME}-w.tsv"

   LEGEND=$(($(sqlite3 ${BASE_PATH}/${PROJECT_NAME}.db "select max(msg) from n where state='total'" | wc -c)*12))
   echo -ne 'set output "'${BASE_PATH}/${PROJECT_NAME}'-w.png"\n'\
      'set term png size '$(($WIDTH+$LEGEND))',480 noenhanced\n'\
      'set boxwidth 0.8\n'\
      'set style fill solid 1.00 border 0\n'\
      'set style data histogram\n'\
      'set style histogram rowstacked\n'\
      'set key outside horizontal center bottom font ",10"\n'\
      'set ylabel "words"\n'\
      'set xtics rotate font ",10"\n'\
      'plot "'${BASE_PATH}/${PROJECT_NAME}'-w.tsv" using 2:xticlabels(1) lt rgb "#406090" title "translated", "" using 3 title "fuzzy", "" using 4 title "untranslated"' | gnuplot
   chmod 644 "${BASE_PATH}/${PROJECT_NAME}-w.png"
   echo "${BASE_PATH}/${PROJECT_NAME}-w.png"
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

BASE_PATH=${WORK_PATH}/${PROJECT_NAME}
export PYTHONPATH=${WORK_PATH}/pology:$PYTHONPATH
export PATH=${WORK_PATH}/pology/bin:$PATH
LOCALES=$(find ${BASE_PATH} -name *.po -exec basename {} .po \; | sort -u)
WIDTH=$((110+$(($(find ${BASE_PATH} -name *.po -exec basename {} .po \; | sort -u | wc -l)*14))))

rpm -q gnuplot sqlite &> /dev/null
if [ $? -ne 0 ]; then
    echo "download : installing required packages"
    VERSION_AUX=( $(cat /etc/fedora-release) )
    if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y gnuplot sqlite --nogpgcheck; else sudo dnf install -y gnuplot sqlite; fi
fi

populate_db
png_stat_msg
png_stat_w
