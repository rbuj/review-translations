#!/bin/bash
# ---------------------------------------------------------------------------
# Copyright 2017, Robert Buj <rbuj@fedoraproject.org>
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
if [ ! -f "${WORK_PATH}/snippet/jquery-${JQUERY_VERSION}.slim.min.js" ]; then
    wget -O ${WORK_PATH}/snippet/jquery-${JQUERY_VERSION}.slim.min.js https://code.jquery.com/jquery-${JQUERY_VERSION}.slim.min.js
fi
