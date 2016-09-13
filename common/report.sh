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
REPORT_PATH=

LANG_CODE=
PROJECT_NAME=
TRANSLATION_TYPE=
INPUT_FILE=
DISABLE_WORDLIST=
VERBOSE=

LT_SERVER=
LT_PORT=
LT_EXTERNAL=

function usage {
    echo "usage : $0 -l|--lang=LANG_CODE -p|--project=PROJECT -f|--file=INPUT_FILE [ ARGS ... ]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo "   -p|--project=PROJECT  Base PROJECT folder for downloaded files"
    echo "   -f|--file=INPUT_FILE  INPUT_FILE that contains the project info"
    echo "   -w|--workpath=W_PATH  Work PATH folder"
    echo "   -t|--type=TYPE        TYPE of translation sorce one of fedora, git, transifex"
    echo -ne "\nOptional arguments:\n"
    echo "   --disable-wordlist    Do not use wordlist file"
    echo "   -h, --help            Display this help and exit"
    echo "   -v, --verbose         Verbose operation"
}

function fedora_wordlist {
    local DICT=${WORK_PATH}/pology/lang/${LANG_CODE}/spell/report-fedora.aspell
    if [ -n "${DISABLE_WORDLIST}" ]; then
        if [ -f "${DICT}" ]; then
            rm -f ${DICT}
        fi
    else
        if [ ! -d "${WORK_PATH}/pology/lang/${LANG_CODE}/spell" ]; then
            mkdir -p ${WORK_PATH}/pology/lang/${LANG_CODE}/spell
        fi
        local WORDS=`cat ${WORK_PATH}/wordlist | wc -l`
        echo "personal_ws-1.1 ${LANG_CODE} ${WORDS} utf-8" > ${DICT}
        cat ${WORK_PATH}/wordlist >> ${DICT}
    fi
}

# project_name project_version html_filename
function report_project_cotent {
    local COMPONENT=${1}
    local HTML_REPORT=${HTML_REPORT_PATH}/data/${COMPONENT}.html

    if [ ! -d "${HTML_REPORT_PATH}/data" ]; then
        mkdir -p ${HTML_REPORT_PATH}/data
        chmod 755 ${HTML_REPORT_PATH}/data
    fi

    declare -i date_file=$(sqlite3 ${DB_PATH} "SELECT date_file FROM t_components WHERE name = '${COMPONENT}';")
    declare -i date_report=$(sqlite3 ${DB_PATH} "SELECT date_report FROM t_components WHERE name = '${COMPONENT}';")
    if [ "$date_report" -gt "$date_file" ]; then
        return 0;
    fi

    cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html lang="${LANG_CODE}" xml:lang="${LANG_CODE}" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Translation Report</title>
    <style type="text/css">
        /* unvisited link */
        a:link {
            color: #D0D0D0;
        }

        /* visited link */
        a:visited {
            color: #00FF00;
        }

	/* mouse over link */
        a:hover {
            color: #FF00FF;
        }

	/* selected link */
        a:active {
            color: #0000FF;
        }
    </style>
  </head>
<body bgcolor="#080808" text="#D0D0D0">
<h1>${COMPONENT}</h1>
EOF
    local LANG_CODE_SIEVE=${LANG_CODE/_/-}
    case $LANG_CODE_SIEVE in
        be|be-BY|br|br-FR|ca|ca-ES|da|da-DK|de|de-AT|de-CH|de-DE|el|el-GR|eo|es|fa|fr|gl|gl-ES|is-IS|it|lt|lt-LT|km-KH|ml|ml-IN|nl|pl|pl-PL|pt|pt-BR|pt-PT|ro|ro-RO|ru|ru-RU|sk|sk-SK|sl|sl-SI|sv|ta|ta-IN|tl-PH|uk|uk-UA)
            echo "<h2>check-spell-ec</h2>" >> ${HTML_REPORT}
            posieve check-spell-ec -s lang:${LANG_CODE_SIEVE} --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${COMPONENT}/ >> ${HTML_REPORT}
            echo "<h2>check-grammar</h2>" >> ${HTML_REPORT}
            posieve check-grammar -s lang:${LANG_CODE_SIEVE} -s host:${LT_SERVER} -s port:${LT_PORT} --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${COMPONENT}/ >> ${HTML_REPORT}
        ;;
        ja|ja-JP|zh-CN)
            echo "<h2>check-spell-ec</h2>" >> ${HTML_REPORT}
            posieve check-spell-ec -s lang:${LANG_CODE_SIEVE} -s suponly --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${COMPONENT}/ >> ${HTML_REPORT}
            echo "<h2>check-grammar</h2>" >> ${HTML_REPORT}
            posieve check-grammar -s lang:${LANG_CODE_SIEVE} -s host:${LT_SERVER} -s port:${LT_PORT} --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${COMPONENT}/ >> ${HTML_REPORT}
        ;;
        *)
            echo "<h2>check-spell-ec</h2>" >> ${HTML_REPORT}
            posieve check-spell-ec -s lang:${LANG_CODE} --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${COMPONENT}/ >> ${HTML_REPORT}
        ;;
    esac
    cat << EOF >> ${HTML_REPORT}
</body>
</html>
EOF
    chmod 644 ${HTML_REPORT}
    sqlite3 ${DB_PATH} "UPDATE t_components SET date_report = "$(date "+%Y%m%d%H")" WHERE name = '${COMPONENT}';"
}

function report {
    declare -i global_date_file
    global_date_file=$(find ${BASE_PATH} -type f -name ${LANG_CODE}.po -exec date -r {} "+%Y%m%d%H" \; | sort | tail -1)
    if [ -z "${global_date_file}" ]; then
        return
    fi

    #########################################
    # DB
    #########################################
    echo "************************************************"
    echo "* Updating database..."
    echo "************************************************"
    sqlite3 ${DB_PATH} < ${WORK_PATH}/sql/locale_report_create_tables.sql
    local COMPONENTS=()
    local COMPONENT_NAME=
    while read -r p; do
        set -- $p
        case $TRANSLATION_TYPE in
            fedora)
                COMPONENT_NAME="${1}-${2}"
            ;;
            git|transifex)
                COMPONENT_NAME="${1}"
            ;;
            *)
              	usage
                exit 1
            ;;
	esac

        declare -i date_file

        # add the component in t_components table if not exists, and update date_file field (PO_FILE latest modification)
        if [ ! -d "${BASE_PATH}/${COMPONENT_NAME}" ]; then
            continue
        fi
        date_file=$(find ${BASE_PATH}/${COMPONENT_NAME}  -type f -name ${LANG_CODE}.po -exec date -r {} "+%Y%m%d%H" \; | sort | tail -1)
        if [ -z "${date_file}" ]; then
            continue
        fi
        COMPONENTS+=("${COMPONENT_NAME}")
        sqlite3 ${DB_PATH} "INSERT OR IGNORE INTO t_components (name) VALUES ('${COMPONENT_NAME}');"
        sqlite3 ${DB_PATH} "UPDATE t_components SET date_file = ${date_file} WHERE name = '${COMPONENT_NAME}';"
    done <${INPUT_FILE}

    #########################################
    # LANGUAGETOOL
    #########################################
    if [ -z "${LT_EXTERNAL}" ]; then
        if [ ! -d "${WORK_PATH}/languagetool" ]; then
            ${WORK_PATH}/common/build-languagetool.sh --path=${WORK_PATH} -l=${LANG_CODE}
        fi
        cd ${WORK_PATH}
        LANGUAGETOOL=`find . -name 'languagetool-server.jar'`
        java -cp $LANGUAGETOOL org.languagetool.server.HTTPServer --port 8081 > /dev/null &
        LANGUAGETOOL_PID=$!
        LT_SERVER="localhost"
        LT_PORT="8081"
    fi
    echo -ne "report : waiting for langtool"
    until $(curl --output /dev/null --silent --data "language=ca&text=Hola món!" --fail http://${LT_SERVER}:${LT_PORT}); do
        printf '.'
        sleep 1
    done
    if [ $? -ne 0 ]; then
        echo " ${RED}[ FAIL ]${NC}"
    else
        echo " ${GREEN}[ OK ]${NC}"
    fi

    #########################################
    # POLOGY
    #########################################
    if [ ! -d "${WORK_PATH}/pology" ]; then
        ${WORK_PATH}/common/build-pology.sh --path=${WORK_PATH}
    fi
    export PYTHONPATH=${WORK_PATH}/pology:$PYTHONPATH
    export PATH=${WORK_PATH}/pology/bin:$PATH

    fedora_wordlist

    #########################################
    # HTML
    #########################################
    HTML_REPORT="${HTML_REPORT_PATH}/index.html"
    echo "************************************************"
    echo "* checking translations..."
    echo "************************************************"
    cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html>
<head>
<title>Translation Report</title>
<style>
.menu {
    list-style-type: none;
    white-space:nowrap;
    margin: 0;
    padding: 0;
    background-color: #080808;
    color: #D0D0D0;
}

.menu li a {
    display: block;
    color: #D0D0D0;
    padding: 8px 16px;
    text-decoration: none;
}

.menu li a:hover, .menu li.active a {
    background-color: #D0D0D0;
    color: #080808;
}
</style>
<script type="text/javascript" src="javascript/jquery-3.1.0.slim.js"></script>
<script>
var make_button_active = function()
{
  var siblings =(\$(this).siblings());

  siblings.each(function (index)
    {
      \$(this).removeClass('active');
    }
  )


  \$(this).addClass('active');
}

\$(document).ready(
  function()
  {
    \$(".menu li").click(make_button_active);
  }
)
</script>
</head>
<body>

<div id="container" style="display: flex; min-height: 100vh;">
    <ul class="menu">
EOF
    local FILES=()
    for COMPONENT in ${COMPONENTS[@]}; do
        report_project_cotent ${COMPONENT}
        if [ -f "${HTML_REPORT_PATH}/data/${COMPONENT}.html" ]; then
            FILES+=("${PROJECT_NAME}-report-${LANG_CODE}/data/${COMPONENT}.html")
            cat << EOF >> ${HTML_REPORT}
      <li><a href="data/${COMPONENT}.html" target="main_page">${COMPONENT}</a></li>
EOF
        fi
    done
    cat << EOF >> ${HTML_REPORT}
    </ul>
    <iframe src="data/emty.html" style="flex: 1;" frameBorder="0" name="main_page"></iframe>
</div>

</body>
</html>
EOF
    chmod 644 ${HTML_REPORT}
    FILES+=("${PROJECT_NAME}-report-${LANG_CODE}/index.html")

    if [ ! -f "${HTML_REPORT_PATH}/data/emty.html" ]; then
        touch "${HTML_REPORT_PATH}/data/emty.html"
        chmod 644 "${HTML_REPORT_PATH}/data/emty.html"
    fi
    FILES+=("${PROJECT_NAME}-report-${LANG_CODE}/data/emty.html")

    if [ ! -d "${HTML_REPORT_PATH}/javascript" ]; then
        mkdir -p "${HTML_REPORT_PATH}/javascript"
        chmod 755 "${HTML_REPORT_PATH}/javascript"
    fi
    if [ ! -f "${HTML_REPORT_PATH}/javascript/jquery-3.1.0.slim.js" ]; then
        curl --output "${HTML_REPORT_PATH}/javascript/jquery-3.1.0.slim.js" https://code.jquery.com/jquery-3.1.0.slim.min.js > /dev/null
        chmod 644 "${HTML_REPORT_PATH}/javascript/jquery-3.1.0.slim.js"
    fi
    FILES+=("${PROJECT_NAME}-report-${LANG_CODE}/javascript/jquery-3.1.0.slim.js")

    cd ${REPORT_PATH}
    if [ -f "${PROJECT_NAME}-report-${LANG_CODE}.txz" ]; then
        rm -f "${PROJECT_NAME}-report-${LANG_CODE}.txz"
    fi
    echo "XZ_OPT=-9 tar -Jcvf ${PROJECT_NAME}-report-${LANG_CODE}.txz ${FILES[@]}" | sh
    chmod 644 ${PROJECT_NAME}-report-${LANG_CODE}.txz

    if [ -z "${LT_EXTERNAL}" ]; then
        kill -9 $LANGUAGETOOL_PID > /dev/null
    fi
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
    --disable-wordlist)
    DISABLE_WORDLIST="YES"
    ;;
    --languagetool-server=*)
    LT_SERVER="${i#*=}"
    shift # past argument=value
    ;;
    --languagetool-port=*)
    LT_PORT="${i#*=}"
    shift # past argument=value
    ;;
    -w=*|--workpath=*)
    WORK_PATH="${i#*=}"
    shift # past argument=value
    ;;
    -t=*|--type=*)
    TRANSLATION_TYPE="${i#*=}"
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

if [ -z "${LANG_CODE}" ] || [ -z "${INPUT_FILE}" ] || [ -z "${PROJECT_NAME}" ] || [ -z "${WORK_PATH}" ] || [ -z "${TRANSLATION_TYPE}" ]; then
    usage
    exit 1
fi
if [ -n "${LT_SERVER}" ] && [ -n "${LT_PORT}" ]; then
    LT_EXTERNAL="YES"
fi


#########################################
# REQUIRED PACKAGES
#########################################
for REQUIRED_PACKAGE in enchant-aspell java-1.8.0-openjdk langpacks-$LANG_CODE perl-Locale-Codes python-enchant sqlite tar xz; do
    rpm -q $REQUIRED_PACKAGE &> /dev/null
    if [ $? -ne 0 ]; then
        echo "report : installing required package : $REQUIRED_PACKAGE"
        VERSION_AUX=( $(cat /etc/fedora-release) )
        set -x
	if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y $REQUIRED_PACKAGE --nogpgcheck; else sudo dnf install -y $REQUIRED_PACKAGE; fi
        set -
    fi
done

BASE_PATH=${WORK_PATH}/${PROJECT_NAME}
REPORT_PATH=${BASE_PATH}/report
HTML_REPORT_PATH=${REPORT_PATH}/${PROJECT_NAME}-report-${LANG_CODE}
DB_PATH="${HTML_REPORT_PATH}.db"

if [ ! -d "${REPORT_PATH}" ]; then
    mkdir -p ${REPORT_PATH}
    chmod 755 ${REPORT_PATH}
fi
if [ ! -d "${HTML_REPORT_PATH}" ]; then
    mkdir -p ${HTML_REPORT_PATH}
    chmod 755 ${HTML_REPORT_PATH}
fi


### Main ###
report
