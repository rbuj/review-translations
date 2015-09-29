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

function usage {
    echo "This script downloads the translations of the blivet-gui project."
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   --disable-wordlist    Do not use wordlist file (requires -r)"
    echo "   -h, --help            Display this help and exit"
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
./zanata.sh -l=${LANG_CODE} -p=blivet-gui -f=blivet-gui.list -u=https://translate.zanata.org/zanata/
if [ -n "$GENERATE_REPORT" ]; then
    if [ -z "${DISABLE_WORDLIST}" ]; then
        ./report-fedora.sh -l=${LANG_CODE} -p=blivet-gui -f=blivet-gui.list
    else
        ./report-fedora.sh -l=${LANG_CODE} -p=blivet-gui -f=blivet-gui.list --disable-wordlist
    fi
fi
echo "complete!"
