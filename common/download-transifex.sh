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
    source ${WORK_PATH}/common/install-pakages.sh
    install-pakages transifex-client
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
