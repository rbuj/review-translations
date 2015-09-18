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
RED=`tput setaf 1`
GREEN=`tput setaf 2`
NC=`tput sgr0` # No Color

DIRECTORI_TREBALL=$PWD
DIRECTORI_BASE=${DIRECTORI_TREBALL}/fedora-main
LANG_CODE=

PROJECT=(abrt abrt anaconda anaconda anaconda anaconda authconfig blivet blivet blivet blivet chkconfig comps firewalld firewalld gnome-abrt gnome-abrt initscripts libpwquality libreport libreport libuser liveusb-creator mlocate newt passwd pykickstart pykickstart python-meh python-meh selinux setroubleshoot system-config-firewall system-config-kdump system-config-kickstart system-config-language system-config-printer usermode)
VERSION=(master rhel7 rhel7-branch rhel6-branch f23-branch master master rhel7-branch rhel6-branch f23-branch master master master master RHEL-7 master rhel7 master master master rhel7 default master default master password master rhel7-branch master rhel7-branch master master master master master master master default)

function usage {
    echo $"usage"" : $0 [-l|--lang]=LANG_CODE"
}

function get_trans {
    echo -ne "downloading : ${PROJECT[$1]}-${VERSION[$1]} "
    if [ ! -d "${DIRECTORI_BASE}/${PROJECT[$1]}-${VERSION[$1]}" ]; then
        mkdir -p ${DIRECTORI_BASE}/${PROJECT[$1]}-${VERSION[$1]}
    fi
    FITXER=${DIRECTORI_BASE}/${PROJECT[$1]}-${VERSION[$1]}/zanata.xml
    if [ ! -f "${FITXER}" ]; then
        cat << EOF > ${FITXER}
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<config xmlns="http://zanata.org/namespace/config/">
  <url>https://fedora.zanata.org/</url>
  <project>${PROJECT[$1]}</project>
  <project-version>${VERSION[$1]}</project-version>
  <project-type>gettext</project-type>

</config>
EOF
    fi
    cd ${DIRECTORI_BASE}/${PROJECT[$1]}"-"${VERSION[$1]}
    zanata-cli -B pull -l ${LANG_CODE} > /dev/null && echo "${GREEN}[ OK ]${NC}" || exit 1
}

function test {
    for (( i=0; i<${#PROJECT[@]}; i++ )); do
        get_trans $i
    done
}

function checking {
if [ ! -d ${DIRECTORI_TREBALL}/pology ]; then
    cd ${DIRECTORI_TREBALL}
    svn checkout svn://anonsvn.kde.org/home/kde/trunk/l10n-support/pology
    cd pology
    mkdir build && cd build
    cmake ..
    make
fi

export PYTHONPATH=${DIRECTORI_TREBALL}/pology:$PYTHONPATH
export PATH=${DIRECTORI_TREBALL}/pology/bin:$PATH

HTML_REPORT=${DIRECTORI_TREBALL}/fedora-main-report.html
cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html lang="${LANG_CODE}" xml:lang="${LANG_CODE}" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Translation Report</title>
  </head>
<body bgcolor="#080808" text="#D0D0D0">
EOF

echo -ne "checking : check the translations"
posieve check-rules,check-spell-ec,stats -s lang:${LANG_CODE} -s showfmsg --msgfmt-check --skip-obsolete --coloring-type=html ${DIRECTORI_BASE}/ >> ${HTML_REPORT}

cat << EOF >> ${HTML_REPORT}
</body>
</html>
EOF
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

for i in "$@"
do
case $i in
    -l=*|--lang=*)
    LANG_CODE="${i#*=}"
    shift # past argument=value
    ;;
    *)
    usage
    exit 1
    ;;
esac
done

rpm -q subversion maven python-enchant zanata-client &> /dev/null
if [ $? -ne 0 ]; then
    echo "installing : required packages"
    sudo dnf install -y subversion maven python-enchant zanata-client &> /dev/null && echo "${GREEN}[ OK ]${NC}" || exit 1
fi

### Main ###
test
checking
echo "Complete!"
