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
BRANCH=$(./common/fedora-version.sh)
function info_proc {
    while read -r p; do
        set -- $p
        PROJECT=${1}

        fedpkg -q co $PROJECT -b $BRANCH --anonymous &> /dev/null
        if [ $? -eq 0 ]; then
            if [ -d "$PROJECT" ]; then
                cd $PROJECT
                if [ -f "sources" ]; then
                    HASH=$(awk 'NR==1 {print $1}' sources)
                    case $HASH in
                    SHA512)
                        FILE=$(awk -F '[()]' 'NR==1 {print $2}' sources)
                    ;;
                    *)
                        FILE=$(awk 'NR==1 {print $2}' sources)
                    ;;
                    esac
                    fedpkg -q sources &> /dev/null
                    DATE="@"$(stat -c %Y $FILE 2>/dev/null)
                    if [ $? -eq 0 ]; then
                        STR_DATE=$(date -d $DATE +%Y-%m-%d)
                        if [ $? -eq 0 ]; then
                            arrIN=(${FILE//.tar./ })
                            VERSION=${arrIN[0]}
                            echo $STR_DATE $PROJECT ${VERSION/$PROJECT-/}
                        fi
                    fi
                fi
                cd ..
                rm -fr $PROJECT
            fi
        fi
    done <${INPUT_FILE}
}

for i in "$@"
do
case $i in
    -f=*|--file=*)
    INPUT_FILE="${i#*=}"
    shift # past argument=value
    ;;
esac
done

cat <<EOF
<!DOCTYPE html>
<html>
<head>
<style>
table {
    border-collapse: collapse;
}

th, td {
    text-align: left;
    padding: 8px;
}

tr:nth-child(even){background-color: #f2f2f2}

th {
    background-color: #4CAF50;
    color: white;
}
</style>
</head>
<body>
<table>
<tr>
<th>Date</th>
<th>Package</th>
<th>Version</th>
</tr>
EOF
info_proc | sort -r | awk '{print "<tr>";for(i=1;i<=NF;i++)print "<td>" $i"</td>";print "</tr>"}'
cat <<EOF
</table>

</body>
</html>
EOF
