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
LANG_CODE=
GENERATE_REPORT=
DISABLE_WORDLIST=
INSTALL_TRANS=

function usage {
    echo "This script downloads the translations of the projects that belongs to main group [1]."
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   --disable-wordlist    Do not use wordlist file (requires -r)"
    echo "   -i, --install         Install translations"
    echo "   -h, --help            Display this help and exit"
    echo ""
    echo -ne "[1] https://fedora.zanata.org/version-group/view/main\n"
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

if [ -z ${LANG_CODE} ]; then
    usage
    exit 1
fi

if [ -z ${GENERATE_REPORT} ] && [ -n ${DISABLE_WORDLIST} ]; then
    usage
    exit 1
fi

### Main ###
GROUP="main"
./zanata-fedora.sh -l=${LANG_CODE} -p=fedora-${GROUP} -f=fedora-${GROUP}.list
if [ -n "$GENERATE_REPORT" ]; then
    if [ -z ${DISABLE_WORDLIST} ]; then
        if [ -z ${LT_SERVER} ] && [ -z ${LT_PORT} ]; then
            ./report-${GROUP}.sh -l=${LANG_CODE} -p=fedora-${GROUP} -f=fedora-${GROUP}.list
        else
            ./report-${GROUP}.sh -l=${LANG_CODE} -p=fedora-${GROUP} -f=fedora-${GROUP}.list --languagetool-server=${LT_SERVER} --languagetool-port=${LT_PORT}
        fi
    else
        if [ -z ${LT_SERVER} ] && [ -z ${LT_PORT} ]; then
            ./report-fedora.sh -l=${LANG_CODE} -p=fedora-${GROUP} -f=fedora-${GROUP}.list --disable-wordlist
        else
            ./report-fedora.sh -l=${LANG_CODE} -p=fedora-${GROUP} -f=fedora-${GROUP}.list --disable-wordlist --languagetool-server=${LT_SERVER} --languagetool-port=${LT_PORT}
        fi
    fi
fi
if [ -n "$INSTALL_TRANS" ]; then
    echo "Installing translations"
    sudo ./install-fedora.sh -l=${LANG_CODE} -p=fedora-${GROUP} -f=fedora-${GROUP}.list
fi
echo "complete!"
