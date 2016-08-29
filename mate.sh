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

PROJECT_NAME=mate
WORK_PATH=$PWD
LIST=${WORK_PATH}/list/${PROJECT_NAME}.list

LANG_CODE=
GENERATE_REPORT=
DISABLE_WORDLIST=
INSTALL_TRANS=

function usage {
    echo "This script downloads the translation of ${PROJECT_NAME}"
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
    if [ "$DISABLE_WORDLIST" == "YES" ]; then
        ./common/transifex-translations.sh -r -l=${LANG_CODE} --disable-wordlist -p=${PROJECT_NAME} -f=${LIST} -w=${WORK_PATH}
    else
        ./common/transifex-translations.sh -r -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${LIST} -w=${WORK_PATH}
    fi
fi
if [ -n "$INSTALL_TRANS" ]; then
    ./common/transifex-translations.sh -i -l=${LANG_CODE} -p=${PROJECT_NAME} -f=${LIST} -w=${WORK_PATH}
fi
echo "complete!"
