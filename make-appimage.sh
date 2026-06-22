#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q discord | awk '{print $2; exit}') # example command to get version of application here
VERSION=${VERSION#*:}
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook:fix-namespaces.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DESKTOP=/usr/share/applications/discord.desktop
export ICON=/usr/share/icons/hicolor/256x256/apps/discord.png
export DEPLOY_PULSE=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1

sed -i -e 's|/usr/bin/discord|Discord|g' /usr/share/applications/discord.desktop

# discord arch package now downloads the electron bundle in the user's home
# the bootstrap script will downlaod discord and attempt to execute it which will fail
/usr/bin/discord || :

discord_exe=$(find "${XDG_CONFIG_HOME:-$HOME/.config}"/discord -type f -name Discord -print -quit)
if [ ! -x "$discord_exe" ]; then
	>&2 echo "Cannot find discord, download failed?"
	exit 1
fi
discord_dir=${discord_exe%/*}

# Deploy dependencies
quick-sharun \
	"$discord_dir"/* \
	/usr/bin/jq      \
	/usr/lib/libappindicator3.so*

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage

# Test the app for 12 seconds, if the app normally quits before that time
# then skip this or check if some flag can be passed that makes it stay open
quick-sharun --simple-test ./dist/*.AppImage
