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
PROJECT_NAME=$(basename ${0} .sh)
WORK_PATH=$PWD
LIST=${WORK_PATH}/list/${PROJECT_NAME}.list

./common/translations.sh -p=${PROJECT_NAME} -f=${LIST} -w=${WORK_PATH} -t="transifex" $@

