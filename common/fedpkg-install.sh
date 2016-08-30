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
    echo "    usage : $0 [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server (-a : all locales)"
    echo "   -p|--project=PROJECT  Base PROJECT folder for downloaded files"
    echo "   -f|--file=INPUT_FILE  INPUT_FILE that contains the project info"
    echo "   -w|--workpath=W_PATH  Work PATH folder"
    echo -ne "\nOptional arguments:\n"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

function install {
    echo "************************************************"
    echo "* installing translations..."
    echo "************************************************"
    VERSION_AUX=( $(cat /etc/fedora-release) )

    rpm -q fedpkg fedora-packager rpmdevtools &> /dev/null
    if [ $? -ne 0 ]; then
        echo "installing required packages"
        set -x
        if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y fedpkg fedora-packager rpmdevtools --nogpgcheck; else sudo dnf install -y fedpkg fedora-packager rpmdevtools; fi
        set -
    fi

    if [ ! -d "${BASE_PATH_RPM}" ]; then
        mkdir -p "${BASE_PATH_RPM}"
    fi

    while read -r p; do
        set -- $p
        PROJECT=${1}

	if [ ! -d "${BASE_PATH}/${PROJECT}/po" ]; then
            echo "${PROJECT}: check downloaded translations ${RED}[ FAIL ]${NC} folder not found."
            continue
        fi

        if [ -d "${BASE_PATH_RPM}/${PROJECT}" ]; then
            rm -fr "${BASE_PATH_RPM}/${PROJECT}"
        fi

        cd "${BASE_PATH_RPM}"

        echo -ne "${PROJECT}: fedpkg clone "
        fedpkg clone -a -B ${PROJECT} &> /dev/null
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        cd "${PROJECT}/${VERSION}"
        echo -ne "${PROJECT}: dnf builddep "
        sudo dnf builddep -y ${PROJECT}.spec --nogpgcheck --allowerasing &> /dev/null
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        echo -ne "${PROJECT}: fedpkg prep "
        fedpkg prep &> /dev/null
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        echo -ne "${PROJECT}: path "
        SRC=$(find . -maxdepth 1 -mindepth 1 -type d ! -name ".*")
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        echo -ne "${PROJECT}: copy folder "
        cp -rp ${SRC#*/} ${SRC#*/}p &> /dev/null
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        echo -ne "${PROJECT}: copy trans "
        if [ -n "${ALL_LANGS}" ]; then
            echo "cp -fu ${BASE_PATH}/${PROJECT}/po/*.po ${BASE_PATH_RPM}/${PROJECT}/${VERSION}/${SRC#*/}p/po/" | sh &> /dev/null
        else
            cp "${BASE_PATH}/${PROJECT}/po/${LANG_CODE}.po" "${SRC#*/}p/po/" &> /dev/null
        fi
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        cd "${SRC#*/}p/po"
        intltool-update --pot
        intltool-update --dist ${LANG_CODE}
        if [ -n "${ALL_LANGS}" ]; then
            for FILE in $(ls *.po); do intltool-update --dist $(basename $FILE .po); done
        else
            intltool-update --dist ${LANG_CODE}
        fi
        cd "${BASE_PATH_RPM}/${PROJECT}/${VERSION}"

        echo -ne "${PROJECT}: patch "
        diff -urN "${SRC#*/}" "${SRC#*/}p" > my.patch
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        cp ${PROJECT}.spec ${PROJECT}.spec.ori

        echo -ne "${PROJECT}: spec "
        sed -i '/^%setup -q*/ a %patch9999 -p1' ${PROJECT}.spec
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        fi

        sed -i '1 i Patch9999: my.patch' ${PROJECT}.spec
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        echo -ne "${PROJECT}: fedpkg local "
        fedpkg local &> /dev/null
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        echo -ne "${PROJECT}: rpm -i "
        rpm -i --replacepkgs --replacefiles */*.rpm &> /dev/null
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        let "COUNTER++"
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
BASE_PATH_RPM=${WORK_PATH}/${PROJECT_NAME}/rpm
LIST=${INPUT_FILE}
VERSION=$(${WORK_PATH}/common/fedora-version.sh)

### Main
# ensure running as root
if [ "$(id -u)" != "0" ]; then
    if [ -n "${ALL_LANGS}" ]; then
        exec sudo "$0" "-a" "-p=${PROJECT_NAME}" "-f=${LIST}" "-w=${WORK_PATH}"
    else
        exec sudo "$0" "-l=${LANG_CODE}" "-p=${PROJECT_NAME}" "-f=${LIST}" "-w=${WORK_PATH}"
    fi
    exit 0
else
    install
fi
