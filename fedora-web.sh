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

function usage {
    echo "This script downloads the translations of the projects that belongs to web group [1]."
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   -h, --help            Display this help and exit"
    echo ""
    echo -ne "[1] https://fedora.zanata.org/version-group/view/web\n"
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

### Main ###
if [ -n "$GENERATE_REPORT" ]; then
    ./zanata-fedora.sh -l=${LANG_CODE} -p=fedora-web -f=fedora-web.list -r
else
    ./zanata-fedora.sh -l=${LANG_CODE} -p=fedora-web -f=fedora-web.list
fi
echo "complete!"
