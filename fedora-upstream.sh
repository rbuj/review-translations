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
GROUP=$(basename ${0} .sh)
WORK_PATH=$PWD
LIST="${WORK_PATH}/list/${GROUP}.list"

LANG_CODE=
GENERATE_REPORT=
DISABLE_WORDLIST=
INSTALL_TRANS=

LT_SERVER=
LT_PORT=

function usage {
    echo "This script downloads the translations of the projects that belongs to upstream group [1]."
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   --disable-wordlist    Do not use wordlist file (requires -r)"
    echo "   -i, --install         Install translations"
    echo "   -h, --help            Display this help and exit"
    echo ""
    echo -ne "[1] https://fedora.zanata.org/version-group/view/upstream\n"
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
    --languagetool-server=*)
    LT_SERVER="${i#*=}"
    shift # past argument=value
    ;;
    --languagetool-port=*)
    LT_PORT="${i#*=}"
    shift # past argument=value
    ;;
    -i|--install)
    INSTALL_TRANS="YES"
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

### Main ###
./common/zanata.sh -l=${LANG_CODE} -p=${GROUP} -f=${LIST} -u=https://fedora.zanata.org/ -w=${WORK_PATH}
if [ -n "$GENERATE_REPORT" ]; then
    if [ -z "${DISABLE_WORDLIST}" ]; then
        if [ -z "${LT_SERVER}" ] && [ -z "${LT_PORT}" ]; then
            ./common/report.sh -l=${LANG_CODE} -p=${GROUP} -f=${LIST} -w=${WORK_PATH}
        else
            ./common/report.sh -l=${LANG_CODE} -p=${GROUP} -f=${LIST} --languagetool-server=${LT_SERVER} --languagetool-port=${LT_PORT} -w=${WORK_PATH}
        fi
    else
        if [ -z "${LT_SERVER}" ] && [ -z "${LT_PORT}" ]; then
            ./common/report.sh -l=${LANG_CODE} -p=${GROUP} -f=${LIST} --disable-wordlist -w=${WORK_PATH}
        else
            ./common/report.sh -l=${LANG_CODE} -p=${GROUP} -f=${LIST} --disable-wordlist --languagetool-server=${LT_SERVER} --languagetool-port=${LT_PORT} -w=${WORK_PATH}
        fi
    fi
fi
if [ -n "$INSTALL_TRANS" ]; then
    ./common/install.sh -l=${LANG_CODE} -p=${GROUP} -f=${LIST} -w=${WORK_PATH}
fi
echo "complete!"
