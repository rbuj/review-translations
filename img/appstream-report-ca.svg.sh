# dnf install -y perl-SQL-Translator
echo ".schema" | sqlite3 appstream/report/appstream-report-ca.db > appstream-report-ca.sql
sqlt-graph -c --from=SQLite -t svg -o img/appstream-report-ca.svg appstream-report-ca.sql
