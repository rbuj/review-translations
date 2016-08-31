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
PROJECT_NAME==
WORK_PATH=
INPUT_FILE=

LANG_CODE=
ALL_LANGS=
GENERATE_REPORT=
DISABLE_WORDLIST=
INSTALL_TRANS=
STATS=

LT_SERVER=
LT_PORT=

function usage {
    echo "This script downloads the translations of the projects that belongs to ${PROJECT_NAME}."
    echo "    usage : ./${PROJECT_NAME}.sh [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server (-a : all locales, no compatible with -r option)"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   --disable-wordlist    Do not use wordlist file (requires -r)"
    if [ "${PROJECT_NAME}" != "fedora-web" ]; then
        echo "   -i, --install         Install translations"
    fi
    echo "   -s, --stats           Stats for translated messages and words (requires -a)"
    echo "   -h, --help            Display this help and exit"
    echo ""
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
    -i|--install)
    INSTALL_TRANS="YES"
    ;;
    -s|--stats)
    STATS="YES"
    ;;
    -r|--report)
    GENERATE_REPORT="YES"
    ;;
    --disable-wordlist)
    DISABLE_WORDLIST="YES"
    ;;
    --languagetool-server=*)
    LT_SERVER="${i#*=}"
    shift # past argument=value
    ;;
    --languagetool-port=*)
    LT_PORT="${i#*=}"
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

if [ "${PROJECT_NAME}" == "fedora-web" ] && [ -n "${INSTALL_TRANS}" ]; then
    usage
    exit 1
fi

if [ -z "${ALL_LANGS}" ] && [ -n "${STATS}" ]; then
    usage
    exit 1
fi

### Main ###
if [ -n "${ALL_LANGS}" ]; then
    ${WORK_PATH}/common/zanata.sh -a -p=${PROJECT_NAME} -f=${INPUT_FILE} -u=https://fedora.zanata.org/ -w=${WORK_PATH}
else
    ${WORK_PATH}/common/zanata.sh -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${INPUT_FILE} -u=https://fedora.zanata.org/ -w=${WORK_PATH}
fi
if [ -n "$GENERATE_REPORT" ]; then
    if [ -z "${DISABLE_WORDLIST}" ]; then
        if [ -z "${LT_SERVER}" ] && [ -z "${LT_PORT}" ]; then
            ${WORK_PATH}/common/report.sh -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${INPUT_FILE} -w=${WORK_PATH}
        else
            ${WORK_PATH}/common/report.sh -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${INPUT_FILE} --languagetool-server=${LT_SERVER} --languagetool-port=${LT_PORT} -w=${WORK_PATH}
        fi
    else
        if [ -z "${LT_SERVER}" ] && [ -z "${LT_PORT}" ]; then
            ${WORK_PATH}/common/report.sh -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${INPUT_FILE} --disable-wordlist -w=${WORK_PATH}
        else
            ${WORK_PATH}/common/report.sh -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${INPUT_FILE} --disable-wordlist --languagetool-server=${LT_SERVER} --languagetool-port=${LT_PORT} -w=${WORK_PATH}
        fi
    fi
fi
if [ -n "$INSTALL_TRANS" ]; then
    if [ "${PROJECT_NAME}" != "fedora-web" ]; then
        ${WORK_PATH}/common/install.sh -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${INPUT_FILE} -w=${WORK_PATH}
    else
        usage
        exit 1
    fi
fi
if [ -n "$STATS" ]; then
    ${WORK_PATH}/common/stats.sh "-p=${PROJECT_NAME}" "-f=${INPUT_FILE}" "-w=${WORK_PATH}"
fi
echo "complete!"
