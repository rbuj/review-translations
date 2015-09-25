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

WORK_PATH=$PWD
BASE_PATH=${WORK_PATH}

LANG_CODE=
GENERATE_REPORT=
DISABLE_WORDLIST=
INSTALL_TRANS=
DEPLOY_MARIADB=

function usage {
    echo "This script downloads the translation of askbot"
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   --deploy              Create MariaDB database & user, virtualenv"
    echo "   --disable-wordlist    Do not use wordlist file"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

function deploy_mariadb {
    rpm -q mysql-server mariadb-devel &> /dev/null
    if [ $? -ne 0 ]; then
        set -x
        sudo dnf install -y mysql-server mariadb-devel
        set -
    fi
    set -x
    sudo systemctl start mariadb.service
    sudo systemctl enable mariadb.service
    sudo mysql_secure_installation
    mysql -u root -p < ${WORK_PATH}/askbot.sql
    set -

    if [ ! -d "${WORK_PATH}/VirtPyAskboot" ]; then
        virtualenv --no-site-package ${WORK_PATH}/VirtpyAskboot
    fi
    source ${WORK_PATH}/VirtpyAskboot/bin/activate

    pip install mysql-python

    cd ${WORK_PATH}/VirtpyAskboot
    if [ ! -d "${WORK_PATH}/VirtPyAskboot" ]; then
        cd ${WORK_PATH}/VirtpyAskboot
        git clone git://github.com/ASKBOT/askbot-devel.git
    else
        cd ${WORK_PATH}/VirtpyAskboot/askbot-devel
        git pull
    fi

    cd ${WORK_PATH}/VirtpyAskboot/askbot-devel
    tx pull -fas
    python setup.py develop

    cd ${WORK_PATH}/VirtpyAskboot
    askbot-setup --db-engine=3 --db-name=dbaskbot --db-user=dbaskbootuser --db-password=dbaskbootpassword -n forum

    cd ${WORK_PATH}/VirtpyAskboot/forum
    echo "${RED}When the script asks you if you want to create a superuser, answer no.${NC}"
    python manage.py syncdb
    python manage.py migrate askbot
    python manage.py migrate django_authopenid
    python manage.py migrate
    python manage.py createsuperuser

    cd ${WORK_PATH}/VirtpyAskboot/askbot-devel
    tx pull -fas

    cd ${WORK_PATH}/VirtpyAskboot/askbot-devel/askbot
    python ../../forum/manage.py compilemessages

    cd ${WORK_PATH}/VirtpyAskboot/forum
    sed -i -e "s/LANGUAGE_CODE = 'en'/LANGUAGE_CODE = '${LANG_CODE}'/g" settings.py
    python manage.py runserver

    set -x
    echo "drop database dbaskbot;" | mysql -u root -p
    echo "drop user dbaskbootuser;" | mysql -u root -p
    set -
}

function install {
    if [ ! -d "/usr/lib/python2.7/site-packages/askbot" ]; then
        rpm -q python-devel redhat-rpm-config python-virtualenv python-mysql > /dev/null
        if [ $? -ne 0 ]; then
            set -x
            sudo dnf install -y python-devel redhat-rpm-config python-mysql &> /dev/null && echo "${GREEN}[ OK ]${NC}" || exit 1
            set -
        fi
        sudo pip install askbot
    fi
    for file in djangojs django; do
        set -x
        sudo rm -f /usr/lib/python2.7/site-packages/askbot/locale/${LANG_CODE}/LC_MESSAGES/${file}.mo /usr/lib/python2.7/site-packages/askbot/locale/${LANG_CODE}/LC_MESSAGES/${file}.po
        sudo msgfmt ${BASE_PATH}/askbot/askbot/locale/${LANG_CODE}/LC_MESSAGES/${file}.po -o /usr/lib/python2.7/site-packages/askbot/locale/${LANG_CODE}/LC_MESSAGES/${file}.mo
        sudo cp ${BASE_PATH}/askbot/askbot/locale/${LANG_CODE}/LC_MESSAGES/${file}.po /usr/lib/python2.7/site-packages/askbot/locale/${LANG_CODE}/LC_MESSAGES/
        set -
    done
    echo ""
    echo "Please read the following steps to complete the installation:"
    echo "    * Create database for Askbot : http://askbot.org/doc/create-database.html"
    echo "    * Initial Configuration of Askbot : http://askbot.org/doc/initial-configuration.html"
    echo "    * ..."
    echo ""
}

function download_code {
    cd ${BASE_PATH}
    if [ ! -d "${1}" ]; then
        echo -ne "git clone "
        git clone $2 $1 &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    else
        cd $1
        echo -ne "git pull "
        git pull &> /dev/null && echo "${GREEN}[ OK ]${NC}" || echo "${RED}[ FAIL ]${NC}"
    fi
}

function get_code {
    download_code askbot https://github.com/ASKBOT/askbot-devel.git
}

function get_trans {
    rpm -q transifex-client &> /dev/null
    if [ $? -ne 0 ]; then
        echo "report : installing required packages"
        set -x
        sudo dnf install -y transifex-client
        set -
    fi
    echo -ne "downloading translation "
    cd ${BASE_PATH}/askbot
    find ./askbot/locale/${LANG_CODE} -type f -name '*.po' -exec rm '{}' \;
    tx pull -l ${LANG_CODE} > /dev/null
    if [ $? -ne 0 ]; then
        echo " ${RED}[ FAIL ]${NC}"
        exit 1
    else
        echo " ${GREEN}[ OK ]${NC}"
    fi
}

function download {
    get_code
    get_trans
}

function fedora_wordlist {
    DICT=${WORK_PATH}/pology/lang/${LANG_CODE}/spell/report-fedora.aspell
    if [ -n "${DISABLE_WORDLIST}" ]; then
        if [ -f "${DICT}" ]; then
            rm -f ${DICT}
        fi
    else
        if [ ! -d "${WORK_PATH}/pology/lang/${LANG_CODE}/spell" ]; then
            mkdir -p ${WORK_PATH}/pology/lang/${LANG_CODE}/spell
        fi
        WORDS=`cat ${WORK_PATH}/wordlist | wc -l`
        echo "personal_ws-1.1 ${LANG_CODE} ${WORDS} utf-8" > ${DICT}
        cat ${WORK_PATH}/wordlist >> ${DICT}
    fi
}

function report {
    rpm -q aspell-${LANG_CODE} python-enchant enchant-aspell &> /dev/null
    if [ $? -ne 0 ]; then
        echo "report : installing required packages"
        set -x
        sudo dnf install -y aspell-${LANG_CODE} python-enchant enchant-aspell
        set -
    fi
    #########################################
    # LANGUAGETOOL
    #########################################
    if [ ! -d "${WORK_PATH}/languagetool" ]; then
        ${WORK_PATH}/build-languagetool.sh --path=${WORK_PATH} -l=${LANG_CODE}
    fi
    cd ${WORK_PATH}
    LANGUAGETOOL=`find . -name 'languagetool-server.jar'`
    java -cp $LANGUAGETOOL org.languagetool.server.HTTPServer --port 8081 > /dev/null &
    LANGUAGETOOL_PID=$!

    echo -ne "report : waiting for langtool"
    until $(curl --output /dev/null --silent --data "language=ca&text=Hola món!" --fail http://localhost:8081); do
        printf '.'
        sleep 1
    done
    if [ $? -ne 0 ]; then
        echo " ${RED}[ FAIL ]${NC}"
    else
        echo " ${GREEN}[ OK ]${NC}"
    fi

    #########################################
    # POLOGY
    #########################################
    if [ ! -d "${WORK_PATH}/pology" ]; then
        ${WORK_PATH}/build-pology.sh --path=${WORK_PATH}
    fi
    export PYTHONPATH=${WORK_PATH}/pology:$PYTHONPATH
    export PATH=${WORK_PATH}/pology/bin:$PATH
    fedora_wordlist

    HTML_REPORT=${WORK_PATH}/askbot-report.html
    cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html lang="${LANG_CODE}" xml:lang="${LANG_CODE}" xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <meta http-equiv="content-type" content="text/html; charset=UTF-8" />
    <title>Translation Report</title>
  </head>
<body bgcolor="#080808" text="#D0D0D0">
EOF

    echo "************************************************"
    echo "* checking translation..."
    echo "************************************************"
    posieve check-rules,check-spell-ec,check-grammar,stats -s lang:${LANG_CODE} -s showfmsg -s byrule --msgfmt-check --skip-obsolete --coloring-type=html ${BASE_PATH}/askbot/askbot/locale/${LANG_CODE}/ >> ${HTML_REPORT}

    cat << EOF >> ${HTML_REPORT}
</body>
</html>
EOF

    chmod 644 ${HTML_REPORT}
    kill -9 ${LANGUAGETOOL_PID} > /dev/null
}

for i in "$@"
do
case $i in
    -l=*|--lang=*)
    LANG_CODE="${i#*=}"
    shift # past argument=value
    ;;
    -r|--report)
    GENERATE_REPORT="YES"
    ;;
    --disable-wordlist)
    DISABLE_WORDLIST="YES"
    ;;
    --deploy)
    DEPLOY_MARIADB="YES"
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

if [ -z "${LANG_CODE}" ]; then
    usage
    exit 1
fi
if [ -z "${GENERATE_REPORT}" ] && [ -n "${DISABLE_WORDLIST}" ]; then
    usage
    exit 1
fi

### Main
download
if [ -n "$GENERATE_REPORT" ]; then
    report
fi
if [ -n "$DEPLOY_MARIADB" ]; then
    deploy_mariadb
fi
echo "complete!"
