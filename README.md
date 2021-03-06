# review-translations

Bash scripts for downloading the Fedora Project translations. Those scripts can also make a report for reviewing grammar and spelling mistakes for a specified language.
* fedora-docs.sh : download the translations that belongs to the [docs group](https://fedora.zanata.org/version-group/view/docs)
* fedora-main.sh : download the translations that belongs to the [main group](https://fedora.zanata.org/version-group/view/main)
* fedora-report.sh : uploads the reports to [https://rbuj.fedorapeople.org](https://rbuj.fedorapeople.org/)
* fedora-rhel.sh : download the translations that belongs to the [main group](https://fedora.zanata.org/version-group/view/rhel)
* fedora-upstream.sh : download the translations that belongs to the [upstream group](https://fedora.zanata.org/version-group/view/upstream)
* fedora-web.sh : download the translations that belongs to the [web group](https://fedora.zanata.org/version-group/view/web)

Components (scripts which are used by other scrips):
* common/languagetool.sh : builds LanguageTool if there is no languagetool folder and launch LT server
* common/download-fedora.sh : downloads the translations from fedora.zanata.org
* common/download-git.sh : downloads the translations from a git repo
* common/download-transifex.sh : downloads the translations from transifex
* common/fedora-version.sh : gets the branch from the OS version
* common/fedpkg-install.sh : patches and installs the project related packages with new translations
* common/install.sh : installs the translations in the system
* common/stats.sh : creates images for word and message translation status for all languages
* common/translations.sh : handles the translations
* common/report.sh : makes a translation report of a translation group
* common/zanata.sh : downloads the translations from zanata

More scripts:
* appstream.sh : downloads and tests the translations of [AppStream](http://www.freedesktop.org/wiki/Distributions/AppStream/)
* askbot.sh : downloads and tests the translations of [askbot](https://askbot.com/) which is used in [Ask Fedora](https://ask.fedoraproject.org)
* audacious.sh : downloads and tests the translations of [audacious] (http://audacious-media-player.org//)
* audacity.sh : downloads and tests the translations of [audacity] (http://www.audacityteam.org/)
* clipit.sh : downloads and tests the translations of [ClipIt](https://github.com/shantzu/ClipIt)
* colord.sh : downloads and tests the translations of [colord](https://www.freedesktop.org/software/colord/)
* colorhug-client : downloads and tests the translations of [colorhug-client](http://www.hughski.com/)
* compiz-reloaded.sh: downloads and tests the translations of [Compiz](http://www.compiz.org/)
* exaile.sh: downloads and tests the translations of [exaile](http://www.exaile.org/)
* freedesktop.sh : downloads and tests the translations of [accounts-service](http://freedesktop.org/wiki/Software/AccountsService/), [fprintd](http://www.freedesktop.org/wiki/Software/fprint/), [PackageKit](http://www.freedesktop.org/software/PackageKit/), [Shared MIME-info Database](http://standards.freedesktop.org/shared-mime-info-spec/latest/) and [udisks2](http://www.freedesktop.org/wiki/Software/udisks/)
* fwupd.sh : downloads and tests the translations of [fwupd](http://www.fwupd.org/)
* geany.sh : downloads and tests the translations of [geany](http://www.geany.org/)
* gnome.sh : downloads and tests the translations of some [GNOME packages](https://www.gnome.org/)
* hexchat.sh : downloads and tests the translations of [HexChat](https://hexchat.github.io/)
* MATE-1-20.sh : downloads and tests the translations of [MATE Desktop Environment on Fedora](http://mate-desktop.org/)
* MATE-master.sh : downloads and tests the translations of [MATE Desktop Environment on Fedora](http://mate-desktop.org/)
* phpMyAdmin.sh : downloads and tests the translations of [phpMyAdmin on Fedora](https://www.phpmyadmin.net/)
* rpm.sh : downloads and tests the translations of [RPM package](http://www.rpm.org/)
* sugar.sh : downloads and tests the translations of [Sugar Labs on Fedora](https://spins.fedoraproject.org/soas/)
* transmission.sh : downloads and tests the translations of [Transmission](https://transmissionbt.com/) - gtk only
* update-compiz-reloaded.list.sh : update list/compiz-reloaded.list file EXPERIMENTAL
* update-gnome-list.sh : update list/gnome.list file
* XFCE.sh : downloads and tests the translations of [xfce](http://www.xfce.org/)
* yumex.sh : downloads and tests the translations of [yumex](http://www.yumex.dk/) and [yumex-dnf](http://www.yumex.dk/)

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
./fedora-main.sh -l=ca -r -i
```


```
./fedora-main.sh -l=ca -r
```


```
./fedora-main.sh -l=ca -i
```


```
./fedora-main.sh -l=ca
```

