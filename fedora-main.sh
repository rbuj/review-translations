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

function usage {
    echo $"usage"" : $0 [-l|--lang]=LANG_CODE"
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

### Main ###
./zanata-fedora.sh -l=${LANG_CODE} -p=fedora-main -f=fedora-main.list
echo "complete!"
