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
RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0` # No Color

WORK_PATH=$PWD
BASE_PATH=${WORK_PATH}/XFCE
BASE_PATH_RPM=${WORK_PATH}/XFCE/rpm
LIST=${WORK_PATH}/list/xfce.list

LANG_CODE=
GENERATE_REPORT=
DISABLE_WORDLIST=
INSTALL_TRANS=
VERSION=$(${WORK_PATH}/common/fedora-version.sh)

function usage {
    echo "This script downloads the translation of XFCE"
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   --disable-wordlist    Do not use wordlist file"
    echo "   -i, --install         Install translations"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

function download_code {
    cd ${BASE_PATH}
    if [ ! -d "${1}" ]; then
        echo -ne "git clone "
        git clone $2 $1 &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    else
        cd $1
        echo -ne "git pull "
        git pull &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    fi
}

function fedora_wordlist {
    DICT=${WORK_PATH}/pology/lang/${LANG_CODE}/spell/report-fedora.aspell
    if [ -n "${DISABLE_WORDLIST}" ]; then
        if [ -f "${DICT}" ]; then
            rm -f ${DICT}
        fi
    else
        if [ ! -d "${WORK_PATH}/pology/lang/${LANG_CODE}/spell" ]; then
            mkdir -p ${WORK_PATH}/pology/lang/${LANG_CODE}/spell
        fi
        WORDS=`cat ${WORK_PATH}/wordlist | wc -l`
        echo "personal_ws-1.1 ${LANG_CODE} ${WORDS} utf-8" > ${DICT}
        cat ${WORK_PATH}/wordlist >> ${DICT}
    fi
}

function report_toc {
    HTML_REPORT=${1}
    cat << EOF >> ${HTML_REPORT}
<h1 id=toc>Table of contents</h1>
<div data-fill-with="table-of-contents"><ul class="toc">
EOF
    COUNTER=1
    while read -r p; do
        set -- $p
        cat << EOF >> ${HTML_REPORT}
  <li><span class="secno">${COUNTER}</span> <span><a href="#${1}">${1}</a></span></li>
EOF
        let "COUNTER++"
    done <${LIST}
    cat << EOF >> ${HTML_REPORT}
<ul></div>
EOF
}

# project_name html_filename
function report_project_cotent {
    cat << EOF >> $2
<h1 id=${1}>${1}<a href="#toc">[^]</a></h1>
<h2 id=CheckSpellEc${1}>check-spell-ec <a href="#toc">[^]</a></h2>
EOF
    posieve check-spell-ec -s lang:${LANG_CODE} --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${1}/ >> $2
    cat << EOF >> $2
<h2 id=CheckRules${1}>check-rules <a href="#toc">[^]</a></h2>
EOF
    posieve check-rules -s lang:${LANG_CODE} -s showfmsg --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${1}/ >> $2
    cat << EOF >> $2
<h2 id=CheckGrammar${1}>check-grammar <a href="#toc">[^]</a></h2>
EOF
    posieve check-grammar -s lang:${LANG_CODE} --skip-obsolete --coloring-type=html --include-name=${LANG_CODE}\$ ${BASE_PATH}/${1}/ >> $2
}

function report {
    rpm -q aspell-${LANG_CODE} python-enchant enchant-aspell &> /dev/null
    if [ $? -ne 0 ]; then
        echo "report : installing required packages"
        set -x
        sudo dnf install -y aspell-${LANG_CODE} python-enchant enchant-aspell
        set -
    fi
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

    #########################################
    # POLOGY
    #########################################
    if [ ! -d "${WORK_PATH}/pology" ]; then
        ${WORK_PATH}/common/build-pology.sh --path=${WORK_PATH}
    fi
    export PYTHONPATH=${WORK_PATH}/pology:$PYTHONPATH
    export PATH=${WORK_PATH}/pology/bin:$PATH
    fedora_wordlist

    HTML_REPORT=${WORK_PATH}/XFCE-report.html
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
EOF

    report_toc ${HTML_REPORT}
    COUNTER=1
    if [ ! -d "${BASE_PATH}" ]; then
        mkdir -p "${BASE_PATH}"
    fi
    while read -r p; do
        set -- $p
        cd ${BASE_PATH}
        echo -ne "${1}: "
        download_code ${1} ${2}
        cd ${BASE_PATH}/${1}
        report_project_cotent ${1} ${HTML_REPORT}

    done <${LIST}

    cat << EOF >> ${HTML_REPORT}
</body>
</html>
EOF

    chmod 644 ${HTML_REPORT}
    kill -9 ${LANGUAGETOOL_PID} > /dev/null
}

function install {
    echo "installing translations"

    rpm -q fedpkg fedora-packager rpmdevtools &> /dev/null
    if [ $? -ne 0 ]; then
        echo "installing required packages"
        set -x
        sudo dnf install -y fedpkg fedora-packager rpmdevtools
        set -
    fi

    if [ ! -d "${BASE_PATH_RPM}" ]; then
        mkdir -p "${BASE_PATH_RPM}"
    fi

    while read -r p; do
        set -- $p
        PROJECT=${1}

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
        sudo dnf builddep -y ${PROJECT}.spec &> /dev/null
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
        cp "${BASE_PATH}/${PROJECT}/po/${LANG_CODE}.po" "${SRC#*/}p/po/" &> /dev/null
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        cd "${SRC#*/}p/po"
        intltool-update --pot
        intltool-update --dist ${LANG_CODE}
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
        rpm -i --replacepkgs --replacefiles */*.rpm &> /dev/null
        if [ $? -ne 0 ]; then
            echo "${RED}[ FAIL ]${NC}"
            continue
        else
            echo "${GREEN}[ OK ]${NC}"
        fi

        let "COUNTER++"
    done <${LIST}
}

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
    --disable-wordlist)
    DISABLE_WORDLIST="YES"
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
if [ -z "${GENERATE_REPORT}" ] && [ -n "${DISABLE_WORDLIST}" ]; then
    usage
    exit 1
fi

### Main
if [ -n "$GENERATE_REPORT" ]; then
    report
fi
if [ -n "$INSTALL_TRANS" ]; then
    # ensure running as root
    if [ "$(id -u)" != "0" ]; then
      cd "${WORK_PATH}"
      exec sudo "$0" "-l=${LANG_CODE}" "-i"
      exit 0
    else
      install
    fi
fi
echo "complete!"
