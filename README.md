# review-translations

Bash scripts for downloading the Fedora Project translations. Those scripts can also make a report for reviewing grammar and spelling mistakes for a specified language.
* fedora-main.sh : download the translations that belongs to the [main group](https://fedora.zanata.org/version-group/view/main)
* fedora-upstream.sh : download the translations that belongs to the [upstream group](https://fedora.zanata.org/version-group/view/upstream)
* fedora-web.sh : download the translations that belongs to the [web group](https://fedora.zanata.org/version-group/view/web)

More scripts:
* deploy.sh : a deployment example for publishing the reports in a local apache server.
* sugar.sh : download and test the translations of [Sugar Labs on Fedora](https://spins.fedoraproject.org/soas/)


Installation on Fedora
----------------------

```
git clone https://github.com/rbuj/review-translations.git
```

Useful translator comments
--------------------------
| Translator comment  | Feature | Description | More info  |
| ------------------- | ------- | ----------- | ---------- |
| well-spelled:       | report  | to skip words in spell checking | [Skipping Messages and Words](http://pology.nedohodnik.net//doc/user/en_US/index-mono.html#sec-lgspskip) section of the [Pology User Manual](http://pology.nedohodnik.net//doc/user/en_US/index-mono.html) |
| apply-rule:         | report  | to apply a rule | [Skipping and Manually Applying The Rule on A Message](http://pology.nedohodnik.net//doc/user/en_US/index-mono.html) section of the [Pology User Manual](http://pology.nedohodnik.net//doc/user/en_US/index-mono.html) |
| skip-rule:          | report  | to skip a rule | [Skipping and Manually Applying The Rule on A Message](http://pology.nedohodnik.net//doc/user/en_US/index-mono.html) section of the [Pology User Manual](http://pology.nedohodnik.net//doc/user/en_US/index-mono.html) |

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

