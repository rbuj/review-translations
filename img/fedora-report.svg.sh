# dnf install -y perl-SQL-Translator
echo ".schema" | sqlite3 fedora-report.db > fedora-report.sql
sqlt-graph -c --from=SQLite -t svg -o img/fedora-report.svg fedora-report.sql
