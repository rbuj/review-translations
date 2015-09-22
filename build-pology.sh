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
    echo "This script builds Pology in the specified path if there is no pology folder."
    echo "usage : $0 -l|--lang=LANG_CODE"
    echo "   --path=PATH           PATH  to look for"
    echo "   -h, --help            Display this help and exit"
}

function build_pology {
    rpm -q cmake subversion python-enchant enchant-aspell &> /dev/null
    if [ $? -ne 0 ]; then
        echo "pology : installing required packages"
        set -x
        sudo dnf install -y cmake subversion python-enchant enchant-aspell
        set -
    fi
    echo "pology : building"
    cd ${WORK_PATH}
    svn checkout svn://anonsvn.kde.org/home/kde/trunk/l10n-support/pology
    cd pology
    mkdir build && cd build
    cmake ..
    make
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

if [ ! -d "${WORK_PATH}/pology" ]; then
    build_pology
fi
