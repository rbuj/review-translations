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

SCRIPTS=(./fedora-docs.sh ./fedora-main.sh ./fedora-upstream.sh ./fedora-web.sh ./fedora-rhel.sh)
declare -A tasks
LANG_CODE=
GENERATE_REPORT=
LANGUAGETOOL_PID=

function usage {
    echo "This script downloads the translations that belongs to all grops in parallel"
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   -h, --help            Display this help and exit"
    echo ""
}

main () {
    local -A pids=()
    local max_concurrent_tasks=2

    for key in "${!tasks[@]}"; do
        while [ $(jobs 2>&1 | grep -c Running) -ge "$max_concurrent_tasks" ]; do
            sleep 1 # gnu sleep allows floating point here...
        done
        ${tasks[$key]} > /dev/null &
        pids+=(["$key"]="$!")
    done

    errors=0
    for key in "${!tasks[@]}"; do
        pid=${pids[$key]}
        local cur_ret=0
        if [ -z "$pid" ]; then
            echo "No Job ID known for the $key process" # should never happen
            cur_ret=1
        else
            wait $pid
            cur_ret=$?
        fi
        if [ "$cur_ret" -ne 0 ]; then
            errors=$(($errors + 1))
            echo "$key (${tasks[$key]}) failed."
        fi
    done

    return $errors
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

if [ -n "${GENERATE_REPORT}" ]; then
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
fi

rpm -q pology &> /dev/null
if [ $? -ne 0 ]; then
    echo "download : installing required packages"
    VERSION_AUX=( $(cat /etc/fedora-release) )
    if [ "${VERSION_AUX[${#VERSION_AUX[@]}-1]}" == "(Rawhide)" ]; then sudo dnf install -y pology --nogpgcheck; else sudo dnf install -y pology; fi
fi

cd ${WORK_PATH}
for i in "${!SCRIPTS[@]}"; do
    if [ -n "$GENERATE_REPORT" ]; then
        tasks["key${i}"]="${SCRIPTS[${i}]} -l=${LANG_CODE} -r --languagetool-server=localhost --languagetool-port=8081"
    fi
done

### Main ###
main
kill -9 $LANGUAGETOOL_PID > /dev/null
echo "complete!"
