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
declare -a PROJECT_NAMES=( fedora-main fedora-upstream fedora-web )
declare -a locales=( ca de el es fr gl it nl pt ru )
declare -A header=( [fedora-main]="Fedora Main" [fedora-upstream]="Fedora Upstream" [fedora-web]="Fedora Websites" )
declare -A languages=( [ca]="Catalan" [de]="German" [el]="Greek" [es]="Spanish" [fr]="French" [gl]="Galician" [it]="Italian" [nl]="Dutch" [pt]="Portuguese" [ru]="Russian" )
WORK_PATH=$PWD

echo "***************************************"
echo "* downloading translations ..."
echo "***************************************"
for PROJECT_NAME in ${PROJECT_NAMES[@]}; do
    cd ${WORK_PATH}
    for LOCALE in ${locales[@]}; do
        ${WORK_PATH}/${PROJECT_NAME}.sh -l=$LOCALE;
    done
done

echo "***************************************"
echo "* reports ..."
echo "***************************************"
for PROJECT_NAME in ${PROJECT_NAMES[@]}; do
BASE_PATH=${WORK_PATH}/${PROJECT_NAME}
HTML_REPORT="${WORK_PATH}/${PROJECT_NAME}-index.html"
cd ${WORK_PATH}
rm -f ${WORK_PATH}/${PROJECT_NAME}.*.html.gz ${WORK_PATH}/${PROJECT_NAME}.*.html
cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html>
<head>
<title>${header[${PROJECT_NAME}]}</title>
<style>
table {
    font-family: arial, sans-serif;
    border-collapse: collapse;
    width: 100%;
}

td, th {
    border: 1px solid #dddddd;
    text-align: left;
    padding: 8px;
}

tr:nth-child(even) {
    background-color: #dddddd;
}

figure {
    display: inline-block;
    border: 1px none;
    margin: 20px; /* adjust as needed */
}

figure img {
    vertical-align: top;
}

figure figcaption {
    border: none;
    text-align: center;
}
</style>
</head>
<body>

<h1>${header[${PROJECT_NAME}]}</h1>
<h2>spelling and grammar report</h2>
<table>
  <tr>
    <th>ISO 6391-1 Code</th>
    <th>Language</th>
    <th>Size</th>
    <th>MD5SUM</th>
  </tr>
EOF
for LOCALE in ${locales[@]}; do
    ${WORK_PATH}/${PROJECT_NAME}.sh -l=$LOCALE -r --disable-wordlist -n;
    mv ${WORK_PATH}/${PROJECT_NAME}-report.html ${WORK_PATH}/${PROJECT_NAME}-report.${LOCALE}.html;
    cd ${WORK_PATH}
    rm -f ${PROJECT_NAME}-report.${LOCALE}.html.gz
    gzip ${PROJECT_NAME}-report.${LOCALE}.html
    cat << EOF >> ${HTML_REPORT}
  <tr>
    <td>${LOCALE}</td>
    <td><A HREF="${PROJECT_NAME}.${LOCALE}.html.gz">${languages[${LOCALE}]}</A></td>
    <td>$(du -h ${PROJECT_NAME}-report.${LOCALE}.html.gz | cut -f1)</td>
    <td>$(md5sum ${PROJECT_NAME}-report.${LOCALE}.html.gz)</td>
  </tr>
EOF
done
${WORK_PATH}/${PROJECT_NAME}.sh -n -s -a;
cat << EOF >> ${HTML_REPORT}
</table>
<figure>
  <img src="data:image/png;base64,$(base64 -w 0 ${BASE_PATH}/${PROJECT_NAME}-msg.png)" alt="Messages">
  <figcaption style="text-align: center;">Fig.1 - Messages.</figcaption>
</figure>
<figure>
  <img src="data:image/png;base64,$(base64 -w 0 ${BASE_PATH}/${PROJECT_NAME}-w.png)" alt="Words">
  <figcaption style="text-align: center;">Fig.2 - Words.</figcaption>
</figure>
<br>$(LC_ALL=en.utf8 date)
<br><br>&copy; 2015-2016 Robert Antoni Buj Gelonch - <a href="https://github.com/rbuj/review-translations">https://github.com/rbuj/review-translations</a>
<br><br>
    Copyright (C) $(LC_ALL=en.utf8 date '+%Y') Robert Antoni Buj Gelonch.
    Permission is granted to copy, distribute and/or modify this document
    under the terms of the GNU Free Documentation License, Version 1.3
    or any later version published by the Free Software Foundation;
    with no Invariant Sections, no Front-Cover Texts, and no Back-Cover Texts.
    A copy of the license is included in the section entitled "GNU
    Free Documentation License".
</body>
</html>
EOF
chmod 644 ${HTML_REPORT}
done

echo "***************************************"
echo "* uploading ..."
echo "***************************************"
for PROJECT_NAME in ${PROJECT_NAMES[@]}; do
    scp -i ~/.ssh/id_rsa ${WORK_PATH}/${PROJECT_NAME}.*.html.gz rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/${PROJECT_NAME}-report
    scp -i ~/.ssh/id_rsa ${WORK_PATH}/${PROJECT_NAME}-index.html rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/${PROJECT_NAME}-report/index.html
done
