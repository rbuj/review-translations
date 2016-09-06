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

function usage {
    echo "This script downloads the translation of ${PROJECT_NAME}"
    echo "    usage : ${0} [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server (-a : all locales)"
    echo "   -p|--project=PROJECT  Base PROJECT folder for downloaded files"
    echo "   -f|--file=INPUT_FILE  INPUT_FILE that contains the project info"
    echo "   -w|--workpath=W_PATH  Work PATH folder"
    echo -ne "\nOptional arguments:\n"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

function download_code {
    cd ${BASE_PATH}
    if [ ! -d "${1}" ]; then
        echo -ne "git clone "
        git clone $2 $1 &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    else
        cd $1
        echo -ne "git pull "
        git pull --rebase &> /dev/null && git submodule init &> /dev/null && git submodule update &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    fi
}

function download {
    echo "************************************************"
    echo "* downloading translations..."
    echo "************************************************"
    if [ ! -d "${BASE_PATH}" ]; then
        mkdir -p "${BASE_PATH}"
    fi
    while read -r p; do
        set -- $p
        cd ${BASE_PATH}
        echo -ne "${1}: "
        download_code ${1} ${2}
    done <${INPUT_FILE}
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

BASE_PATH=${WORK_PATH}/${PROJECT_NAME}

download
