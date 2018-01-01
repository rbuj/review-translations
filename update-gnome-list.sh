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
URL_LIST=( https://l10n.gnome.org/languages/en_US/gnome-3-28/ui.tar.gz http://l10n.gnome.org/languages/en_US/gnome-extras/ui.tar.gz )
for URL in ${URL_LIST[@]}; do
  for PACKAGE in $(LC_ALL=en_US.UTF-8 wget -qO- $URL | tar tvz | grep -oE '[^ ]+$' | cut -d'.' -f1); do
    echo "$PACKAGE"
    echo "  + checking sources file..."
    wget -qO/dev/null  https://src.fedoraproject.org/cgit/rpms/$PACKAGE.git/plain/sources
    if [ $? -ne 0 ]; then
      echo "  + couldn't find sources file. skipping."
    else
      echo "  + adding the package into list/gnome.list..."
      echo "$PACKAGE git://git.gnome.org/$PACKAGE" >> list/gnome.list
      sort -u -o list/gnome.list list/gnome.list
    fi
  done
done
