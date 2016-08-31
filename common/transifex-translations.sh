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
ALL_LANGS=

GENERATE_REPORT=
DISABLE_WORDLIST=
INSTALL_TRANS=
STATS=

function usage {
    echo "This script downloads the translation of ${PROJECT_NAME}"
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server (-a : all locales, no compatible with -r option)"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   --disable-wordlist    Do not use wordlist file"
    echo "   -i, --install         Install translations"
    echo "   -s, --stats           Stats for translated messages and words (requires -a)"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

function download_code {
    cd ${BASE_PATH}
    if [ ! -f "${1}/.tx/config" ]; then
        mkdir -p ${1}/.tx
        cat << EOF > ${1}/.tx/config
[main]
host = https://www.transifex.com

[${2}.${3}]
source_file = po/${3}.pot
source_lang = en
type = PO
file_filter = po/<lang>.po
EOF
    fi
    cd ${BASE_PATH}/${1}
    if [ -n "${ALL_LANGS}" ]; then
        tx pull -a > /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}";
    else
        tx pull -l ${LANG_CODE} > /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}";
    fi
}

function download {
    rpm -q transifex-client &> /dev/null
    if [ $? -ne 0 ]; then
        echo "download : installing required packages"
        VERSION_AUX=( $(cat /etc/fedora-release) )
        if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y transifex-client --nogpgcheck; else sudo dnf install -y transifex-client; fi
    fi
    echo "************************************************"
    echo "* downloading translations..."
    echo "************************************************"
    if [ ! -d "${BASE_PATH}" ]; then
        mkdir -p "${BASE_PATH}"
    fi
    while read -r p; do
        set -- $p
        cd ${BASE_PATH}
        echo -ne "${3}: "
        download_code ${1} ${2} ${3}
    done <${LIST}
}

for i in "$@"
do
case $i in
    -l=*|--lang=*)
    LANG_CODE="${i#*=}"
    shift # past argument=value
    ;;
    -a)
    ALL_LANGS="YES"
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
    -r|--report)
    GENERATE_REPORT="YES"
    ;;
    --disable-wordlist)
    DISABLE_WORDLIST="YES"
    ;;
    -i|--install)
    INSTALL_TRANS="YES"
    ;;
    -s|--stats)
    STATS="YES"
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

if [ -z "${INPUT_FILE}" ] || [ -z "${PROJECT_NAME}" ] || [ -z "${WORK_PATH}" ]; then
    usage
    exit 1
fi

if [ -z "${LANG_CODE}" ] && [ -z "${ALL_LANGS}" ]; then
    usage
    exit 1
fi

if [ -n "${LANG_CODE}" ] && [ -n "${ALL_LANGS}" ]; then
    usage
    exit 1
fi

if [ -z "${GENERATE_REPORT}" ] && [ -n "${DISABLE_WORDLIST}" ]; then
    usage
    exit 1
fi

if [ -n "${GENERATE_REPORT}" ] && [ -n "${ALL_LANGS}" ]; then
    usage
    exit 1
fi

if [ -z "${ALL_LANGS}" ] && [ -n "${STATS}" ]; then
    usage
    exit 1
fi

BASE_PATH=${WORK_PATH}/${PROJECT_NAME}
BASE_PATH_RPM=${WORK_PATH}/${PROJECT_NAME}/rpm
LIST=${INPUT_FILE}
VERSION=$(${WORK_PATH}/common/fedora-version.sh)

### Main
download
if [ -n "$GENERATE_REPORT" ]; then
    if [ -n "${DISABLE_WORDLIST}" ]; then
        ${WORK_PATH}/common/pology-languagetool-report.sh "-l=${LANG_CODE}" "-p=${PROJECT_NAME}" "-f=${LIST}" "-w=${WORK_PATH}"
    else
        ${WORK_PATH}/common/pology-languagetool-report.sh "-l=${LANG_CODE}" "-p=${PROJECT_NAME}" "-f=${LIST}" "-w=${WORK_PATH}" "--disable-wordlist"
    fi
fi
if [ -n "$INSTALL_TRANS" ]; then
    if [ -n "${ALL_LANGS}" ]; then
        ${WORK_PATH}/common/fedpkg-install.sh "-a" "-p=${PROJECT_NAME}" "-f=${LIST}" "-w=${WORK_PATH}"
    else
        ${WORK_PATH}/common/fedpkg-install.sh "-l=${LANG_CODE}" "-p=${PROJECT_NAME}" "-f=${LIST}" "-w=${WORK_PATH}"
    fi
fi
if [ -n "$STATS" ]; then
    ${WORK_PATH}/common/project-stats.sh "-p=${PROJECT_NAME}" "-w=${WORK_PATH}"
fi
echo "complete!"
