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
BASE_PATH=${WORK_PATH}
LANG_CODE=

function usage {
    echo $"usage"" : $0 [-l|--lang]=LANG_CODE"
}

function update_src {
    cd ${BASE_PATH}
    if [ ! -d $1 ]; then
        echo -ne "downloading : source code - git clone "
        git clone $2 $1 &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    else
        cd $1
        echo -ne "downloading : source code - git pull "
        git pull &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    fi
}

function get_code {
    update_src dnf https://github.com/rpm-software-management/dnf.git
}

function get_trans {
    echo -ne "downloading : translation "
    cd ${BASE_PATH}/dnf/po
    zanata-cli -B pull -l ${LANG_CODE} > /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
}

function build_src {
    cd ${BASE_PATH}/dnf
    echo "installing builddeps..."
    sudo dnf builddep dnf.spec -y &> /dev/null
    if [ ! -d "${BASE_PATH}/dnf/build" ]; then
        mkdir build
    fi
    pushd build;
    cmake .. && make;
    popd;
}

function test {
    get_code
    get_trans
    build_src
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

echo -ne "wait for langtool"
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

HTML_REPORT=${WORK_PATH}/dnf-report.html
cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html lang="${LANG_CODE}" xml:lang="${LANG_CODE}" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Translation Report</title>
  </head>
<body bgcolor="#080808" text="#D0D0D0">
EOF

echo "checking : running posieve"
posieve check-rules,check-spell-ec,check-grammar,stats -s lang:${LANG_CODE} -s showfmsg -s byrule --msgfmt-check --skip-obsolete --coloring-type=html ${BASE_PATH}/dnf/po/${LANG_CODE}.po >> ${HTML_REPORT}

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

### Main ###
test
report
echo "complete!"
echo "Test your translation with:"
echo ""
echo "    PYTHONPATH=\`readlink -f dnf\` dnf/bin/dnf-3 ARGS" 
echo ""
