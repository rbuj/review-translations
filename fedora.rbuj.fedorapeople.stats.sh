#!/bin/bash

export PYTHONPATH=${PWD}/pology:$PYTHONPATH
export PATH=${PWD}/pology/bin:$PATH
LOCALES=( ca de es el fr gl it nl pt ru )

function populate_db {
   rm -f test.db
   sqlite3 test.db  "create table n (id INTEGER PRIMARY KEY, 'filename' TEXT, 'state' TEXT, 'msg' INTEGER, 'msg_div_tot' TEXT, 'w_or' INTEGER, 'w_div_tot_or' TEXT, 'w_tr' INTEGER, 'ch_or' INTEGER, 'ch_tr' INTEGER);"
   for FILE in $(find fedora-* -name *.po); do
      stdbuf -oL posieve stats $FILE |
      while read -r p; do
         set -- $p
            if [ "${1}" != "-" ];then
               echo "sqlite3 test.db  \"insert into n ('filename','state','msg','msg_div_tot','w_or','w_div_tot_or','w_tr','ch_or','ch_tr') values ('"${FILE}"','${1}','${2}','${3}','${4}','${5}','${6}','${7}','${8}');\"" | sh
            fi
      done
   done
}

function png_stat_msg {
   pattern="fedora-${1}"
   type="${2}"

   if [ -f "${pattern}-msg.tsv" ]; then
      rm -f ${pattern}-msg.tsv
   fi

   for LOCALE in ${LOCALES[@]}; do
      translated=$(sqlite3 test.db "select sum(msg) from n where filename like '%${LOCALE}.po' and filename like '${pattern}%' and state='translated'";)
      fuzzy=$(sqlite3 test.db "select sum(msg) from n where filename like '%${LOCALE}.po' and filename like '${pattern}%' and state='fuzzy'";)
      untranslated=$(sqlite3 test.db "select sum(msg) from n where filename like '%${LOCALE}.po' and filename like '${pattern}%' and state='untranslated'";)
      echo "${LOCALE} ${translated} ${fuzzy} ${untranslated}" >> ${pattern}-msg.tsv
   done

   echo -ne 'set output "'${pattern}'-msg.png"\n'\
      'set term png\n'\
      'set boxwidth 1\n'\
      'set style fill solid 1.00 border 0\n'\
      'set style data histogram\n'\
      'set style histogram rowstacked\n'\
      'set key outside horizontal center bottom\n'\
      'plot "'${pattern}'-msg.tsv" using 2:xticlabels(1) lt rgb "#406090" title "translated", "" using 3 title "fuzzy", "" using 4 title "untranslated"' | gnuplot
}

function png_stat_w {
   pattern="fedora-${1}"
   type="${2}"

   if [ -f "${pattern}-w.tsv" ]; then
      rm -f ${pattern}-w.tsv
   fi

   for LOCALE in ${LOCALES[@]}; do
      translated=$(sqlite3 test.db "select sum(w_or) from n where filename like '%${LOCALE}.po' and filename like '${pattern}%' and state='translated'";)
      fuzzy=$(sqlite3 test.db "select sum(w_or) from n where filename like '%${LOCALE}.po' and filename like '${pattern}%' and state='fuzzy'";)
      untranslated=$(sqlite3 test.db "select sum(w_or) from n where filename like '%${LOCALE}.po' and filename like '${pattern}%' and state='untranslated'";)
      echo "${LOCALE} ${translated} ${fuzzy} ${untranslated}" >> ${pattern}-w.tsv
   done

   echo -ne 'set output "'${pattern}'-w.png"\n'\
      'set term png\n'\
      'set boxwidth 1\n'\
      'set style fill solid 1.00 border 0\n'\
      'set style data histogram\n'\
      'set style histogram rowstacked\n'\
      'set key outside horizontal center bottom\n'\
      'plot "'${pattern}'-w.tsv" using 2:xticlabels(1) lt rgb "#406090" title "translated", "" using 3 title "fuzzy", "" using 4 title "untranslated"' | gnuplot
}

populate_db

for GROUP in main upstream web; do
   png_stat_msg ${GROUP}
   png_stat_w ${GROUP}
done

chmod 644 *.png
scp -i ~/.ssh/id_rsa *.png rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/img
rm -f *.png *.db *.tsv
