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

DIRECTORI_TREBALL=$PWD
DIRECTORI_BASE=${DIRECTORI_TREBALL}

function update_src {
    cd ${DIRECTORI_BASE}
    if [ ! -d $1 ]; then
        echo -ne "Es clona el codi font "
        git clone $2 $1 &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    else
        cd $1
        echo -ne "S'actualitza el codi font "
        git pull &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
        cd ..
    fi
}

function obte_codi {
    update_src dnf https://github.com/rpm-software-management/dnf.git
}

function obte_traduccio {
    echo -ne "S'obté la traducció"
    cd ${DIRECTORI_BASE}/dnf/po
    zanata-cli -B pull -l ca &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
}

function compila_codi {
    echo "Es compila el codi"
    cd ${DIRECTORI_BASE}/dnf
    dnf builddep dnf.spec -y &> /dev/null
    if [ ! -d "${DIRECTORI_BASE}/dnf/build" ]; then
        mkdir build
    fi
    pushd build;
    cmake .. && make;
    popd;
}

function test {
    obte_codi
    obte_traduccio
    compila_codi
}

function revisio {
if [ ! -d "${DIRECTORI_TREBALL}/languagetool" ]; then
    cd ${DIRECTORI_TREBALL}
    git clone https://github.com/languagetool-org/languagetool.git
    cd languagetool
    ./build.sh languagetool-standalone clean package -DskipTests
fi

cd ${DIRECTORI_TREBALL}
LANGUAGETOOL=`find . -name 'languagetool-server.jar'`
java -cp $LANGUAGETOOL org.languagetool.server.HTTPServer --port 8081 > /dev/null &
LANGUAGETOOL_PID=$!

echo -ne "Revisió: S'espera que s'hagi iniciat el servidor web del langtool"
until $(curl --output /dev/null --silent --data "language=ca&text=Hola món!" --fail http://localhost:8081); do
    printf '.'
    sleep 1
done
if [ $? -ne 0 ]; then
    echo " ${RED}[ FAIL ]${NC}"
else
    echo " ${GREEN}[ OK ]${NC}"
fi

if [ ! -d ${DIRECTORI_TREBALL}/pology ]; then
    cd ${DIRECTORI_TREBALL}
    svn checkout svn://anonsvn.kde.org/home/kde/trunk/l10n-support/pology
    cd pology
    mkdir build && cd build
    cmake ..
    make
fi

export PYTHONPATH=${DIRECTORI_TREBALL}/pology:$PYTHONPATH
export PATH=${DIRECTORI_TREBALL}/pology/bin:$PATH

cat << EOF > ${DIRECTORI_TREBALL}/dnf-informe.html
<!DOCTYPE html>
<html lang="ca" xml:lang="ca" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Memòries de traducció lliures al català</title>
  </head>
<body bgcolor="#080808" text="#D0D0D0">
EOF

echo "Revisió: S'analitzen les traduccions"
posieve check-rules,check-spell-ec,check-grammar,stats -s lang:ca -s showfmsg -s byrule --msgfmt-check --skip-obsolete --coloring-type=html ${DIRECTORI_BASE}/dnf/po/ca.po >> ${DIRECTORI_TREBALL}/dnf-informe.html

cat << EOF >> ${DIRECTORI_TREBALL}/dnf-informe.html
</body>
</html>
EOF

kill -9 $LANGUAGETOOL_PID > /dev/null
}


# ensure running as root
if [ "$(id -u)" != "0" ]; then
  exec sudo "$0" "$@" 
  exit 0
fi

echo -ne "S'instal·len les eines necessaries "
dnf install -y svn maven python-enchant &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"

### Principal ###
test
revisio
echo "S'ha finalitzat!"
