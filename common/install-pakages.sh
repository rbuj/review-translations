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
function install-pakages {
    if [ $# -lt 1 ]; then
        echo "Missing argument";
        return 1;
    fi

    for f in "$@"; do
        rpm -q $f &> /dev/null
        if [ $? -ne 0 ]; then
            echo "download : installing required packages"
            local VERSION_AUX=( $(cat /etc/fedora-release) )
            if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y $f --nogpgcheck; else sudo dnf install -y $f; fi
        fi
    done
}
