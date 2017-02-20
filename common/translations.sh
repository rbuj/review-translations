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

BASE_PATH=

PROJECT_NAME=
INPUT_FILE=
TRANSLATION_TYPE=
DOCUMENT="NO"

LANG_CODE=
ALL_LANGS=

GENERATE_REPORT=
INSTALL_TRANS=
STATS=
DOWNLOAD="YES"

LT_SERVER=
LT_PORT=

function usage {
    echo "This script downloads the translation of ${PROJECT_NAME}"
    echo "    usage : ./${PROJECT_NAME}.sh [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server (-a : all locales, no compatible with -r option)"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    if [ "${DOCUMENT}" == "NO" ]; then
        echo "   -i, --install         Install translations"
    fi
    echo "   -s, --stats           Stats for translated messages and words (requires -a)"
    echo "   -n                    Do not download the translations"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

###################################################################################

function download {
    if [ -n "${ALL_LANGS}" ]; then
        case $TRANSLATION_TYPE in
            fedora|git|transifex)
                ${WORK_PATH}/common/download-${TRANSLATION_TYPE}.sh -a -p=${PROJECT_NAME} -f=${INPUT_FILE} -w=${WORK_PATH}
            ;;
            *)
                usage
                exit 1
            ;;
        esac
    else
        case $TRANSLATION_TYPE in
            fedora|git|transifex)
                ${WORK_PATH}/common/download-${TRANSLATION_TYPE}.sh -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${INPUT_FILE} -w=${WORK_PATH}
            ;;
            *)
                usage
                exit 1
            ;;
        esac
    fi
}

###################################################################################

function install {
    case $TRANSLATION_TYPE in
        fedora)
            if [ "${PROJECT_NAME}" != "fedora-web" ]; then
                ${WORK_PATH}/common/install.sh -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${INPUT_FILE} -w=${WORK_PATH}
            else
                usage
                exit 1
            fi
        ;;
        git|transifex)
            if [ -n "${ALL_LANGS}" ]; then
                ${WORK_PATH}/common/fedpkg-install.sh "-a" "-p=${PROJECT_NAME}" "-f=${INPUT_FILE}" "-w=${WORK_PATH}"
            else
                ${WORK_PATH}/common/fedpkg-install.sh "-l=${LANG_CODE}" "-p=${PROJECT_NAME}" "-f=${INPUT_FILE}" "-w=${WORK_PATH}"
            fi
        ;;
        *)
            usage
            exit 1
        ;;
    esac
}

###################################################################################

function report {
    if [ -z "${LT_SERVER}" ] && [ -z "${LT_PORT}" ]; then
        ${WORK_PATH}/common/report.sh -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${INPUT_FILE} -w=${WORK_PATH} -t=${TRANSLATION_TYPE}
    else
        ${WORK_PATH}/common/report.sh -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${INPUT_FILE} --languagetool-server=${LT_SERVER} --languagetool-port=${LT_PORT} -w=${WORK_PATH} -t=${TRANSLATION_TYPE}
    fi
}

###################################################################################

function stats {
    ${WORK_PATH}/common/stats.sh "-p=${PROJECT_NAME}" "-f=${INPUT_FILE}" "-w=${WORK_PATH}" "-t=${TRANSLATION_TYPE}"
}

###################################################################################

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
    -t=*|--type=*)
    TRANSLATION_TYPE="${i#*=}"
    shift # past argument=value
    ;;
    -d=*|--document=*)
    DOCUMENT="${i#*=}"
    shift # past argument=value
    ;;
    -r|--report)
    GENERATE_REPORT="YES"
    ;;
    -i|--install)
    INSTALL_TRANS="YES"
    ;;
    -s|--stats)
    STATS="YES"
    ;;
    --languagetool-server=*)
    LT_SERVER="${i#*=}"
    shift # past argument=value
    ;;
    --languagetool-port=*)
    LT_PORT="${i#*=}"
    shift # past argument=value
    ;;
    -n)
    DOWNLOAD="NO"
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

###################################################################################

if [ -z "${INPUT_FILE}" ] || [ -z "${PROJECT_NAME}" ] || [ -z "${WORK_PATH}" ] || [ -z "${TRANSLATION_TYPE}" ]; then
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

if [ -n "${GENERATE_REPORT}" ] && [ -n "${ALL_LANGS}" ]; then
    usage
    exit 1
fi

if [ -z "${ALL_LANGS}" ] && [ -n "${STATS}" ]; then
    usage
    exit 1
fi

###################################################################################

if [ "${DOWNLOAD}" == "YES" ]; then
    download
fi

if [ -n "$GENERATE_REPORT" ]; then
    report
fi

if [ -n "$INSTALL_TRANS" ] && [ "${DOCUMENT}" == "NO" ]; then
    install
fi

if [ -n "$STATS" ]; then
    stats
fi

echo "complete!"
