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

WORK_PATH=
BASE_PATH=

LANG_CODE=
PROJECT_NAME=
INPUT_FILE=
BASE_URL=
VERBOSE=

function usage {
    echo "usage : $0 -l|--lang=LANG_CODE -p|--project=PROJECT -f|--file=INPUT_FILE -u|--url=URL [ ARGS ... ]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo "   -p|--project=PROJECT  Base PROJECT folder for downloaded files"
    echo "   -f|--file=INPUT_FILE  INPUT_FILE that contains the project info"
    echo "   -w|--workpath=W_PATH  Work PATH folder"
    echo "   -u|--url=URL          Base URL of the Zanata server"
    echo -ne "\nOptional arguments:\n"
    echo "   -h, --help            Display this help and exit"
    echo "   -v, --verbose         Verbose operation"
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
  <url>${BASE_URL}</url>
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
    zanata-cli -B -q pull -l ${LANG_CODE} --pull-type trans > /dev/null && echo "${GREEN}[ OK ]${NC}" || exit 1
}

function download {
    rpm -q zanata-client &> /dev/null
    if [ $? -ne 0 ]; then
        echo "download : installing required packages"
        sudo dnf install -y zanata-client
    fi
    echo "************************************************"
    echo "* downloading translations..."
    echo "************************************************"
    while read -r p; do
        set -- $p
        if [ -z "${VERBOSE}" ]; then echo -ne "${1} (${2}) "; fi
        project_folder $1 $2
        project_config $1 $2
        project_download $1 $2
    done <${INPUT_FILE}
    echo "************************************************"
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
    -u=*|--url=*)
    BASE_URL="${i#*=}"
    shift # past argument=value
    ;;
    -w=*|--workpath=*)
    WORK_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -v|--verbose)
    VERBOSE="YES"
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

if [ -z "${LANG_CODE}" ] || [ -z "${INPUT_FILE}" ] || [ -z "${PROJECT_NAME}" ] || [ -z "${BASE_URL}" ] || [ -z "${WORK_PATH}" ]; then
    usage
    exit 1
fi
BASE_PATH=${WORK_PATH}/${PROJECT_NAME}

### Main ###
download
