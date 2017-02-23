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
function install_trans {
    IFS=';' read -a TRANS <<< "$3"
    echo -ne "installing ${1} (${2}) "
    if [ ${#TRANS[@]} -gt 1 ]; then echo -ne "${#TRANS[@]} files:\n"; fi
    for i in "${TRANS[@]}"; do
        IFS=':' read -a ADDR <<< "${i//"LOCALE"/${LANG_CODE}}"
        dnf provides ${ADDR[1]} &> /dev/null
        if [ $? -ne 0 ]; then
            echo -ne "[${ADDR[1]} file was not installed. installing...] "
            dnf install -y `dnf repoquery -f ${ADDR[1]}` &> /dev/null
            if [ $? -ne 0 ]; then
                echo "${RED}[ FAIL ]${NC}"
            else
                echo "${GREEN}[ OK ]${NC}"
                if [ ${#TRANS[@]} -gt 1 ]; then echo -ne "    ${ADDR[1]} "; fi
                rm -f ${ADDR[1]} && msgfmt ${BASE_PATH}/${1}-${2}/${ADDR[0]} -o ${ADDR[1]} && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
            fi
        else
            if [ ${#TRANS[@]} -gt 1 ]; then echo -ne "    ${ADDR[1]} "; fi
            rm -f ${ADDR[1]} && msgfmt ${BASE_PATH}/${1}-${2}/${ADDR[0]} -o ${ADDR[1]} && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
        fi
    done
}

function install {
    local VERSION="upstream"
    if [ -f "/etc/fedora-release" ]; then
        VERSION_AUX=`cat /etc/fedora-release`
        case ${VERSION_AUX} in
            "Fedora release 23 (Twenty Three)")
            VERSION="F23"
            ;;
        esac
    fi
    while read -r p; do
        set -- $p
        if [ $# -eq 3 ]; then
            install_trans $@
        elif [ $# -eq 4 ]; then
            if [ "$VERSION" = "$3" ]; then
                install_trans $1 $2 $4
            fi
        fi
    done <${LIST}
}

install
