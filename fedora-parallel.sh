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

SCRIPTS=(./fedora-web.sh ./fedora-main.sh ./fedora-upstream.sh)
declare -A tasks
LANG_CODE=
GENERATE_REPORT=
DISABLE_WORDLIST=
LANGUAGETOOL_PID=

function usage {
    echo "This script downloads the translations that belongs to all grops in parallel"
    echo "    usage : $0 -l|--lang=LANG_CODE [ARGS]"
    echo -ne "\nMandatory arguments:\n"
    echo "   -l|--lang=LANG_CODE   Locale to pull from the server"
    echo -ne "\nOptional arguments:\n"
    echo "   -r, --report          Generate group report"
    echo "   --disable-wordlist    Do not use wordlist file (requires -r)"
    echo "   -h, --help            Display this help and exit"
    echo ""
    echo -ne "[1] https://fedora.zanata.org/version-group/view/web\n"
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
    --disable-wordlist)
    DISABLE_WORDLIST="YES"
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

if [ -n "${GENERATE_REPORT}" ]; then
    #########################################
    # LANGUAGETOOL
    #########################################
    if [ -z "${LT_SERVER}" ] && [ -z "${LT_PORT}" ]; then
        if [ ! -d "${WORK_PATH}/languagetool" ]; then
            ${WORK_PATH}/build-languagetool.sh --path=${WORK_PATH} -l=${LANG_CODE}
        fi
        cd ${WORK_PATH}
        LANGUAGETOOL=`find . -name 'languagetool-server.jar'`
        java -cp $LANGUAGETOOL org.languagetool.server.HTTPServer --port 8081 > /dev/null &
        LANGUAGETOOL_PID=$!
    fi

    #########################################
    # POLOGY
    #########################################
    if [ ! -d "${WORK_PATH}/pology" ]; then
        ${WORK_PATH}/build-pology.sh --path=${WORK_PATH}
    fi
fi

cd ${WORK_PATH}
for i in "${!SCRIPTS[@]}"; do
    if [ -n "$GENERATE_REPORT" ]; then
        if [ -z "${DISABLE_WORDLIST}" ]; then
            tasks["key${i}"]="${SCRIPTS[${i}]} -l=${LANG_CODE} -r --languagetool-server=localhost --languagetool-port=8081"
        else
            tasks["key${i}"]="${SCRIPTS[${i}]} -l=${LANG_CODE} -r --disable-wordlist --languagetool-server=localhost --languagetool-port=8081"
        fi
    fi
done

### Main ###
main
kill -9 $LANGUAGETOOL_PID > /dev/null
echo "complete!"
