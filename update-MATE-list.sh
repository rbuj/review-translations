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
for i in {1..2}; do
  for PACKAGE in $(curl -s "https://api.github.com/orgs/mate-desktop/repos?page=$i" | jq '.[] | {name}' | xargs -L3 | perl -pe 's/^\{ name\: (.*) \}$/\1/g'); do
    echo "$PACKAGE"
    echo "  + checking sources file..."
    wget -qO/dev/null  https://src.fedoraproject.org/cgit/rpms/$PACKAGE.git/plain/sources
    if [ $? -ne 0 ]; then
      echo "  + couldn't find sources file. skipping."
    else
      echo "  + adding the package into list/MATE.list..."
      echo "$PACKAGE MATE $PACKAGE" >> list/MATE.list
      sort -u -o list/MATE.list list/MATE.list
    fi
  done
done
