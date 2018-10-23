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
VERSION="master"
if [ -f "/etc/fedora-release" ]; then
    VERSION_AUX=`cat /etc/fedora-release`
    case ${VERSION_AUX} in
        "Fedora release 27 (Twenty Seven)")
        VERSION="f27"
        ;;
	"Fedora release 28 (Twenty Eight)")
        VERSION="f28"
        ;;
        "Fedora release 29 (Twenty Nine")
        VERSION="f29"
        ;;
    esac
fi
echo "${VERSION}"
