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
LC_ALL=en_US.UTF-8 wget -qO- https://l10n.gnome.org/languages/en_US/gnome-3-24/ui.tar.gz | tar tvz | grep -oE '[^ ]+$' | cut -d'.' -f1 | awk '{print $1" git://git.gnome.org/"$1}' > list/gnome.list
LC_ALL=en_US.UTF-8 wget -qO- http://l10n.gnome.org/languages/en_US/gnome-extras/ui.tar.gz | tar tvz | grep -oE '[^ ]+$' | cut -d'.' -f1 | awk '{print $1" git://git.gnome.org/"$1}' >> list/gnome.list
sort list/gnome.list -o list/gnome.list
