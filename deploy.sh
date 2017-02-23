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
WORK_PATH=$PWD
source ${WORK_PATH}/conf/colors.sh

function usage {
    set -
    echo "This is a deployment example for publishing the reports in a local apache server."
    echo "usage : $0 [ ARGS ... ]"
    echo "   -e   systemctl enable httpd.service"
    echo "   -s   systemctl start httpd.service"
    echo "   -f   firewall-cmd --set-default-zone=public"
    echo "        firewall-cmd --permanent --zone=public --add-service=http"
    echo "        firewall-cmd --permanent --zone=public --add-service=https"
    echo "        firewall-cmd --reload"
    echo "   -c   cp *.html /var/www/html/"
    echo "   -h   show this help"
    echo ""
}

if [ $# -eq 0 ]; then
    usage
    exit 0
fi

source ${WORK_PATH}/common/install-pakages.sh
install-pakages httpd

for i in "$@"
do
case $i in
    -e)
    set -x
    sudo systemctl enable httpd.service
    set -
    ;;
    -s)
    set -x
    sudo systemctl start httpd.service
    set -
    ;;
    -f)
    set -x
    sudo firewall-cmd --set-default-zone=public
    sudo firewall-cmd --permanent --zone=public --add-service=http
    sudo firewall-cmd --permanent --zone=public --add-service=https
    sudo firewall-cmd --reload
    set -
    ;;
    -h|--help)
    usage
    ;;
    -c)
    set -x
    sudo cp *.html /var/www/html/
    set -
    ;;
    *)
    echo "Unknowed option : $i"
    ;;
esac
done
