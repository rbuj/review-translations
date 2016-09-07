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
declare -a locales=( ca de el es fr gl it nl pt ru )
declare -A languages=( [ca]="Catalan" [de]="German" [el]="Greek" [es]="Spanish" [fr]="French" [gl]="Galician" [it]="Italian" [nl]="Dutch" [pt]="Portuguese" [ru]="Russian" )
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
</head>
<body>

<h1>${TITLE}</h1>
<h2>spelling and grammar report</h2>
<table>
  <tr>
    <th>ISO 6391-1 Code</th>
    <th>Language</th>
    <th>Date</th>
    <th>Size</th>
    <th>MD5SUM</th>
  </tr>
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

# LOCALE DATE
function locale_report {
    local LOCALE=${1}
    local DATE=${2}
    local HTML_REPORT="${REPORT_PATH}/index.html"

    cd ${WORK_PATH}
    ${WORK_PATH}/${PROJECT_NAME}.sh -l=$LOCALE -r --disable-wordlist -n;
    cd ${REPORT_PATH}
    scp -i ~/.ssh/id_rsa ${PROJECT_NAME}-report-${LOCALE}.tgz rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/${PROJECT_NAME}-report
    cat << EOF >> ${HTML_REPORT}
  <tr>
    <td>${LOCALE}</td>
    <td><a href="${PROJECT_NAME}-report-${LOCALE}.tgz">${languages[${LOCALE}]}</a></td>
    <td nowrap>$(LC_ALL="en.utf-8" date -d "$DATE" "+%d %B, %Y")</td>
    <td>$(du -h ${PROJECT_NAME}-report-${LOCALE}.tgz | cut -f1)</td>
    <td>$(md5sum ${PROJECT_NAME}-report-${LOCALE}.tgz)</td>
  </tr>
EOF
}

########################################################

function create_project_report_stats {
    local HTML_REPORT="${REPORT_PATH}/index.html"

    cd ${WORK_PATH}
    ${WORK_PATH}/${PROJECT_NAME}.sh -n -s -a;
    cat << EOF >> ${HTML_REPORT}
</table>
<figure>
  <img src="data:image/png;base64,$(base64 -w 0 ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.png)" alt="Messages">
  <figcaption>Fig.1 - Global translation - message stats by language.</figcaption>
</figure>
<figure>
  <img src="data:image/png;base64,$(base64 -w 0 ${DATA_STATS_PATH}/${PROJECT_NAME}-w.png)" alt="Words">
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
        if [ -f "${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.png" ]; then
            local FILE="${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.png"
            cat << EOF >> ${HTML_REPORT}
<figure>
  <img src="data:image/png;base64,$(base64 -w 0 ${FILE})" alt="Messages">
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

    sqlite3 ${DB_PATH} "CREATE TABLE IF NOT EXISTS t_projects (id INTEGER PRIMARY KEY AUTOINCREMENT, 'project' TEXT NOT NULL UNIQUE, 'date_file' INTEGER DEFAULT 0, 'date_report' INTEGER DEFAULT 0);"
    sqlite3 ${DB_PATH} "CREATE TABLE IF NOT EXISTS t_locales (id INTEGER PRIMARY KEY AUTOINCREMENT, 'locale' TEXT NOT NULL UNIQUE);"
    sqlite3 ${DB_PATH} "CREATE TABLE IF NOT EXISTS t_updates (id INTEGER PRIMARY KEY AUTOINCREMENT, 'id_project' INTEGER, 'id_locale' INTEGER, 'date_file' INTEGER DEFAULT 0, 'date_report' INTEGER DEFAULT 0, UNIQUE(id_project, id_locale) ON CONFLICT IGNORE, FOREIGN KEY(id_project) REFERENCES t_projects(id), FOREIGN KEY(id_locale) REFERENCES t_locales(id));"

    # add the project in t_projects table if not exists, and update date_file field (PO_FILE latest modification)
    if [ ! -d "${WORK_PATH}/${PROJECT_NAME}" ]; then
        return 1;
    fi
    date_file=$(find ${WORK_PATH}/${PROJECT_NAME}  -type f -name *.po -exec date -r {} "+%Y%m%d" \; | sort | tail -1)
    sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO t_projects (project) VALUES ('${PROJECT_NAME}');"
    declare -i id_project=$(sqlite3 ${DB_PATH} "SELECT id FROM t_projects WHERE project = '${PROJECT_NAME}';")
    sqlite3 ${DB_PATH} "UPDATE t_projects SET date_file = ${date_file} WHERE id = ${id_project};"

    date_report=$(sqlite3 ${DB_PATH} "SELECT date_report FROM t_projects WHERE id = ${id_project};")
    if [ "$date_report" -lt "$date_file" ]; then
        for LOCALE in ${LOCALES[@]}; do
            # get required fiels for updating t_updates
            date_file_t_updates=$(find ${WORK_PATH}/${PROJECT_NAME}  -type f -name ${LOCALE}.po -exec date -r {} "+%Y%m%d" \; | sort | tail -1)
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

    echo "* project: ${PROJECT_NAME}"
    download_all_project_translations
    update_project_db

    declare -i id_project=$(sqlite3 ${DB_PATH} "SELECT id FROM t_projects WHERE project = '${PROJECT_NAME}';")
    date_file=$(sqlite3 ${DB_PATH} "SELECT date_file FROM t_projects WHERE id = ${id_project};")
    date_report=$(sqlite3 ${DB_PATH} "SELECT date_report FROM t_projects WHERE id = ${id_project};")

    if [ "$date_report" -lt "$date_file" ]; then
        start_report_index_html
        for LOCALE in ${locales[@]}; do
            id_locale=$(sqlite3 ${DB_PATH} "SELECT id FROM t_locales WHERE locale = '${LOCALE}';")
            id_update=$(sqlite3 ${DB_PATH} "SELECT id FROM t_updates WHERE id_project = ${id_project} AND id_locale = ${id_locale};")
            if [ -n "${id_update}" ]; then
                date_file_t_updates=$(sqlite3 ${DB_PATH} "SELECT date_file FROM t_updates WHERE id = ${id_update};")
                date_report_t_updates=$(sqlite3 ${DB_PATH} "SELECT date_report FROM t_updates WHERE id = ${id_update};")
                if [ "$date_report_t_updates" -lt "$date_file_t_updates" ]; then
                    locale_report ${LOCALE} ${date_file_t_updates}
                    sqlite3 ${DB_PATH} "UPDATE t_updates SET date_report = $(date '+%Y%m%d') WHERE id = ${id_update};"
                fi
            fi
        done
        create_project_report_stats
        report_package_table
        add_locale_stats
        end_report_index_html
        chmod 644 ${REPORT_PATH}/index.html
        scp -i ~/.ssh/id_rsa ${REPORT_PATH}/index.html rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/${PROJECT_NAME}-report/index.html

        sqlite3 ${DB_PATH} "UPDATE t_projects SET date_report = $(date '+%Y%m%d') WHERE id = ${id_project};"
    fi
done
