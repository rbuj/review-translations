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

PROJECT="exaile"
WORK_PATH=$PWD
BASE_PATH=${WORK_PATH}/${PROJECT}
BASE_PATH_RPM=${BASE_PATH}/rpm

LANG_CODE=
GENERATE_REPORT=
DISABLE_WORDLIST=
INSTALL_TRANS=
VERSION=$(${WORK_PATH}/common/fedora-version.sh)

function usage {
    echo "This script downloads the translation of the ${PROJECT} package"
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

function get_code {
    download_code ${PROJECT} https://github.com/exaile/exaile.git
}

function download {
    get_code
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

    HTML_REPORT=${WORK_PATH}/${PROJECT}-report.html
    cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html lang="${LANG_CODE}" xml:lang="${LANG_CODE}" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Translation Report</title>
  </head>
<body bgcolor="#080808" text="#D0D0D0">
EOF

    echo "************************************************"
    echo "* checking translation..."
    echo "************************************************"
    posieve check-rules,check-spell-ec,check-grammar,stats -s lang:${LANG_CODE} -s showfmsg -s byrule --msgfmt-check --skip-obsolete --coloring-type=html ${BASE_PATH}/${PROJECT}/po/${LANG_CODE}.po >> ${HTML_REPORT}

    cat << EOF >> ${HTML_REPORT}
</body>
</html>
EOF

    chmod 644 ${HTML_REPORT}
    kill -9 ${LANGUAGETOOL_PID} > /dev/null
}

function install {
    echo "installing translation"

    if [ ! -d "${BASE_PATH_RPM}" ]; then
        mkdir -p "${BASE_PATH_RPM}"
    fi

    if [ -d "${BASE_PATH_RPM}/${PROJECT}" ]; then
        rm -fr "${BASE_PATH_RPM}/${PROJECT}"
    fi

    cd "${BASE_PATH_RPM}"
    echo -ne "${PROJECT}: fedpkg clone "
    fedpkg clone -a -B ${PROJECT} &> /dev/null
    if [ $? -ne 0 ]; then
        echo "${RED}[ FAIL ]${NC}"
        return 1
    else
        echo "${GREEN}[ OK ]${NC}"
    fi

    cd "${BASE_PATH_RPM}/${PROJECT}/${VERSION}"
    echo -ne "${PROJECT}: dnf builddep "
    sudo dnf builddep -y ${PROJECT}.spec &> /dev/null
    if [ $? -ne 0 ]; then
        echo "${RED}[ FAIL ]${NC}"
        return 1
    else
        echo "${GREEN}[ OK ]${NC}"
    fi

    echo -ne "${PROJECT}: fedpkg prep "
    fedpkg prep &> /dev/null
    if [ $? -ne 0 ]; then
        echo "${RED}[ FAIL ]${NC}"
        return 1
    else
        echo "${GREEN}[ OK ]${NC}"
    fi

    echo -ne "${PROJECT}: path "
    SRC=$(find . -maxdepth 1 -mindepth 1 -type d ! -name ".*")
    if [ $? -ne 0 ]; then
        echo "${RED}[ FAIL ]${NC}"
        return 1
    else
        echo "${GREEN}[ OK ]${NC}"
    fi

    echo -ne "${PROJECT}: copy folder "
    cp -rp ${SRC#*/} ${SRC#*/}p &> /dev/null
    if [ $? -ne 0 ]; then
        echo "${RED}[ FAIL ]${NC}"
        return 1
    else
        echo "${GREEN}[ OK ]${NC}"
    fi

    echo -ne "${PROJECT}: copy trans "
    cp "${BASE_PATH}/${PROJECT}/po/${LANG_CODE}.po" "${SRC#*/}p/po/" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "${RED}[ FAIL ]${NC}"
        return 1
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
        return 1
    fi

    sed -i '1 i Patch9999: my.patch' ${PROJECT}.spec
    if [ $? -ne 0 ]; then
        echo "${RED}[ FAIL ]${NC}"
        return 1
    else
        echo "${GREEN}[ OK ]${NC}"
    fi

    echo -ne "${PROJECT}: fedpkg local "
    fedpkg local &> /dev/null
    if [ $? -ne 0 ]; then
        echo "${RED}[ FAIL ]${NC}"
        return 1
    else
        echo "${GREEN}[ OK ]${NC}"
    fi

    echo -ne "${PROJECT}: rpm -i "
    rpm -i --replacepkgs --replacefiles */*.rpm &> /dev/null
    if [ $? -ne 0 ]; then
        echo "${RED}[ FAIL ]${NC}"
        return 1
    else
        echo "${GREEN}[ OK ]${NC}"
    fi
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
if [ ! -d "${BASE_PATH}" ]; then
    mkdir -p "${BASE_PATH}"
fi
if [ -n "$GENERATE_REPORT" ]; then
    download
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
