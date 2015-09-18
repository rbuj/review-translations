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
BASE_PATH=${WORK_PATH}/fedora-web

LANG_CODE=

function usage {
    echo $"usage"" : $0 [-l|--lang]=LANG_CODE"
}

function get_trans {
    echo -ne "downloading : "${1}" "${2}
    if [ ! -d "${BASE_PATH}/${1}-${2}" ]; then
        mkdir -p ${BASE_PATH}/${1}-${2}
    fi
    FITXER=${BASE_PATH}/${1}-${2}/zanata.xml
    if [ ! -f "${FITXER}" ]; then
        cat << EOF > ${FITXER}
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://zanata.org/namespace/config/">
  <url>https://fedora.zanata.org/</url>
  <project>${1}</project>
  <project-version>${2}</project-version>
  <project-type>gettext</project-type>

</config>
EOF
    fi
    cd ${BASE_PATH}/${1}-${2}
    zanata-cli -B pull -l ${LANG_CODE} > /dev/null && echo "${GREEN}[ OK ]${NC}" || exit 1
}

function test {
    while read -r p; do
        set -- $p
        get_trans $1 $2
    done <fedora-web.list
}

function report {
if [ ! -d "${WORK_PATH}/languagetool" ]; then
    cd ${WORK_PATH}
    git clone https://github.com/languagetool-org/languagetool.git
    cd languagetool
    ./build.sh languagetool-standalone clean package -DskipTests
fi

cd ${WORK_PATH}
LANGUAGETOOL=`find . -name 'languagetool-server.jar'`
java -cp $LANGUAGETOOL org.languagetool.server.HTTPServer --port 8081 > /dev/null &
LANGUAGETOOL_PID=$!

echo -ne "ckecking: wait for langtool"
until $(curl --output /dev/null --silent --data "language=ca&text=Hola món!" --fail http://localhost:8081); do
    printf '.'
    sleep 1
done
if [ $? -ne 0 ]; then
    echo " ${RED}[ FAIL ]${NC}"
else
    echo " ${GREEN}[ OK ]${NC}"
fi

if [ ! -d ${WORK_PATH}/pology ]; then
    cd ${WORK_PATH}
    svn checkout svn://anonsvn.kde.org/home/kde/trunk/l10n-support/pology
    cd pology
    mkdir build && cd build
    cmake ..
    make
fi

export PYTHONPATH=${WORK_PATH}/pology:$PYTHONPATH
export PATH=${WORK_PATH}/pology/bin:$PATH

HTML_REPORT=${WORK_PATH}/fedora-web-report.html
cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html lang="${LANG_CODE}" xml:lang="${LANG_CODE}" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Report</title>
  </head>
<body bgcolor="#080808" text="#D0D0D0">
EOF

echo "checking: check translations"
posieve check-rules,check-spell-ec,check-grammar,stats -s lang:${LANG_CODE} -s showfmsg -s byrule --msgfmt-check --skip-obsolete --coloring-type=html ${BASE_PATH}/ >> ${HTML_REPORT}

cat << EOF >> ${HTML_REPORT}
</body>
</html>
EOF

kill -9 $LANGUAGETOOL_PID > /dev/null
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

for i in "$@"
do
case $i in
    -l=*|--lang=*)
    LANG_CODE="${i#*=}"
    shift # past argument=value
    ;;
    *)
    usage
    exit 1
    ;;
esac
done

rpm -q subversion maven python-enchant zanata-client &> /dev/null
if [ $? -ne 0 ]; then
    echo "installing : required packages"
    sudo dnf install -y subversion maven python-enchant zanata-client &> /dev/null && echo "${GREEN}[ OK ]${NC}" || exit 1
fi

### Principal ###
test
report
echo "complete!"
