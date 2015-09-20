# review-translations

Bash scripts for downloading the Fedora Project translations. Those scripts can also make a report for reviewing grammar and spelling mistakes for a specified language.
* fedora-web.sh : download the translations that belongs to the [web group](https://fedora.zanata.org/version-group/view/web)
* fedora-main.sh : download the translations that belongs to the [main group](https://fedora.zanata.org/version-group/view/main)

Installation on Fedora
----------------------

```
git clone https://github.com/rbuj/review-translations.git
```

Useful translator comments
--------------------------
* well-spelled, to skip words in spell checking for the report generation, more info in the section: (Skipping Messages and Words)[http://pology.nedohodnik.net//doc/user/en_US/index-mono.html#sec-lgspskip] of the (Pology User Manual)[http://pology.nedohodnik.net//doc/user/en_US/index-mono.html]
* apply-rule and skip-rule, to apply or to skip a rule for the report generation, more info in the section: (Skipping and Manually Applying The Rule on A Message)[http://pology.nedohodnik.net//doc/user/en_US/index-mono.html] of the (Pology User Manual)[http://pology.nedohodnik.net//doc/user/en_US/index-mono.html]

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

