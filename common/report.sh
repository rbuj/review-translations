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
LT_EXTERNAL=

# project_name project_version html_filename
function report_project_cotent {
    local COMPONENT=${1}
    local HTML_REPORT=${HTML_REPORT_PATH}/data/${COMPONENT}.html

    if [ ! -d "${HTML_REPORT_PATH}/data" ]; then
        mkdir -p ${HTML_REPORT_PATH}/data
        chmod 755 ${HTML_REPORT_PATH}/data
    fi

    declare -i date_file=$(sqlite3 ${REPORT_DB_PATH} "SELECT date_file FROM t_components WHERE name = '${COMPONENT}';")
    declare -i date_report=$(sqlite3 ${REPORT_DB_PATH} "SELECT date_report FROM t_components WHERE name = '${COMPONENT}';")
    if [ "$date_report" -gt "$date_file" ]; then
        return 0;
    fi

    sed "s/LANG_CODE/$LANG_CODE/g;s/COMPONENT/$COMPONENT/g" ${WORK_PATH}/snippet/html.report.COMPONENT.start.txt > ${HTML_REPORT}
    local LANG_CODE_SIEVE=${LANG_CODE/_/-}
    cd ${BASE_PATH}/${COMPONENT}
    case $LANG_CODE_SIEVE in
        be|be-BY|br|br-FR|ca|ca-ES|da|da-DK|de|de-AT|de-CH|de-DE|el|el-GR|eo|es|fa|fr|gl|gl-ES|is-IS|it|lt|lt-LT|km-KH|ml|ml-IN|nl|pl|pl-PL|pt|pt-BR|pt-PT|ro|ro-RO|ru|ru-RU|sk|sk-SK|sl|sl-SI|sv|ta|ta-IN|tl-PH|uk|uk-UA)
            echo "<h2>check-spell-ec</h2>" >> ${HTML_REPORT}
            LC_ALL=en_US.UTF-8 posieve check-spell-ec -s lang:${LANG_CODE/-/_} -s provider:myspell --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ./ >> ${HTML_REPORT}
            echo "<h2>check-grammar</h2>" >> ${HTML_REPORT}
            LC_ALL=en_US.UTF-8 posieve check-grammar -s lang:${LANG_CODE_SIEVE} -s host:${LT_SERVER} -s port:${LT_PORT} --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ./ >> ${HTML_REPORT}
        ;;
        ja|ja-JP|zh-CN)
            echo "<h2>check-spell-ec</h2>" >> ${HTML_REPORT}
            LC_ALL=en_US.UTF-8 posieve check-spell-ec -s lang:${LANG_CODE_SIEVE} -s suponly --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ./ >> ${HTML_REPORT}
            echo "<h2>check-grammar</h2>" >> ${HTML_REPORT}
            LC_ALL=en_US.UTF-8 posieve check-grammar -s lang:${LANG_CODE_SIEVE} -s host:${LT_SERVER} -s port:${LT_PORT} --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ./ >> ${HTML_REPORT}
        ;;
        *)
            if [ -f "/usr/share/myspell/${LANG_CODE/-/_}.dic" ]; then
                echo "<h2>check-spell-ec</h2>" >> ${HTML_REPORT}
                LC_ALL=en_US.UTF-8 posieve check-spell-ec -s lang:${LANG_CODE/-/_} -s provider:myspell --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ./ >> ${HTML_REPORT}
            fi
        ;;
    esac
    cat ${WORK_PATH}/snippet/html.report.COMPONENT.end.txt >> ${HTML_REPORT}

    # xml
    cat ${WORK_PATH}/snippet/check-grammar.start.xml > ${HTML_REPORT_PATH}/data/${COMPONENT}.xml
    sed -n '/^[\-]\{2,\}<br\/>$/,/^<br\/>$/p' ${HTML_REPORT} | perl ${WORK_PATH}/snippet/parse-grammar.pl >> ${HTML_REPORT_PATH}/data/${COMPONENT}.xml
    cat ${WORK_PATH}/snippet/check-grammar.end.xml >> ${HTML_REPORT_PATH}/data/${COMPONENT}.xml

    # backup
    mv ${HTML_REPORT} ${HTML_REPORT_PATH}/data/${COMPONENT}.out.html

    # html
    local NUM_GRAMMAR_ISSUES=$(xmllint --xpath "count(//item)" ${HTML_REPORT_PATH}/data/${COMPONENT}.xml)
    if [ "$NUM_GRAMMAR_ISSUES" -gt "0" ]; then
        source ${WORK_PATH}/snippet/jquery.version
        cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html>
<head>
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
 <title>Translation Report</title>
 <link rel="stylesheet" type="text/css" href="../css/component.css">
 <script src="../javascript/jquery-$JQUERY_VERSION.slim.min.js"></script>
 <script src="../javascript/mustache.min.js"></script>
 <script src="../javascript/jquery.tablesorter.min.js"></script>
 <script>
  function loadContent() {
   var template = \$('#grammarIssuesTemplate').html();
   Mustache.parse(template);   // optional, speeds up future uses
   var data = {
    grammarIssues: [$(xsltproc ${WORK_PATH}/snippet/check-grammar.xsl ${HTML_REPORT_PATH}/data/${COMPONENT}.xml)]
   };
   var rendered = Mustache.render(template, data);
   \$('#grammarIssuesDiv').html(rendered).promise().done(function() {
    \$("#reportTable").tablesorter();
   });
  };
 </script>
</head>
<body onload="loadContent()">
 <h1>$COMPONENT</h1>
$(cat ${HTML_REPORT_PATH}/data/${COMPONENT}.out.html | perl ${WORK_PATH}/snippet/parse-spelling.pl)
 <br>
 <div id="grammarIssuesDiv">Loading...</div>
 <script id="grammarIssuesTemplate" type="x-tmpl-mustache">
  <table id="reportTable" class="tablesorter">
   <thead>
    <tr style="background-color:#9ACD32;">
     <th style="text-align:left;">File</th>
     <th style="text-align:left;">Context</th>
     <th style="text-align:left;">Tip</th>
     <th style="text-align:left;">Rule</th>
    </tr>
   </thead>
   <tbody>
    {{#grammarIssues}}
     <tr><td>{{& file }}</td><td>{{& context }}</td><td>{{& tip }}</td><td>{{& rule }}</td></tr>
    {{/grammarIssues}}
   <tbody>
 </script>
</body>
</html>
EOF
    else
        cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html>
<head>
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
 <title>Translation Report</title>
 <link rel="stylesheet" type="text/css" href="../css/component.css">
</head>
<body>
 <h1>$COMPONENT</h1>
$(cat ${HTML_REPORT_PATH}/data/${COMPONENT}.out.html | perl ${WORK_PATH}/snippet/parse-spelling.pl)
</body>
</html>
EOF
    fi
    chmod 644 ${HTML_REPORT}
    sqlite3 ${REPORT_DB_PATH} "UPDATE t_components SET date_report = "$(date "+%Y%m%d%H")" WHERE name = '${COMPONENT}';"
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
    sqlite3 ${REPORT_DB_PATH} < ${WORK_PATH}/sql/locale_report_create_tables.sql
    local COMPONENTS=()
    local COMPONENT_NAME=
    while read -r p; do
        set -- $p
        case $TYPE in
            fedora)
                COMPONENT_NAME="${1}-${2}"
            ;;
            bzr|git|transifex)
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
        date_file=$(find ${BASE_PATH}/${COMPONENT_NAME} -type f -name ${LANG_CODE}.po -exec date -r {} "+%Y%m%d%H" \; | sort | tail -1)
        if [ -z "${date_file}" ]; then
            continue
        fi
        sqlite3 ${REPORT_DB_PATH} "INSERT OR IGNORE INTO t_components (name) VALUES ('${COMPONENT_NAME}');"
        sqlite3 ${REPORT_DB_PATH} "UPDATE t_components SET date_file = ${date_file} WHERE name = '${COMPONENT_NAME}';"
        # translated words > 0
        if [ "$(LC_ALL=en_US.UTF-8 posieve stats --coloring-type=none --include-name=${LANG_CODE}\$ ${BASE_PATH}/${COMPONENT_NAME} | xargs -n 8 | perl -alne '/^total.*/ && print $F[5]')" -gt "0" ]; then
            COMPONENTS+=("${COMPONENT_NAME}")
        fi
    done <${LIST}

    #########################################
    # LANGUAGETOOL
    #########################################
    if [ -z "${LT_EXTERNAL}" ]; then
        source ${WORK_PATH}/common/languagetool.sh
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
    # HTML
    #########################################
    local HTML_REPORT="${HTML_REPORT_PATH}/index.html"
    echo "************************************************"
    echo "* checking translations..."
    echo "************************************************"
    local FILES=()
    local JSON_FILES=()
    for COMPONENT in ${COMPONENTS[@]}; do
        report_project_cotent ${COMPONENT}
        if [ -f "${HTML_REPORT_PATH}/data/${COMPONENT}.html" ]; then
            FILES+=("${PROJECT_NAME}-report-${LANG_CODE}/data/${COMPONENT}.html")
            jq -n "{name: \"$COMPONENT\"} + {url: \"data/$COMPONENT.html\"}" --indent n > ${HTML_REPORT_PATH}/${COMPONENT}.json
            JSON_FILES+=(${HTML_REPORT_PATH}/${COMPONENT}.json)
        fi
    done
    source ${WORK_PATH}/snippet/jquery.version
    cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html>
<head>
 <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
 <title>Translation Report</title>
 <link rel="stylesheet" type="text/css" href="css/nav.css">
 <script src="javascript/jquery-$JQUERY_VERSION.slim.min.js"></script>
 <script src="javascript/mustache.min.js"></script>
 <script>
  var make_button_active = function() {
   var siblings =(\$(this).siblings());
   siblings.each(function (index) {
    \$(this).removeClass('active');
   })
   \$(this).addClass('active');
  }
  function loadMenu() {
   var template = \$('#template').html();
   Mustache.parse(template);   // optional, speeds up future uses
   var data = {
    components: $(jq --indent n "sort_by(.name)" --slurp . ${JSON_FILES[*]})
   };
   var rendered = Mustache.render(template, data);
   \$('#container').html(rendered).promise().done(function() {
    \$(".menu li").click(make_button_active);
   });
  };
 </script>
</head>
<body onload="loadMenu()">
 <div id="container" style="display: flex; min-height: 100vh;">Loading...</div>
 <script id="template" type="x-tmpl-mustache">
  <ul class="menu">
  {{#components}}
   <li><a href="javascript:;" onclick="document.getElementById('main_page').src='{{& url }}';document.body.scrollTop=0;document.documentElement.scrollTop=0;return true;">{{ name }}</a></li>
  {{/components}}
  </ul>
  <iframe src="data/emty.html" style="flex:1;border:none;" name="main_page" id="main_page"></iframe>
 </script>
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
    source ${WORK_PATH}/common/download-jquery.sh
    if [ ! -f "${HTML_REPORT_PATH}/javascript/jquery-${JQUERY_VERSION}.slim.min.js" ]; then
        cp ${WORK_PATH}/snippet/jquery-${JQUERY_VERSION}.slim.min.js ${HTML_REPORT_PATH}/javascript/jquery-${JQUERY_VERSION}.slim.min.js > /dev/null
        chmod 644 "${HTML_REPORT_PATH}/javascript/jquery-${JQUERY_VERSION}.slim.min.js"
    fi
    FILES+=("${PROJECT_NAME}-report-${LANG_CODE}/javascript/jquery-${JQUERY_VERSION}.slim.min.js")

    source ${WORK_PATH}/common/download-tablesorter.sh
    if [ ! -f "${HTML_REPORT_PATH}/javascript/jquery.tablesorter.min.js" ]; then
        cp ${WORK_PATH}/snippet/jquery.tablesorter.min.js ${HTML_REPORT_PATH}/javascript/jquery.tablesorter.min.js > /dev/null
        chmod 644 "${HTML_REPORT_PATH}/javascript/jquery.tablesorter.min.js"
    fi
    FILES+=("${PROJECT_NAME}-report-${LANG_CODE}/javascript/jquery.tablesorter.min.js")

    source ${WORK_PATH}/common/download-mustache.sh
    if [ ! -f "${HTML_REPORT_PATH}/javascript/mustache.min.js" ]; then
        cp ${WORK_PATH}/snippet/mustache.min.js ${HTML_REPORT_PATH}/javascript/mustache.min.js > /dev/null
        chmod 644 "${HTML_REPORT_PATH}/javascript/mustache.min.js"
    fi
    FILES+=("${PROJECT_NAME}-report-${LANG_CODE}/javascript/mustache.min.js")

    if [ ! -d "${HTML_REPORT_PATH}/css" ]; then
        mkdir "${HTML_REPORT_PATH}/css"
    fi
    if [ ! -f "${HTML_REPORT_PATH}/css/nav.css" ]; then
        cp ${WORK_PATH}/css/nav.css ${HTML_REPORT_PATH}/css/nav.css > /dev/null
        chmod 644 "${HTML_REPORT_PATH}/css/nav.css"
    fi
    if [ ! -f "${HTML_REPORT_PATH}/css/component.css" ]; then
        cp ${WORK_PATH}/css/component.css ${HTML_REPORT_PATH}/css/component.css
        chmod 644 "${HTML_REPORT_PATH}/css/component.css"
    fi
    FILES+=("${PROJECT_NAME}-report-${LANG_CODE}/css/nav.css" "${PROJECT_NAME}-report-${LANG_CODE}/css/component.css")

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

#########################################
# REQUIRED PACKAGES
#########################################
REQUIRED_PACKAGES=( pology enchant-aspell java-1.8.0-openjdk perl-Locale-Codes python2-enchant sqlite tar xz jq perl-HTML-Strip libxslt libxml2 )
case $LANG_CODE in
    ast|en_GB|mai|pt_BR|zh_CN|zh_TW)
        REQUIRED_PACKAGES+=(langpacks-$LANG_CODE)
    ;;
    *)
        REQUIRED_PACKAGES+=(langpacks-${LANG_CODE:0:2})
    ;;
esac
source ${WORK_PATH}/common/install-pakages.sh
install-pakages ${REQUIRED_PACKAGES[@]}

# translated words == 0?
if [ "$(LC_ALL=en_US.UTF-8 posieve stats --coloring-type=none --include-name=${LANG_CODE}\$ ${BASE_PATH} | xargs -n 8 | perl -alne '/^total.*/ && print $F[5]')" -eq "0" ]; then
    exit 0
fi

if [ -n "${LT_SERVER}" ] && [ -n "${LT_PORT}" ]; then
    LT_EXTERNAL="YES"
else
    source ${WORK_PATH}/conf/languagetool.sh
fi


REPORT_PATH=${BASE_PATH}/report
HTML_REPORT_PATH=${REPORT_PATH}/${PROJECT_NAME}-report-${LANG_CODE}
REPORT_DB_PATH="${HTML_REPORT_PATH}.db"

if [ ! -d "${REPORT_PATH}" ]; then
    mkdir -p ${REPORT_PATH}
    chmod 755 ${REPORT_PATH}
fi
if [ ! -d "${HTML_REPORT_PATH}" ]; then
    mkdir -p ${HTML_REPORT_PATH}
    chmod 755 ${HTML_REPORT_PATH}
fi

report
