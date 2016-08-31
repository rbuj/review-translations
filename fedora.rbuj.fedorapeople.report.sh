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
HTML_REPORT="index.html"
declare -A scripts=( "fedora-main" "fedora-upstream" "fedora-web" )
declare -A locales= ( "ca" "de" "el" "es" "fr" "gl" "it" "nl" "pt" "ru" )
declare -A header=( ["fedora-main"]="Fedora Websites" ["fedora-upstream"]="Fedora Upstream" ["fedora-web"]="Fedora Websites" )
declare -A languages=( ["ca"]="Catalan" ["de"]="German" ["el"]="Greek" ["es"]="Spanish" ["fr"]="French" ["gl"]="Galician" ["it"]="Italian" ["nl"]="Dutch" ["pt"]="Portuguese" ["ru"]="Russian" )

for SCRIPT in ${scripts[@]}; do
cat << EOF > ${HTML_REPORT}
<!DOCTYPE html>
<html>
<head>
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

<h1>${header[${SCRIPT}]}</h1>
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
    ./${SCRIPT}.sh -l=$LOCALE -r --disable-wordlist;
    mv ${SCRIPT}-report.html ${SCRIPT}-report.${LOCALE}.html;
    gzip ${SCRIPT}-report.${LOCALE}.html
    cat << EOF >> ${HTML_REPORT}
  <tr>
    <td>${LOCALE}</td>
    <td><A HREF="fedora-web-report.${LOCALE}.html.gz">${languages[${LOCALE}]}</A></td>
    <td>${$(du -h ${SCRIPT}-report.${LOCALE}.html.gz | cut -f1)}</td>
    <td>${$(md5sum ${SCRIPT}-report.${LOCALE}.html.gz)}</td>
  </tr>
EOF
done
cat << EOF >> ${HTML_REPORT}
</table>
<figure>
  <img src="/img/fedora-web-msg.png" alt="Messages">
  <figcaption style="text-align: center;">Fig.1 - Messages.</figcaption>
</figure>
<figure>
  <img src="/img/fedora-web-w.png" alt="Words">
  <figcaption style="text-align: center;">Fig.1 - Words.</figcaption>
</figure>
<br/>${$(LC_ALL=en.utf8 date '+%B %d, %Y')}.
<br/><br/>&copy; 2016 Robert Antoni Buj Gelonch - <a href="https://github.com/rbuj/review-translations">https://github.com/rbuj/review-translations</a>
</body>
</html>
EOF
chmod 644 index.html
scp -i ~/.ssh/id_rsa index.html rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/${SCRIPT}-report
scp -i ~/.ssh/id_rsa *.gz rbuj@fedorapeople.org:/home/fedora/rbuj/public_html/${SCRIPT}-report
rm -f *.gz
done
rm -f indedx.html
