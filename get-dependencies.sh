#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm discord libappindicator-gtk3 jq

if [ "$ARCH" = 'x86_64' ]; then
	pacman -Syu --noconfirm libva-intel-driver
fi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano intel-media-driver-mini

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

mkdir -p ./AppDir/bin
cp -rv /opt/discord/*               ./AppDir/bin
cp -v  /opt/discord/discord.desktop ./AppDir
cp -v  /opt/discord/discord.png     ./AppDir/.DirIcon

sed -i -e 's|/usr/bin/discord|Discord|g' ./AppDir/discord.desktop
