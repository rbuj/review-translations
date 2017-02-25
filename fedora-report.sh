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
source ${WORK_PATH}/conf/languagetool.conf
source ${WORK_PATH}/conf/colors.sh

########################################################

function start_report_data_xml {
    local HTML_REPORT="${REPORT_PATH}/data.xml"
    cat << EOF > ${HTML_REPORT}
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="/xsl/project.xsl"?>
<project>
  <name>$TITLE</name>
  <date>$(LC_ALL=en.utf8 date)</date>
  <msg>$(cat ${DATA_STATS_PATH}/${PROJECT_NAME}-msg.svg | python -m base64 -e | perl -pe 'chomp')</msg>
  <wrd>$(cat ${DATA_STATS_PATH}/${PROJECT_NAME}-w.svg | python -m base64 -e | perl -pe 'chomp')</wrd>
EOF
}

########################################################

function end_report_data_xml {
    local HTML_REPORT="${REPORT_PATH}/data.xml"
    echo "</project>" >> ${HTML_REPORT}
}

########################################################

function start_locales_report {
    local HTML_REPORT="${REPORT_PATH}/data.xml"
    echo "  <languages>" >> ${HTML_REPORT}
}

########################################################

function end_locales_report {
    local HTML_REPORT="${REPORT_PATH}/data.xml"
    echo "  </languages>" >> ${HTML_REPORT}
}

########################################################

# LOCALE
function locale_report {
    local LOCALE=${1}
    cd ${WORK_PATH}
    ${WORK_PATH}/${PROJECT_NAME}.sh -l=$LOCALE -r -n  --languagetool-server=$LT_SERVER --languagetool-port=$LT_PORT;
    cd ${REPORT_PATH}
    scp -i ~/.ssh/id_rsa ${PROJECT_NAME}-report-${LOCALE}.txz rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/report/${PROJECT_NAME}
}

# LOCALE DATE
function locale_report_data {
    local LOCALE=${1}
    local DATE=${2}
    local HTML_REPORT="${REPORT_PATH}/data.xml"
    local LANGUAGE=$(perl -e "use Locale::Language; print (code2language('${LOCALE:0:2}'));")
    local FORMATED_DATE=$(LC_ALL="en.utf-8" date -d "$DATE" "+%d %B, %Y")

    if [ ! -f "${REPORT_PATH}/${PROJECT_NAME}-report-${LOCALE}.txz" ]; then
        return 1
    fi
    cd ${REPORT_PATH}
    local SIZE=$(du -h ${PROJECT_NAME}-report-${LOCALE}.txz | cut -f1)
    local MD5SUM=$(md5sum ${PROJECT_NAME}-report-${LOCALE}.txz)
    local FILE="${DATA_STATS_PATH}/${PROJECT_NAME}-msg.${LOCALE}.svg"
    cat << EOF >> ${HTML_REPORT}
    <language>
      <url>${PROJECT_NAME}-report-${LOCALE}.txz</url>
      <language>$LANGUAGE</language>
      <date>$FORMATED_DATE</date>
      <size>$SIZE</size>
      <md5sum>$MD5SUM</md5sum>
      <svg>$(cat $FILE | python -m base64 -e | perl -pe 'chomp')</svg>
      <svg-alt>$(basename $FILE)</svg-alt>
    </language>
EOF
}

########################################################

function create_project_report_stats {
    local HTML_REPORT="${REPORT_PATH}/data.xml"

    cd ${WORK_PATH}
    ${WORK_PATH}/${PROJECT_NAME}.sh -n -s -a;
}

########################################################

function report_package_table {
    local HTML_REPORT="${REPORT_PATH}/data.xml"

    echo "  <components>" >> ${HTML_REPORT}
    if [ "${DOCUMENT}" == "NO" ]; then
        for PACKAGE in $(cat $LIST | cut -d ' ' -f1 | sort -u); do
            cat << EOF >> ${HTML_REPORT}
    <component>
      <name>${PACKAGE}</name>
      <desc>$(dnf repoquery -q --queryformat "%{description}" $PACKAGE)</desc>
    </component>
EOF
        done
    else
        for PACKAGE in $(cat $LIST | cut -d ' ' -f1 | sort -u); do
            cat << EOF >> ${HTML_REPORT}
    <component>
      <name>${PACKAGE}</name>
      <desc>document</desc>
    </component>
EOF
        done
    fi
    echo "  </components>" >> ${HTML_REPORT}
}

########################################################

function download_all_project_translations {
    ${WORK_PATH}/${PROJECT_NAME}.sh -a;
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
REQUIRED_PACKAGES=( java-1.8.0-openjdk perl-Locale-Codes sqlite tidy )
source ${WORK_PATH}/common/install-pakages.sh
install-pakages ${REQUIRED_PACKAGES[@]}

#########################################
# LANGUAGETOOL
#########################################
source ${WORK_PATH}/common/languagetool.sh

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
        LOCALES=( )
        for LOCALE in ${locales[@]}; do
            if [ "$LOCALE" == "pt_BR" ] && [ "$PROJECT" == "fedora-upstream" ]; then
                continue;
            fi
            id_locale=$(sqlite3 ${DB_PATH} "SELECT id FROM t_locales WHERE locale = '${LOCALE}';")
            id_update=$(sqlite3 ${DB_PATH} "SELECT id FROM t_updates WHERE id_project = ${id_project} AND id_locale = ${id_locale};")
            if [ -n "${id_update}" ]; then
                date_file_t_updates=$(sqlite3 ${DB_PATH} "SELECT date_file FROM t_updates WHERE id = ${id_update};")
                date_report_t_updates=$(sqlite3 ${DB_PATH} "SELECT date_report FROM t_updates WHERE id = ${id_update};")
                if [ "$date_report_t_updates" -le "$date_file_t_updates" ]; then
                    locale_report ${LOCALE}
                    sqlite3 ${DB_PATH} "UPDATE t_updates SET date_report = $(date '+%Y%m%d%H') WHERE id = ${id_update};"
                fi
                LOCALES+=( $LOCALE )
            fi
        done
        create_project_report_stats
        start_report_data_xml
        start_locales_report
        for LOCALE in ${LOCALES[@]}; do
            id_locale=$(sqlite3 ${DB_PATH} "SELECT id FROM t_locales WHERE locale = '${LOCALE}';")
            id_update=$(sqlite3 ${DB_PATH} "SELECT id FROM t_updates WHERE id_project = ${id_project} AND id_locale = ${id_locale};")
            if [ -n "${id_update}" ]; then
                date_file_t_updates=$(sqlite3 ${DB_PATH} "SELECT date_file FROM t_updates WHERE id = ${id_update};")
                locale_report_data ${LOCALE} $(echo "$date_file_t_updates" | cut -c -8)
            fi
        done
        end_locales_report
        report_package_table
        end_report_data_xml
        chmod 644 ${REPORT_PATH}/data.xml
        scp -i ~/.ssh/id_rsa ${REPORT_PATH}/data.xml rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/report/${PROJECT_NAME}/data.xml

        sqlite3 ${DB_PATH} "UPDATE t_projects SET date_report = $(date '+%Y%m%d%H') WHERE id = ${id_project};"
    fi
done

#########################################
# LANGUAGETOOL
#########################################
kill -9 $LANGUAGETOOL_PID > /dev/null
