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
RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0` # No Color

WORK_PATH=
BASE_PATH=

PROJECT_NAME=
INPUT_FILE=

LANG_CODE=

DISABLE_WORDLIST=

function usage {
    echo "This script downloads the translation of ${PROJECT_NAME}"
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo "   -p|--project=PROJECT  Base PROJECT folder for downloaded files"
    echo "   -f|--file=INPUT_FILE  INPUT_FILE that contains the project info"
    echo "   -w|--workpath=W_PATH  Work PATH folder"
    echo -ne "\nOptional arguments:\n"
    echo "   --disable-wordlist    Do not use wordlist file"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

function fedora_wordlist {
    DICT=${WORK_PATH}/pology/lang/${LANG_CODE}/spell/report-fedora.aspell
    if [ -n "${DISABLE_WORDLIST}" ]; then
        if [ -f "${DICT}" ]; then
            rm -f ${DICT}
        fi
    else
        if [ ! -d "${WORK_PATH}/pology/lang/${LANG_CODE}/spell" ]; then
            mkdir -p ${WORK_PATH}/pology/lang/${LANG_CODE}/spell
        fi
        WORDS=`cat ${WORK_PATH}/wordlist | wc -l`
        echo "personal_ws-1.1 ${LANG_CODE} ${WORDS} utf-8" > ${DICT}
        cat ${WORK_PATH}/wordlist >> ${DICT}
    fi
}

function report_toc {
    HTML_REPORT=${1}
    cat << EOF >> ${HTML_REPORT}
<h1 id=toc>Table of contents</h1>
<div data-fill-with="table-of-contents"><ul class="toc">
EOF
    COUNTER=1
    while read -r p; do
        set -- $p
        cat << EOF >> ${HTML_REPORT}
  <li><span class="secno">${COUNTER}</span> <span><a href="#${1}">${1}</a></span></li>
EOF
        let "COUNTER++"
    done <${LIST}
    cat << EOF >> ${HTML_REPORT}
<ul></div>
EOF
}

# project_name html_filename
function report_project_cotent {
if [ ! -f "${BASE_PATH}/${1}/po/${LANG_CODE}.po" ]; then
    cat << EOF >> $2
<h1 id=${1}>${1}<a href="#toc">[^]</a></h1>
ERROR: File not found.
EOF
else
    cat << EOF >> $2
<h1 id=${1}>${1}<a href="#toc">[^]</a></h1>
<h2 id=CheckSpellEc${1}>check-spell-ec <a href="#toc">[^]</a></h2>
EOF
    posieve check-spell-ec -s lang:${LANG_CODE} --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${1}/po/ >> $2
    cat << EOF >> $2
<h2 id=CheckRules${1}>check-rules <a href="#toc">[^]</a></h2>
EOF
    posieve check-rules -s lang:${LANG_CODE} -s showfmsg --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${1}/po/ >> $2
    cat << EOF >> $2
<h2 id=CheckGrammar${1}>check-grammar <a href="#toc">[^]</a></h2>
EOF
    posieve check-grammar -s lang:${LANG_CODE} --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${1}/po/ >> $2
fi
}

function report {
    echo "************************************************"
    echo "* checking translations..."
    echo "************************************************"
    rpm -q aspell-${LANG_CODE} python-enchant enchant-aspell &> /dev/null
    if [ $? -ne 0 ]; then
        echo "report : installing required packages"
        VERSION_AUX=( $(cat /etc/fedora-release) )
        set -x
        if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y aspell-${LANG_CODE} python-enchant enchant-aspell --nogpgcheck; else sudo dnf install -y aspell-${LANG_CODE} python-enchant enchant-aspell; fi
        set -
    fi
    #########################################
    # LANGUAGETOOL
    #########################################
    if [ ! -d "${WORK_PATH}/languagetool" ]; then
        ${WORK_PATH}/common/build-languagetool.sh --path=${WORK_PATH} -l=${LANG_CODE}
    fi
    cd ${WORK_PATH}
    LANGUAGETOOL=`find . -name 'languagetool-server.jar'`
    java -cp $LANGUAGETOOL org.languagetool.server.HTTPServer --port 8081 > /dev/null &
    LANGUAGETOOL_PID=$!

    echo -ne "report : waiting for langtool"
    until $(curl --output /dev/null --silent --data "language=ca&text=Hola món!" --fail http://localhost:8081); do
        printf '.'
        sleep 1
    done
    if [ $? -ne 0 ]; then
        echo " ${RED}[ FAIL ]${NC}"
    else
        echo " ${GREEN}[ OK ]${NC}"
    fi

    #########################################
    # POLOGY
    #########################################
    if [ ! -d "${WORK_PATH}/pology" ]; then
        ${WORK_PATH}/common/build-pology.sh --path=${WORK_PATH}
    fi
    export PYTHONPATH=${WORK_PATH}/pology:$PYTHONPATH
    export PATH=${WORK_PATH}/pology/bin:$PATH
    fedora_wordlist

    HTML_REPORT=${WORK_PATH}/${PROJECT_NAME}-report.html
    cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html lang="${LANG_CODE}" xml:lang="${LANG_CODE}" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Translation Report</title>
    <style type="text/css">
        /* unvisited link */
        a:link {
            color: #D0D0D0;
        }

        /* visited link */
        a:visited {
            color: #00FF00;
        }

        /* mouse over link */
        a:hover {
            color: #FF00FF;
        }

        /* selected link */
        a:active {
            color: #0000FF;
        }
    </style>
  </head>
<body bgcolor="#080808" text="#D0D0D0">
EOF

    report_toc ${HTML_REPORT}
    COUNTER=1
    if [ ! -d "${BASE_PATH}" ]; then
        mkdir -p "${BASE_PATH}"
    fi
    while read -r p; do
        set -- $p
        echo -ne "${1}: "
        cd ${BASE_PATH}/${1}
        report_project_cotent ${1} ${HTML_REPORT}

    done <${LIST}

    cat << EOF >> ${HTML_REPORT}
</body>
</html>
EOF

    chmod 644 ${HTML_REPORT}
    kill -9 ${LANGUAGETOOL_PID} > /dev/null
}

for i in "$@"
do
case $i in
    -l=*|--lang=*)
    LANG_CODE="${i#*=}"
    shift # past argument=value
    ;;
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
    --disable-wordlist)
    DISABLE_WORDLIST="YES"
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

if [ -z "${LANG_CODE}" ] || [ -z "${INPUT_FILE}" ] || [ -z "${PROJECT_NAME}" ] || [ -z "${WORK_PATH}" ]; then
    usage
    exit 1
fi

BASE_PATH=${WORK_PATH}/${PROJECT_NAME}
BASE_PATH_RPM=${WORK_PATH}/${PROJECT_NAME}/rpm
LIST=${INPUT_FILE}
VERSION=$(${WORK_PATH}/common/fedora-version.sh)

### Main
report
