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
INSTALL_TRANS=
DEPLOY_MARIADB=
UPDATE_DEPLOY=

function usage {
    echo "This script downloads the translation of askbot"
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   --deploy              Create MariaDB database & user, virtualenv"
    echo "   --update              Update translations in local deployment"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

function update_deploy {
    source ${WORK_PATH}/VirtpyAskboot/bin/activate

    cd ${WORK_PATH}/VirtpyAskboot/askbot-devel
    tx pull -fs -l ${LANG_CODE}

    cd ${WORK_PATH}/VirtpyAskboot/askbot-devel/askbot
    python ../../forum/manage.py compilemessages

    cd ${WORK_PATH}/VirtpyAskboot/forum
    python manage.py runserver
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
    tx pull -fs -l ${LANG_CODE}
    python setup.py develop

    cd ${WORK_PATH}/VirtpyAskboot
    askbot-setup --db-engine=3 --db-name=dbaskbot --db-user=dbaskbotuser --db-password=dbaskbotpassword -n forum

    cd ${WORK_PATH}/VirtpyAskboot/forum
    echo "${RED}When the script asks you if you want to create a superuser, answer no.${NC}"
    python manage.py syncdb
    python manage.py migrate askbot
    python manage.py migrate django_authopenid
    python manage.py migrate
    python manage.py createsuperuser

    cd ${WORK_PATH}/VirtpyAskboot/askbot-devel
    tx pull -fs -l ${LANG_CODE}

    cd ${WORK_PATH}/VirtpyAskboot/askbot-devel/askbot
    python ../../forum/manage.py compilemessages

    cd ${WORK_PATH}/VirtpyAskboot/forum
    sed -i -e "s/LANGUAGE_CODE = 'en'/LANGUAGE_CODE = '${LANG_CODE}'/g" settings.py
    python manage.py runserver
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

function report {
    rpm -q pology aspell-${LANG_CODE} python-enchant enchant-aspell &> /dev/null
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
        ${WORK_PATH}/common/build-languagetool.sh --path=${WORK_PATH} -l=${LANG_CODE}
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
    --deploy)
    DEPLOY_MARIADB="YES"
    ;;
    --update)
    UPDATE_DEPLOY="YES"
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

### Main
download
if [ -n "$GENERATE_REPORT" ]; then
    report
fi
if [ -n "$DEPLOY_MARIADB" ] && [ -z "${UPDATE_DEPLOY}" ]; then
    deploy_mariadb
fi
if [ -z "$DEPLOY_MARIADB" ] && [ -n "${UPDATE_DEPLOY}" ]; then
    update_deploy
fi
echo "complete!"
