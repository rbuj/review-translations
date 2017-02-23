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

CONFIG=

BASE_PATH=

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
    echo "   --conf=CONFIG_FILE    Config"
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
    case $TYPE in
        fedora|git|transifex)
            source ${WORK_PATH}/common/download-${TYPE}.sh
        ;;
        *)
            usage
            exit 1
        ;;
    esac
}

###################################################################################

function install {
    case $TYPE in
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
    source ${WORK_PATH}/common/report.sh
}

###################################################################################

function stats {
    source ${WORK_PATH}/common/stats.sh
}

###################################################################################

for i in "$@"
do
case $i in
    --conf=*)
    CONFIG_FILE="${i#*=}"
    shift # past argument=value
    ;;
    -l=*|--lang=*)
    LANG_CODE="${i#*=}"
    shift # past argument=value
    ;;
    -a)
    ALL_LANGS="YES"
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

if [ -z "${CONFIG_FILE}" ]; then
    echo "Missing argument: --conf=CONF_FILE"
    exit 1
fi
source $CONFIG_FILE

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

BASE_PATH=${WORK_PATH}/${PROJECT_NAME}

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
