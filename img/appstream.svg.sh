#dnf install -y perl-SQL-Translator
echo ".schema" | sqlite3 appstream/stats/appstream.db > appstream.sql
sqlt-graph -c --from=SQLite -t svg -o img/appstream.svg appstream.sql
