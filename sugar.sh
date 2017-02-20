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

WORK_PATH=$PWD
BASE_PATH=${WORK_PATH}/sugar
LIST=${WORK_PATH}/list/sugar.list

LANG_CODE=
GENERATE_REPORT=
INSTALL_TRANS=

function usage {
    echo "This script downloads the translations of the Sugar Labs project"
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   -i, --install         Install translations"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

function update_src {
    cd ${BASE_PATH}
    if [ ! -d "${BASE_PATH}/${1}" ]; then
        echo -ne "$1 : git clone "
        git clone $2 $1 &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    else
        cd $1
        echo -ne "$1 : git pull "
        git pull &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    fi
}

function download_trans {
    echo -ne "$1 : downloading translation"
    curl -s -S $2 > ${BASE_PATH}/${1}/po/${LANG_CODE}.po && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
}

function download {
    echo "************************************************"
    echo "* downloading sources & translations..."
    echo "************************************************"
    for PROJECT in sugar sugar-toolkit-gtk3; do
        echo -ne ${PROJECT}" "
        curl -s -S http://translate.sugarlabs.org/export/${PROJECT}/${LANG_CODE}.po > ${BASE_PATH}/${PROJECT}.po && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
    done

    echo -ne "olpc-switch-desktop "; curl -s -S http://translate.sugarlabs.org/export/OLPC_switch_desktop/${LANG_CODE}/${LANG_CODE}.po > ${BASE_PATH}/olpc-switch-desktop.po && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"

    while read -r p; do
        set -- ${p//"LOCALE"/${LANG_CODE}}
        if [ $# -ge 3 ]; then
            update_src $1 $3
            download_trans $1 $2
        fi
    done < ${LIST}
}

# project_name rpm
function install_builddeps {
    echo -ne ${1}" : installing builddeps "
    dnf builddep -y ${2} &> /dev/null && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
}

# project_name
function build_code {
    echo -ne ${1}" : build "
    cd ${BASE_PATH}/${1}
    python setup.py build &> /dev/null && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
}

function install_binaries {
    echo -ne ${1}" : installing binaries"
    cd ${BASE_PATH}/${1}
    python setup.py install &> /dev/null && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
}

function install {
    for PROJECT in sugar sugar-toolkit-gtk3 olpc-switch-desktop; do
        echo -ne "${PROJECT} : installing translation "
        rm -f /usr/share/locale/${LANG_CODE}/LC_MESSAGES/${PROJECT}.mo
        msgfmt ${BASE_PATH}/${PROJECT}.po -o /usr/share/locale/${LANG_CODE}/LC_MESSAGES/${PROJECT}.mo && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
    done
    while read -r p; do
        set -- ${p//"LOCALE"/${LANG_CODE}}
        if [ $# -ge 4 ]; then
            install_builddeps $1 $4
            build_code $1
            install_binaries $1
        fi
    done < ${LIST}
}

# section project_name html_file
function report_toc_project {
    cat << EOF >> ${3}
    <li><span class="secno">${1}</span> <span><a href="#${2}">${2}</a></span>
      <ul class="toc">
        <li><span class="secno">${1}.1</span> <span><a href="#CheckSpellEc${2}">check-spell-ec</a></span></li>
        <li><span class="secno">${1}.2</span> <span><a href="#CheckRules${2}">check-rules</a></span></li>
        <li><span class="secno">${1}.3</span> <span><a href="#CheckGrammar${2}">check-grammar</a></span></li>
        <li><span class="secno">${1}.4</span> <span><a href="#Stats${2}">stats</a></span></li>
      </ul>
    </li>
EOF
}

# project_name translation_file html_filename
function report_project_cotent {
    cat << EOF >> $3
<h1 id=${1}>${1} <a href="#toc">[^]</a></h1>
<h2 id=CheckSpellEc${1}>check-spell-ec <a href="#toc">[^]</a></h2>
EOF
    posieve check-spell-ec -s lang:${LANG_CODE} --skip-obsolete --coloring-type=html $2 >> $3
    cat << EOF >> $3
<h2 id=CheckRules${1}>check-rules <a href="#toc">[^]</a></h2>
EOF
    posieve check-rules -s lang:${LANG_CODE} -s showfmsg --skip-obsolete --coloring-type=html $2 >> $3
    cat << EOF >> $3
<h2 id=CheckGrammar${1}>check-grammar <a href="#toc">[^]</a></h2>
EOF
    posieve check-grammar -s lang:${LANG_CODE} --skip-obsolete --coloring-type=html $2 >> $3
    cat << EOF >> $3
<h2 id=Stats${1}>stats <a href="#toc">[^]</a></h2>
EOF
    posieve stats --msgfmt-check --skip-obsolete --coloring-type=html $2 >> $3
}

function install_pology {
    if [ ! -d "${WORK_PATH}/pology" ]; then
        echo "report : building pology"
        cd ${WORK_PATH}
        svn checkout svn://anonsvn.kde.org/home/kde/trunk/l10n-support/pology
        cd pology
        mkdir build && cd build
        cmake ..
        make
    fi
}

function report {
    rpm -q pology aspell-${LANG_CODE} python-enchant enchant-aspell &> /dev/null
    if [ $? -ne 0 ]; then
        echo "report : installing required packages"
        set -x
        sudo dnf install -y pology aspell-${LANG_CODE} python-enchant enchant-aspell
        set -
    fi
    #########################################
    # LANGUAGETOOL
    #########################################
    if [ ! -d "${WORK_PATH}/languagetool" ]; then
        ${WORK_PATH}/common/build-languagetool.sh --path=${WORK_PATH} -l={LANG_CODE}
    fi
    cd ${WORK_PATH}
    LANGUAGETOOL=`find . -name 'languagetool-server.jar'`
    java -cp $LANGUAGETOOL org.languagetool.server.HTTPServer --port 8081 > /dev/null &
    LANGUAGETOOL_PID=$!

    echo -ne "report : waiting for langtool"
    until $(curl --output /dev/null --silent --data "language=ca&text=Hola món!" --fail http://localhost:8081); do
        printf '.'
        sleep 1
    done
    if [ $? -ne 0 ]; then
        echo " ${RED}[ FAIL ]${NC}"
    else
        echo " ${GREEN}[ OK ]${NC}"
    fi

    HTML_REPORT=${WORK_PATH}/sugar-report.html
    cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html lang="ca" xml:lang="ca" xmlns="http://www.w3.org/1999/xhtml">
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
<h1 id=toc>Table of contents</h1>
<div data-fill-with="table-of-contents"><ul class="toc">
  <li><span class="secno">1</span> <span><a href="#Sucrose">Sucrose</a></span>
    <ul class="toc">
EOF

    echo "************************************************"
    echo "* checking translations..."
    echo "************************************************"

    COUNTER=1
    for PROJECT in sugar sugar-toolkit-gtk3 olpc-switch-desktop; do
        report_toc_project 2.${COUNTER} ${PROJECT} ${HTML_REPORT}
        let "COUNTER++"
    done

    cat << EOF >> ${HTML_REPORT}
    </ul>
  </li>
  <li><span class="secno">2</span> Activities</span>
  <ul class="toc">
EOF

    COUNTER=1
    while read -r p; do
        set -- $p
        if [ $# -ge 3 ]; then
            report_toc_project 2.${COUNTER} ${1} ${HTML_REPORT}
            let "COUNTER++"
        fi
    done < ${LIST}

    cat << EOF >> ${HTML_REPORT}
  </ul>
  </li>
</ul>
<h1 id="Sucrose">Sucrose</h1>
EOF

    for PROJECT in sugar sugar-toolkit-gtk3 olpc-switch-desktop; do
        report_project_cotent ${PROJECT} ${BASE_PATH}/${PROJECT}.po ${HTML_REPORT}
    done

    while read -r p; do
        set -- $p
        set -- ${p//"LOCALE"/${LANG_CODE}}
        echo "${1} : check translations"
        if [ $# -ge 3 ]; then
            report_project_cotent ${1} ${BASE_PATH}/${1}/po/${LANG_CODE}.po ${HTML_REPORT}
        fi
    done < ${LIST}

    cat << EOF >> ${HTML_REPORT}
</body>
</html>
EOF
    chmod 644 ${HTML_REPORT}
    kill -9 $LANGUAGETOOL_PID > /dev/null
}

# ensure running as root
if [ "$(id -u)" != "0" ]; then
  exec sudo "$0" "$@"
  exit 0
fi

for i in "$@"
do
case $i in
    -l=*|--lang=*)
    LANG_CODE="${i#*=}"
    shift # past argument=value
    ;;
    -r|--report)
    GENERATE_REPORT="YES"
    ;;
    -i|--install)
    INSTALL_TRANS="YES"
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

if [ -z "${LANG_CODE}" ]; then
    usage
    exit 1
fi

if [ ! -d "${BASE_PATH}" ]; then
    mkdir ${BASE_PATH}
fi

### Main ###
download
if [ -n "$GENERATE_REPORT" ]; then
    report
fi
if [ -n "$INSTALL_TRANS" ]; then
    install
fi
echo "complete!"
