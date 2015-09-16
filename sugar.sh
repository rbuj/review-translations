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

CODI=(abacus analyzejournal calculate chat deducto erikos finance followmebutia fototoon fractionbounce get-books get-internet-archive-books imageviewer infoslicer jukebox log maze measure memorize paint paths physics pippy ruler read readetexts read-sd-comics record speak terminal turtleart turtleart-extras typing-turtle viewslides visualmatch browse words-activity write)
TRADUCCIO=(Abacus AnalyzeJournal Calculate Chat Deducto Erikos Finance FollowMeButia FotoToon FractionBounce GetBooks GetIABooks ImageViewer InfoSlicer Jukebox Log Maze Measure Memorize Paint Paths Physics Pippy Ruler Read ReadETexts ReadSDComics Record Speak Terminal TurtleArt TurtleArtExtras TypingTurtle ViewSlides Dimensions Web Words Write)
PACKAGE_SUFFIX=(abacus analyze calculator chat deducto no finance no fototoon fractionbounce no getiabooks imageviewer infoslicer jukebox log maze measure memorize paint no physics pippy ruler read no no record speak terminal turtleart no typing-turtle view-slides visualmatch browse words write)

DIRECTORI_TREBALL=$PWD
DIRECTORI_BASE=${DIRECTORI_TREBALL}/sugar

function update_src {
    cd ${DIRECTORI_BASE}
    if [ ! -d $1 ]; then
        echo -ne "$1: Es clona el codi font "
        git clone $2 $1 &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    else
        cd $1
        echo -ne "$1: S'actualitza el codi font "
        git pull &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
        cd ..
    fi
}

function install_rpm {
    echo -ne ${CODI[$1]}" : S'insta·len les dependències del paquet "
    if [ "x${PACKAGE_SUFFIX[$1]}" == "xno" ]; then
        echo "${RED}[ NO DISP ]${NC}"
    else
        echo -ne sugar-${PACKAGE_SUFFIX[$1]}" "
        dnf builddep -y sugar-${PACKAGE_SUFFIX[$1]} &> /dev/null && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
    fi
}

function obte_codi {
    update_src ${CODI[$1]} git://git.sugarlabs.org/${CODI[$1]}/mainline.git
}

function obte_traduccio {
    echo -ne ${CODI[$1]}" : S'obté la traducció"
    curl -s -S http://translate.sugarlabs.org/export/${TRADUCCIO[$1]}/ca.po > ${DIRECTORI_BASE}/${CODI[$1]}/po/ca.po && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
}

function compila_codi {
    echo -ne ${CODI[$1]}" : Es compila el codi"
    cd ${DIRECTORI_BASE}/${CODI[$1]}
    python setup.py build &> /dev/null && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
}

function installa_codi {
    echo -ne ${CODI[$1]}" : S'instal·la el codi"
    cd ${DIRECTORI_BASE}/${CODI[$1]}
    python setup.py install &> /dev/null && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
    cd $DIRECTORI_TREBALL
}

function prepara_revisio {
    echo -ne ${CODI[$1]}" : Es prepara la revisió"
    if [ ! -d "${DIRECTORI_BASE}/sugar/${CODI[$1]}" ]; then
        mkdir -p "${DIRECTORI_BASE}/sugar/${CODI[$1]}"
    fi
    cat ${DIRECTORI_BASE}/${CODI[$1]}/po/ca.po | perl -pe "s/(#:\s(.)*:(\d)*)/\${1}\n#, python-format/g" > ${DIRECTORI_BASE}/sugar/${CODI[$1]}/ca.po && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
}

function test {
rm -fr sugar
for PROJECTE in sugar sugar-toolkit-gtk3; do
    echo -ne ${PROJECTE}": es crea el mo "
    curl -s -S http://translate.sugarlabs.org/export/$PROJECTE/ca.po > ${DIRECTORI_BASE}/$PROJECTE.po
    msgfmt ${DIRECTORI_BASE}/${PROJECTE}.po -o /usr/share/locale/ca/LC_MESSAGES/${PROJECTE}.mo && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
    if [ ! -d "${DIRECTORI_BASE}/sugar/${PROJECTE}" ]; then
        mkdir -p "${DIRECTORI_BASE}/sugar/${PROJECTE}"
    fi
    echo -ne ${PROJECTE}": es prepara per a la revisió"
    cat ${DIRECTORI_BASE}/${PROJECTE}.po | perl -pe "s/(#:\s(.)*:(\d)*)/\${1}\n#, python-format/g" > ${DIRECTORI_BASE}/sugar/${PROJECTE}/ca.po && echo " ${GREEN}[ OK ]${NC}" || echo " ${RED}[ FAIL ]${NC}"
done

for (( i=0; i<${#CODI[@]}; i++ )); do
    install_rpm $i
    obte_codi $i
    obte_traduccio $i
    compila_codi $i
    installa_codi $i
    prepara_revisio $i
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

cat << EOF > ${DIRECTORI_TREBALL}/sugar-informe.html
<!DOCTYPE html>
<html lang="ca" xml:lang="ca" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Memòries de traducció lliures al català</title>
  </head>
<body>
EOF

echo "Revisió: S'analitzen les traduccions"
posieve check-rules,check-spell-ec,check-grammar,stats -s lang:ca -s showfmsg -s byrule -s list --msgfmt-check --skip-obsolete --coloring-type=html ${DIRECTORI_BASE}/sugar/ >> ${DIRECTORI_TREBALL}/sugar-informe.html

cat << EOF >> ${DIRECTORI_TREBALL}/sugar-informe.html
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

if [ ! -d ${DIRECTORI_BASE} ]; then
    mkdir ${DIRECTORI_BASE}
fi

update_src fractionbounce git://git.sugarlabs.org/fractionboounce/fractionbounce.git
update_src words-activity git://git.sugarlabs.org/words-activity/words-activity.git
update_src deducto git://git.sugarlabs.org/deducto/deducto.git
update_src analyzejournal git://git.sugarlabs.org/analyzejournal/analyzejournal.git
update_src turtleart-extras git://git.sugarlabs.org/turtleart-extras/turtleart-extras.git

### Principal ###
test
revisio
echo "S'ha finalitzat!"
