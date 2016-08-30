# review-translations

Bash scripts for downloading the Fedora Project translations. Those scripts can also make a report for reviewing grammar and spelling mistakes for a specified language.
* fedora-docs.sh : download the translations that belongs to the [docs group](https://fedora.zanata.org/version-group/view/docs)
* fedora-main.sh : download the translations that belongs to the [main group](https://fedora.zanata.org/version-group/view/main)
* fedora-upstream.sh : download the translations that belongs to the [upstream group](https://fedora.zanata.org/version-group/view/upstream)
* fedora-web.sh : download the translations that belongs to the [web group](https://fedora.zanata.org/version-group/view/web)
* fedora-parallel.sh : download the translations that belongs to all groups in parallel

Components (scripts which are used by other scrips):
* common/build-languagetool.sh : builds LanguageTool in the specified path if there is no languagetool folder
* common/build-pology.sh : builds Pology in the specified path if there is no pology folder
* common/fedora-version.sh : get current OS version branch
* common/git-translations.sh : handles the translations from git
* common/install.sh : installs the translations in the system
* common/report.sh : makes a translation report of a Fedora group
* common/transifex-translations.sh : handles the translations from transifex
* common/zanata.sh : downloads the translations of a Fedora group

More scripts:
* accounts-service.sh : downloads and tests the translations of [accounts-service](http://freedesktop.org/wiki/Software/AccountsService/)
* appstream.sh : downloads and tests the translations of [AppStream](http://www.freedesktop.org/wiki/Distributions/AppStream/)
* appstream-glib.sh : downloads and tests the translations of [appstream-glib](https://github.com/hughsie/appstream-glib)
* askbot.sh : downloads and tests the translations of [askbot](https://askbot.com/) which is used in [Ask Fedora](https://ask.fedoraproject.org)
* audacious.sh : downloads and tests the translations of [audacious] (http://audacious-media-player.org//)
* audacity.sh : downloads and tests the translations of [audacity] (http://www.audacityteam.org/)
* clipit.sh : downloads and tests the translations of [ClipIt](https://github.com/shantzu/ClipIt)
* colord.sh : downloads and tests the translations of [colord](https://www.freedesktop.org/software/colord/)
* colorhug-client : downloads and tests the translations of [colorhug-client](http://www.hughski.com/)
* compiz-reloaded.sh: downloads and tests the translations of [Compiz](http://www.compiz.org/)
* deploy.sh : a deployment example for publishing the reports in a local apache server
* exaile.sh: downloads and tests the translations of [exaile](http://www.exaile.org/)
* fprintd.sh : downloads and tests the translations of [fprintd](http://www.freedesktop.org/wiki/Software/fprint/)
* fwupd.sh : downloads and tests the translations of [fwupd](http://www.fwupd.org/)
* geany.sh : downloads and tests the translations of [geany](http://www.geany.org/)
* gnome.sh : downloads and tests the translations of some [GNOME packages](https://www.gnome.org/)
* MATE.sh : downloads and tests the translations of [MATE Desktop Environment on Fedora](http://mate-desktop.org/)
* PackageKit.sh : downloads and tests the translations of [PackageKit](http://www.freedesktop.org/software/PackageKit/)
* rpm.sh : downloads and tests the translations of [RPM package](http://www.rpm.org/)
* shared-mime-info.sh : downloads and tests the translations of [Shared MIME-info Database](http://standards.freedesktop.org/shared-mime-info-spec/latest/)
* sugar.sh : downloads and tests the translations of [Sugar Labs on Fedora](https://spins.fedoraproject.org/soas/)
* udisks2.sh : downloads and tests the translations of [udisks2](http://www.freedesktop.org/wiki/Software/udisks/)
* XFCE.sh : downloads and tests the translations of [xfce](http://www.xfce.org/)
* yumex.sh : downloads and tests the translations of [yumex](http://www.yumex.dk/)
* yumex-dnf.sh : downloads and tests the translations of [yumex-dnf](http://www.yumex.dk/)
* zif.sh : downloads and tests the translations of [ZIF](https://people.freedesktop.org/~hughsient/zif/). It's now a dead project.

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
   --disable-wordlist    Do not use wordlist file (requires -r)
   -i, --install         Install translations
   -h, --help            Display this help and exit

[1] https://fedora.zanata.org/version-group/view/main
```


```
./fedora-main.sh -l=ca -r -i --disable-wordlist
```


```
./fedora-main.sh -l=ca -r -i
```


```
./fedora-main.sh -l=ca -r --disable-wordlist
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

