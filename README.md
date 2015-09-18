# review-translations

Bash scripts for Fedora Project translations, to make a report for the reviewing of the translations for a specified language.
* fedora-web.sh : checks the web group projects, https://fedora.zanata.org/version-group/view/web
* fedora-main.sh : checks the main group projects,  https://fedora.zanata.org/version-group/view/main

Installation on Fedora
----------------------

```
git clone https://github.com/rbuj/review-translations.git
```

Usage Examples
--------------

```
./fedora-web.sh -l=ca
./fedora-main.sh -l=ca
```

