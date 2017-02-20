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
WORK_PATH=
LANG_CODE=

function usage {
    echo "This script builds LanguageTool in the specified path if there is no languagetool folder."
    echo "usage : $0 --path=PATH  -l|--lang=LANG_CODE"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo "   --path=PATH           PATH  to look for"
    echo "   -h, --help            Display this help and exit"
}

function build_languagtool {
    #########################################
    # REQUIRED PACKAGES
    #########################################
    for REQUIRED_PACKAGE in java-1.8.0-openjdk java-1.8.0-openjdk-devel perl-Locale-Codes maven; do
        rpm -q $REQUIRED_PACKAGE &> /dev/null
        if [ $? -ne 0 ]; then
            echo "report : installing required package : $REQUIRED_PACKAGE"
            VERSION_AUX=( $(cat /etc/fedora-release) )
            set -x
            if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y $REQUIRED_PACKAGE --nogpgcheck; else sudo dnf install -y $REQUIRED_PACKAGE; fi
            set -
        fi
    done

    echo "languagtool : building"
    cd ${WORK_PATH}
    git clone https://github.com/languagetool-org/languagetool.git
    # use version 3.5
    # https://github.com/languagetool-org/languagetool/commit/4b0f03f6122a99ec5a7da132286015d13c911a21
    # The old API has been deactivated, as documented at https://languagetool.org/http-api/migration.php - it now returns a pseudo error pointing to the migration page
    cd ${WORK_PATH}/languagetool
    git checkout c2f5ac8c245f3cc41f328e66b5d145955f11c4c8
    cd ${WORK_PATH}

    # remove MORFOLOGIK_RULE
    for LOCALE  in be br ca de el es ml nl pl ro ru sl uk; do
        case $LOCALE in
            de)
                for LANGUAGE in AustrianGerman GermanyGerman SwissGerman; do
                    sed -i "/GermanSpellerRule/d" languagetool/languagetool-language-modules/$LOCALE/src/main/java/org/languagetool/language/$LANGUAGE.java
                done
            ;;
            el)
                local LANGUAGE=Greek
                sed -i "/Morfologik"$LANGUAGE"SpellerRule/d" languagetool/languagetool-language-modules/$LOCALE/src/main/java/org/languagetool/language/$LANGUAGE.java
            ;;
            *)
                local LANGUAGE=$(perl -e "use Locale::Language; print (code2language('$LOCALE'));")
                sed -i "/Morfologik"$LANGUAGE"SpellerRule/d" languagetool/languagetool-language-modules/$LOCALE/src/main/java/org/languagetool/language/$LANGUAGE.java
            ;;
	esac
    done

    # Polish: disable BRAK_KROPKI rule
    sed -i -e "s/<rulegroup id=\"BRAK_KROPKI\"/<rulegroup id=\"BRAK_KROPKI\" default=\"off\"/g" languagetool/languagetool-language-modules/pl/src/main/resources/org/languagetool/rules/pl/grammar.xml
#    sed -i -e "/\([ tab]*\)<rulegroup id=\"BRAK_KROPKI\" name=\"Brak kropki na końcu zdania\">/!b;n;c<rule default=\"off\">" languagetool/languagetool-language-modules/pl/src/main/resources/org/languagetool/rules/pl/grammar.xml

    cd languagetool
    ./build.sh languagetool-standalone clean package -DskipTests
}

for i in "$@"
do
case $i in
    -l=*|--lang=*)
    LANG_CODE="${i#*=}"
    shift # past argument=value
    ;;
    --path=*)
    WORK_PATH="${i#*=}"
    shift # past argument=value
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

if [ -z "${WORK_PATH}" ]; then
    usage
    exit 1
fi

if [ ! -d "${WORK_PATH}/languagetool" ]; then
    build_languagtool
fi
