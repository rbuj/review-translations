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

function usage {
    echo "This script builds LanguageTool in the specified path if there is no languagetool folder."
    echo "usage : $0 --path=PATH"
    echo "   --path=PATH           PATH  to look for"
    echo "   -h, --help            Display this help and exit"
}

function build_languagtool {
    rpm -q maven &> /dev/null
    if [ $? -ne 0 ]; then
        echo "languagtool : installing required packages"
        set -x
        sudo dnf install -y maven
        set -
    fi
    echo "languagtool : building"
    cd ${WORK_PATH}
    git clone https://github.com/languagetool-org/languagetool.git
    cd languagetool
    ./build.sh languagetool-standalone clean package -DskipTests
}

for i in "$@"
do
case $i in
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
