#!/bin/bash
# ---------------------------------------------------------------------------
# Copyright 2015, Robert Buj <rbuj@fedoraproject.org>
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

WORK_PATH=$PWD
BASE_PATH=

LANG_CODE=
PROJECT_NAME=
INPUT_FILE=
VERBOSE=
GENERATE_REPORT=

function usage {
    echo $"usage"" : $0 [-l|--lang]=LANG_CODE [-p|--project]=PROJECT_NAME [-f|--file]=INPUT_FILE"
}

function project_folder {
    if [ ! -d "${BASE_PATH}/${1}-${2}" ]; then
        if [ -n "${VERBOSE}" ]; then echo -ne "${1} (${2}) : creating project folder "; fi
       	mkdir -p ${BASE_PATH}/${1}-${2} > /dev/null && if [ -n "${VERBOSE}" ]; then echo "${GREEN}[ OK ]${NC}"; fi || exit 1
    fi
}

function project_config {
    ZANATA_FILE=${BASE_PATH}/${1}-${2}/zanata.xml
    if [ ! -f "${ZANATA_FILE}" ]; then
        if [ -n "${VERBOSE}" ]; then echo -ne "${1} (${2}) : creating zanata.xml file "; fi
        cat << EOF > ${ZANATA_FILE}
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://zanata.org/namespace/config/">
  <url>https://fedora.zanata.org/</url>
  <project>${1}</project>
  <project-version>${2}</project-version>
  <project-type>gettext</project-type>

</config>
EOF
        if [ $? -ne 0 ]; then
            if [ -n "${VERBOSE}" ]; then echo "${RED}[ FAIL ]${NC}"; fi
        else
       	    if [ -n "${VERBOSE}" ]; then echo "${GREEN}[ OK ]${NC}"; fi
        fi
    fi
}

function project_download {
    if [ -n "${VERBOSE}" ]; then echo -ne "${1} (${2}) : downloading project translation "; fi
    cd ${BASE_PATH}/${1}-${2}
    zanata-cli -B pull -l ${LANG_CODE} > /dev/null && echo "${GREEN}[ OK ]${NC}" || exit 1
}

function download {
    rpm -q zanata-client &> /dev/null
    if [ $? -ne 0 ]; then
        echo "download : installing required packages"
        sudo dnf install -y zanata-client &> /dev/null && echo "${GREEN}[ OK ]${NC}" || exit 1
    fi
    while read -r p; do
        set -- $p
        if [ -z "${VERBOSE}" ]; then echo -ne "${1} (${2}) "; fi
        project_folder $1 $2
        project_config $1 $2
        project_download $1 $2
    done <${INPUT_FILE}
}

function report {
    rpm -q hunspell-${LANG_CODE} subversion maven python-enchant &> /dev/null
    if [ $? -ne 0 ]; then
        echo "report : installing required packages"
        sudo dnf install -y hunspell-${LANG_CODE} subversion maven python-enchant &> /dev/null && echo "${GREEN}[ OK ]${NC}" || exit 1
    fi

    if [ ! -d "${WORK_PATH}/languagetool" ]; then
        echo "report : building languagetool"
        cd ${WORK_PATH}
        git clone https://github.com/languagetool-org/languagetool.git
        cd languagetool
        ./build.sh languagetool-standalone clean package -DskipTests
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

    if [ ! -d ${WORK_PATH}/pology ]; then
        echo "report : building pology"
        cd ${WORK_PATH}
        svn checkout svn://anonsvn.kde.org/home/kde/trunk/l10n-support/pology
        cd pology
        mkdir build && cd build
        cmake ..
        make
    fi
    export PYTHONPATH=${WORK_PATH}/pology:$PYTHONPATH
    export PATH=${WORK_PATH}/pology/bin:$PATH

    HTML_REPORT=${WORK_PATH}/fedora-web-report.html
    cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html lang="${LANG_CODE}" xml:lang="${LANG_CODE}" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Report</title>
  </head>
<body bgcolor="#080808" text="#D0D0D0">
EOF

    echo "report : checking translations"
    posieve check-rules,check-spell-ec,check-grammar,stats -s lang:${LANG_CODE} -s showfmsg -s byrule -s provider:hunspell --msgfmt-check --skip-obsolete --coloring-type=html ${BASE_PATH}/ >> ${HTML_REPORT}

    cat << EOF >> ${HTML_REPORT}
</body>
</html>
EOF

    kill -9 $LANGUAGETOOL_PID > /dev/null
}

for i in "$@"
do
case $i in
    -l=*|--lang=*)
    LANG_CODE="${i#*=}"
    shift # past argument=value
    ;;
    -f=*|--file=*)
    INPUT_FILE="${i#*=}"
    shift # past argument=value
    ;;
    -p=*|--project=*)
    PROJECT_NAME="${i#*=}"
    shift # past argument=value
    ;;
    -r|--report)
    GENERATE_REPORT="YES"
    ;;
    -v|--verbose)
    VERBOSE="YES"
    ;;
    *)
    usage
    exit 1
    ;;
esac
done

if [ -z "${LANG_CODE}" ] || [ -z "${INPUT_FILE}" ] || [ -z "${PROJECT_NAME}" ]; then
    usage
    exit 1
fi
BASE_PATH=${WORK_PATH}/${PROJECT_NAME}

### Main ###
download
if [ -n "$GENERATE_REPORT" ]; then
    report
fi
