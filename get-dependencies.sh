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

sed -i -e 's|/usr/bin/discord|Discord|g' /usr/share/applications/discord.desktop

mkdir -p ./AppDir/bin

# discord arch package now downloads the electron bundle in the user's home
# the bootstrap script will downlaod discord and attempt to execute it which will fail
/usr/bin/discord || :

discord_exe=$(find "${XDG_CONFIG_HOME:-$HOME/.config}"/discord -type f -name Discord -print -quit)
if [ ! -x "$discord_exe" ]; then
	>&2 echo "Cannot find discord, download failed?"
	exit 1
fi
discord_dir=${discord_exe%/*}
mv -v "$discord_dir"/* ./AppDir/bin

