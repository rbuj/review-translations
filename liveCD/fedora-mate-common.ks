%packages
-PackageKit*                # we switched to dnfdragora, so we don't need this
firefox
@mate
compiz
compiz-plugins-main
compiz-plugins-extra
compiz-manager
compizconfig-python
compiz-plugins-experimental
libcompizconfig
compiz-plugins-main
ccsm
simple-ccsm
emerald-themes
emerald
fusion-icon
@networkmanager-submodules
blueberry

# some apps from mate-applications
caja-actions
mate-disk-usage-analyzer

# system tools
system-config-printer
system-config-printer-applet
lightdm-gtk-greeter-settings

# audio video
parole
exaile
gstreamer1-plugins-ugly-free # mp3 support

# blacklist applications which breaks mate-desktop
-audacious

# office
@libreoffice

# dsl tools
rp-pppoe

# some tools
p7zip
p7zip-plugins

# FIXME; apparently the glibc maintainers dislike this, but it got put into the
# desktop image at some point.  We won't touch this one for now.
nss-mdns

# Drop things for size
-@3d-printing
-brasero
-colord
-fedora-icon-theme
-gnome-icon-theme
-gnome-icon-theme-symbolic
-gnome-software
-gnome-user-docs

-@mate-applications
-mate-icon-theme-faenza

# Help and art can be big, too
-gnome-user-docs
-evolution-help

# Legacy cmdline things we don't want
-telnet

%end
