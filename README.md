# review-translations

Bash scripts for downloading the Fedora Project translations. Those scripts can also make a report for reviewing the grammar and the orthographic mistakes for a specified language.
* fedora-web.sh : download the translations that belongs to the [web group](https://fedora.zanata.org/version-group/view/web)
* fedora-main.sh : download the translations that belongs to the [main group](https://fedora.zanata.org/version-group/view/main)

Installation on Fedora
----------------------

```
git clone https://github.com/rbuj/review-translations.git
```

Usage Examples
--------------

```
$ ./fedora-main.sh -h
This script downloads the translations of the projects that belongs to main group [1].
    usage : ./fedora-main.sh -l|--lang=LANG_CODE [ARGS]

Mandatory arguments:
   -l|--lang=LANG_CODE   Locale to pull from the server

Optional arguments:
   -r, --report          Generate group report
   -i, --install         Install translations
   -h, --help            Display this help and exit

[1] https://fedora.zanata.org/version-group/view/main
```


```
./fedora-main.sh -l=ca -r
```


```
./fedora-main.sh -l=ca
```

