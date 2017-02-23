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
function install {
    echo "************************************************"
    echo "* installing translations..."
    echo "************************************************"
    local VERSION_AUX=( $(cat /etc/fedora-release) )

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
        sudo rpm reinstall -y */*.rpm &> /dev/null
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        let "COUNTER++"
    done <${LIST}
}

BASE_PATH_RPM=${WORK_PATH}/${PROJECT_NAME}/rpm
VERSION=$(${WORK_PATH}/common/fedora-version.sh)

install
