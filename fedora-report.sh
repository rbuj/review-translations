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
declare -a locales=( be ca da de el es fr gl it ja lt ml ml_IN nl pl pt pt_BR pt_PT ro ru sk sl sv ta uk zh_CN )
WORK_PATH=$PWD
PROJECTS=$(find $WORK_PATH/conf -type f -name *.conf -exec basename {} .conf \; | sort)
DB_PATH="${WORK_PATH}/fedora-report.db"

########################################################

function start_report_index_html {
    local HTML_REPORT="${REPORT_PATH}/index.html"

    cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>${TITLE}</title>
<script type="text/javascript" src="/js/jquery-3.1.0.slim.min.js"></script>
<script type="text/javascript" src="/js/jquery.tablesorter.min.js"></script>
<style>
table {
    font-family: arial, sans-serif;
    border-collapse: collapse;
    width: 100%;
}

td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}

table.tablesorter thead tr .header {
    cursor: pointer;
}

tr:nth-child(even) {
    background-color: #dddddd;
}

figure {
    display: inline-block;
    border: 1px none;
    margin: 20px; /* adjust as needed */
}

figure img {
    vertical-align: top;
}

figure figcaption {
    border: none;
    text-align: center;
}
</style>
<script type="text/javascript">
\$(document).ready(function()
	{
		\$("#reportTable").tablesorter();
	}
);
</script>
</head>
<body>

<h1>${TITLE}</h1>
<h2>spelling and grammar report</h2>
<table id="reportTable" class="tablesorter">
  <thead>
  <tr>
    <th>Language</th>
    <th>Date</th>
    <th>Size</th>
    <th>MD5SUM</th>
  </tr>
  </thead>
  <tbody>
EOF
}

########################################################

function end_report_index_html {
    local HTML_REPORT="${REPORT_PATH}/index.html"

    cat << EOF >> ${HTML_REPORT}
<br>$(LC_ALL=en.utf8 date)
<br><br>&copy; 2015-2016 Robert Buj <a href="https://github.com/rbuj/review-translations">https://github.com/rbuj/review-translations</a>
<br><br>
    Copyright (C) $(LC_ALL=en.utf8 date '+%Y') Robert Buj.
    Permission is granted to copy, distribute and/or modify this document
    under the terms of the GNU Free Documentation License, Version 1.3
    or any later version published by the Free Software Foundation;
    with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
    A copy of the license is included in the section entitled "GNU
    Free Documentation License".
</body>
</html>
EOF
}

########################################################

# LOCALE
function locale_report {
    local LOCALE=${1}

    cd ${WORK_PATH}
    ${WORK_PATH}/${PROJECT_NAME}.sh -l=$LOCALE -r --disable-wordlist -n  --languagetool-server=$LT_SERVER --languagetool-port=$LT_PORT;
    cd ${REPORT_PATH}
    scp -i ~/.ssh/id_rsa ${PROJECT_NAME}-report-${LOCALE}.txz rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/report/${PROJECT_NAME}
}

# LOCALE DATE
function locale_report_html {
    local LOCALE=${1}
    local DATE=${2}
    local HTML_REPORT="${REPORT_PATH}/index.html"

    if [ ! -f "${REPORT_PATH}/${PROJECT_NAME}-report-${LOCALE}.txz" ]; then
        return 1
    fi
    cd ${REPORT_PATH}
    cat << EOF >> ${HTML_REPORT}
  <tr>
    <td><a href="${PROJECT_NAME}-report-${LOCALE}.txz">$(perl -e "use Locale::Language; print (code2language('${LOCALE:0:2}'));") (${LOCALE})</a></td>
    <td nowrap>$(LC_ALL="en.utf-8" date -d "$DATE" "+%d %B, %Y")</td>
    <td>$(du -h ${PROJECT_NAME}-report-${LOCALE}.txz | cut -f1)</td>
    <td>$(md5sum ${PROJECT_NAME}-report-${LOCALE}.txz)</td>
  </tr>
EOF
}

########################################################

function create_project_report_stats {
    local HTML_REPORT="${REPORT_PATH}/index.html"

    cd ${WORK_PATH}
    ${WORK_PATH}/${PROJECT_NAME}.sh -n -s -a;
    cat << EOF >> ${HTML_REPORT}
  </tbody>
</table>
<figure>
EOF
cat ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.svg >> ${HTML_REPORT}
    cat << EOF >> ${HTML_REPORT}
  <figcaption>Fig.1 - Global translation - message stats by language.</figcaption>
</figure>
<figure>
EOF
cat ${DATA_STATS_PATH}/${PROJECT_NAME}-w.svg >> ${HTML_REPORT}
    cat << EOF >> ${HTML_REPORT}
  <figcaption>Fig.2 - Global translation - word stats by language.</figcaption>
</figure>
EOF
}

########################################################

function report_package_table {
    local HTML_REPORT="${REPORT_PATH}/index.html"

    if [ "${DOCUMENT}" == "NO" ]; then
        cat << EOF >> ${HTML_REPORT}
<h2>Package List</h2>
<table>
  <tr>
    <th>Package Name</th>
    <th>Description</th>
  </tr>
EOF
        for PACKAGE in $(cat $LIST | cut -d ' ' -f1 | sort -u); do
            cat << EOF >> ${HTML_REPORT}
  <tr>
    <td nowrap>${PACKAGE}</td>
    <td>$(dnf repoquery -q --queryformat "%{description}" $PACKAGE)</td>
  </tr>
EOF
        done
        cat << EOF >> ${HTML_REPORT}
</table>
EOF
    else
        cat << EOF >> ${HTML_REPORT}
<h2>Document List</h2>
  <ul>
EOF
        for PACKAGE in $(cat $LIST | cut -d ' ' -f1 | sort -u); do
            cat << EOF >> ${HTML_REPORT}
    <li>${PACKAGE}</li>
EOF
        done
        cat << EOF >> ${HTML_REPORT}
  </ul>
EOF
    fi
    cat << EOF >> ${HTML_REPORT}
<br>
EOF
}

########################################################

function download_all_project_translations {
    ${WORK_PATH}/${PROJECT_NAME}.sh -a;
}

########################################################

function add_locale_stats {
    local HTML_REPORT="${REPORT_PATH}/index.html"

    for LOCALE in ${locales[@]}; do
        if [ -f "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.svg" ]; then
            local FILE="${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.svg"
            cat << EOF >> ${HTML_REPORT}
<figure>
EOF
            cat $FILE >> ${HTML_REPORT}
            cat << EOF >> ${HTML_REPORT}
</figure>
EOF
        fi
    done
}

########################################################

function update_project_db() {
    if [ ! -d "${WORK_PATH}/${PROJECT_NAME}" ]; then
        return 1;
    fi
    local LOCALES=$(find ${WORK_PATH}/${PROJECT_NAME}  -type f -name *.po -exec basename {} .po \; | sort -u)
    declare -i date_file
    declare -i date_report

    sqlite3 ${DB_PATH} < ${WORK_PATH}/sql/global_report_create_tables.sql

    # add the project in t_projects table if not exists, and update date_file field (PO_FILE latest modification)
    if [ ! -d "${WORK_PATH}/${PROJECT_NAME}" ]; then
        return 1;
    fi
    date_file=$(find ${WORK_PATH}/${PROJECT_NAME}  -type f -name *.po -exec date -r {} "+%Y%m%d%H" \; | sort | tail -1)
    sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO t_projects (project) VALUES ('${PROJECT_NAME}');"
    declare -i id_project=$(sqlite3 ${DB_PATH} "SELECT id FROM t_projects WHERE project = '${PROJECT_NAME}';")
    sqlite3 ${DB_PATH} "UPDATE t_projects SET date_file = ${date_file} WHERE id = ${id_project};"

    date_report=$(sqlite3 ${DB_PATH} "SELECT date_report FROM t_projects WHERE id = ${id_project};")
    if [ "$date_report" -le "$date_file" ]; then
        for LOCALE in ${LOCALES[@]}; do
            # get required fiels for updating t_updates
            date_file_t_updates=$(find ${WORK_PATH}/${PROJECT_NAME}  -type f -name ${LOCALE}.po -exec date -r {} "+%Y%m%d%H" \; | sort | tail -1)
            if [ -z "$date_file_t_updates" ]; then
                continue
            fi
            # add the locale in t_locales if not exists
            sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO t_locales (locale) VALUES ('${LOCALE}');"
            id_locale=$(sqlite3 ${DB_PATH} "SELECT id FROM t_locales WHERE locale = '${LOCALE}';")
            # add the update in t_projects table if not exists, and update date_file field (PO_FILE latest modification)
            sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO t_updates (id_project,id_locale,date_file) VALUES (${id_project},${id_locale},${date_file_t_updates});"
            id_update=$(sqlite3 ${DB_PATH} "SELECT id FROM t_updates WHERE id_project = ${id_project} AND id_locale = ${id_locale};")
            sqlite3 ${DB_PATH} "UPDATE t_updates SET date_file = ${date_file_t_updates} WHERE id = ${id_update};"
        done
    fi
}

#########################################
# REQUIRED PACKAGES
#########################################
for REQUIRED_PACKAGE in java-1.8.0-openjdk perl-Locale-Codes sqlite; do
    rpm -q $REQUIRED_PACKAGE &> /dev/null
    if [ $? -ne 0 ]; then
        echo "report : installing required package : $REQUIRED_PACKAGE"
        VERSION_AUX=( $(cat /etc/fedora-release) )
        set -x
        if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y $REQUIRED_PACKAGE --nogpgcheck; else sudo dnf install -y $REQUIRED_PACKAGE; fi
        set -
    fi
done

#########################################
# LANGUAGETOOL
#########################################
if [ ! -d "${WORK_PATH}/languagetool" ]; then
    ${WORK_PATH}/common/build-languagetool.sh --path=${WORK_PATH} -l=${LANG_CODE}
fi
cd ${WORK_PATH}
LANGUAGETOOL=`find . -name 'languagetool-server.jar'`
java -cp $LANGUAGETOOL org.languagetool.server.HTTPServer --port 8081 > /dev/null &
LANGUAGETOOL_PID=$!
LT_SERVER="localhost"
LT_PORT="8081"

#########################################
# REPORTS
#########################################
echo "***************************************"
echo "* reports ..."
echo "***************************************"
declare -i date_file
declare -i date_report
for PROJECT in ${PROJECTS[@]}; do
    source ${WORK_PATH}/conf/${PROJECT}.conf
    BASE_PATH=${WORK_PATH}/${PROJECT_NAME}
    REPORT_PATH=${BASE_PATH}/report
    STATS_PATH=${BASE_PATH}/stats
    DATA_STATS_PATH=${BASE_PATH}/stats/${PROJECT_NAME}

    if [ ! -d "$REPORT_PATH" ]; then
        mkdir -p $REPORT_PATH
    fi

    echo "* project: ${PROJECT_NAME}"
    download_all_project_translations
    update_project_db

    declare -i id_project=$(sqlite3 ${DB_PATH} "SELECT id FROM t_projects WHERE project = '${PROJECT_NAME}';")
    date_file=$(sqlite3 ${DB_PATH} "SELECT date_file FROM t_projects WHERE id = ${id_project};")
    date_report=$(sqlite3 ${DB_PATH} "SELECT date_report FROM t_projects WHERE id = ${id_project};")

    if [ "$date_report" -le "$date_file" ]; then
        start_report_index_html
        for LOCALE in ${locales[@]}; do
            id_locale=$(sqlite3 ${DB_PATH} "SELECT id FROM t_locales WHERE locale = '${LOCALE}';")
            id_update=$(sqlite3 ${DB_PATH} "SELECT id FROM t_updates WHERE id_project = ${id_project} AND id_locale = ${id_locale};")
            if [ -n "${id_update}" ]; then
                date_file_t_updates=$(sqlite3 ${DB_PATH} "SELECT date_file FROM t_updates WHERE id = ${id_update};")
                date_report_t_updates=$(sqlite3 ${DB_PATH} "SELECT date_report FROM t_updates WHERE id = ${id_update};")
                if [ "$date_report_t_updates" -le "$date_file_t_updates" ]; then
                    locale_report ${LOCALE}
                    sqlite3 ${DB_PATH} "UPDATE t_updates SET date_report = $(date '+%Y%m%d%H') WHERE id = ${id_update};"
                fi
                locale_report_html ${LOCALE} $(echo "$date_file_t_updates" | cut -c -8)
            fi
        done
        create_project_report_stats
        report_package_table
        add_locale_stats
        end_report_index_html
        chmod 644 ${REPORT_PATH}/index.html
        scp -i ~/.ssh/id_rsa ${REPORT_PATH}/index.html rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/report/${PROJECT_NAME}/index.html

        sqlite3 ${DB_PATH} "UPDATE t_projects SET date_report = $(date '+%Y%m%d%H') WHERE id = ${id_project};"
    fi
done

#########################################
# LANGUAGETOOL
#########################################
kill -9 $LANGUAGETOOL_PID > /dev/null
