#!/bin/sh

set -eu

ARCH=$(uname -m)

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm brotli discord libappindicator-gtk3 jq

if [ "$ARCH" = 'x86_64' ]; then
	pacman -Syu --noconfirm libva-intel-driver
fi

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common --prefer-nano

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

sed -i -e 's|/usr/bin/discord|Discord|g' /usr/share/applications/discord.desktop

mkdir -p ./AppDir/bin

# Download Discord's full distribution directly from Discord's CDN
# (same approach as NixOS: pkgs/applications/networking/instant-messengers/discord/)
MANIFEST_URL="https://updates.discord.com/distributions/app/manifests/latest?channel=stable&platform=linux&arch=x64"
MANIFEST=$(wget --header="User-Agent: Discord-Updater/1" "$MANIFEST_URL" -O -)

# Main distro: brotli-compressed tar, all files under a files/ prefix
echo "Downloading Discord main distro..."
wget --header="User-Agent: Discord-Updater/1" \
	"$(echo "$MANIFEST" | jq -r '.full.url')" \
	-O - \
	| brotli -d | tar xf - --strip-components=1 -C ./AppDir/bin

# The 1.0.170 bootstrap only registers the module paths the updater installs
# into the (read-only inside the AppImage) mount, the legacy
# ~/.config/discord/<version>/modules lookup is gone. Ship the modules as the
# bootstrap's own standalone modules and turn the updater off, so the modules
# are loaded straight from the AppImage.
echo "Disabling the Discord updater..."
jq '.disableUpdater = true | .standaloneModules = true' \
	./AppDir/bin/resources/build_info.json \
	> "${TMPDIR:-/tmp}"/discord-build_info.json
mv "${TMPDIR:-/tmp}"/discord-build_info.json ./AppDir/bin/resources/build_info.json

echo "Downloading native modules..."
MODULES_DIR=./AppDir/bin/resources/standalone_modules
mkdir -p "$MODULES_DIR"

TMP_MODS=${TMPDIR:-/tmp}/discord-modules
rm -rf "$TMP_MODS"
mkdir -p "$TMP_MODS"

for mod in discord_desktop_core discord_erlpack discord_spellcheck discord_utils discord_voice discord_zstd discord_game_utils discord_krisp discord_rpc; do
	mod_url=$(echo "$MANIFEST" | jq -r ".modules.\"$mod\".full.url")
	mkdir -p "$TMP_MODS"/"$mod"
	wget --header="User-Agent: Discord-Updater/1" "$mod_url" -O - \
		| brotli -d | tar xf - --strip-components=1 -C "$TMP_MODS"/"$mod"
	mv "$TMP_MODS"/"$mod" "$MODULES_DIR"/"$mod"
done
rm -rf "$TMP_MODS"

# Krisp fails to initialize if its KMS/logs directory is missing (or if it
# cannot be created). Pre-create it, matching what Flathub does.
mkdir -p "$MODULES_DIR"/discord_krisp/KMS/logs
