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
    if [ -z "${ALL_LANGS}" ]; then
        zanata-cli -B -q pull -l ${LANG_CODE} --pull-type trans > /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}";
    else
        zanata-cli -B -q pull --pull-type trans > /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}";
    fi
}

function download {
    source ${WORK_PATH}/common/install-pakages.sh
    install-pakages zanata-client
    echo "************************************************"
    echo "* downloading translations..."
    echo "************************************************"
    while read -r p; do
        set -- $p
        if [ -z "${VERBOSE}" ]; then echo -ne "${1} (${2}) "; fi
        project_folder $1 $2
        project_config $1 $2
        project_download $1 $2
    done <${LIST}
    echo "************************************************"
}
