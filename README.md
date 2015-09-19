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
$ ./fedora-web.sh -h
This script downloads the translations of the projects that belongs to web group [1].
  usage : ./fedora-web.sh [-l|--lang]=LANG_CODE
   -r|report       generate group report

[1] https://fedora.zanata.org/version-group/view/web
```


```
./fedora-main.sh -l=ca -r
```


```
./fedora-main.sh -l=ca
```

