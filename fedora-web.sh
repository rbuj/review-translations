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
DIRECTORI_BASE=${DIRECTORI_TREBALL}/fedora-web

TRADUCCIO=(fedorahosted.org boot.fedoraproject.org fedoracommunity.org start.fedoraproject.org spins.fedoraproject.org getfedora.org labs.fedoraproject.org arm.fedoraproject.org)

function obte_traduccio {
    echo -ne "S'obté la traducció "${TRADUCCIO[$1]}" "
    if [ ! -d "${DIRECTORI_BASE}/${TRADUCCIO[$1]}" ]; then
        mkdir -p ${DIRECTORI_BASE}/${TRADUCCIO[$1]}
    fi
    FITXER=${DIRECTORI_BASE}/${TRADUCCIO[$1]}/zanata.xml
    if [ ! -f "${FITXER}" ]; then
        cat << EOF > ${FITXER}
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://zanata.org/namespace/config/">
  <url>https://fedora.zanata.org/</url>
  <project>fedora-web</project>
  <project-version>${TRADUCCIO[$1]}</project-version>
  <project-type>gettext</project-type>

</config>
EOF
    fi
    cd ${DIRECTORI_BASE}/${TRADUCCIO[$1]}
    zanata-cli -B pull -l ca &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
}

function test {
    for (( i=0; i<${#TRADUCCIO[@]}; i++ )); do
        obte_traduccio $i
    done
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

cat << EOF > ${DIRECTORI_TREBALL}/fedora-web-informe.html
<!DOCTYPE html>
<html lang="ca" xml:lang="ca" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Memòries de traducció lliures al català</title>
  </head>
<body bgcolor="#080808" text="#D0D0D0">
EOF

echo "Revisió: S'analitzen les traduccions"
posieve check-rules,check-spell-ec,check-grammar,stats -s lang:ca -s showfmsg -s byrule --msgfmt-check --skip-obsolete --coloring-type=html ${DIRECTORI_BASE}/ >> ${DIRECTORI_TREBALL}/fedora-web-informe.html

cat << EOF >> ${DIRECTORI_TREBALL}/fedora-web-informe.html
</body>
</html>
EOF

kill -9 $LANGUAGETOOL_PID > /dev/null
}

rpm -q subversion maven python-enchant &> /dev/null
if [ $? -ne 0 ]; then
    echo "installing : required packages"
    sudo dnf install -y subversion maven python-enchant &> /dev/null && echo "${GREEN}[ OK ]${NC}" || exit 1
fi

### Principal ###
test
revisio
echo "S'ha finalitzat!"
