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
get-debloated-pkgs --add-common --prefer-nano intel-media-driver-mini

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

# Download native modules into the AppImage itself (like NixOS)
# Discord loads these .node addons at runtime via require() from
# ~/.config/discord/<version>/modules/ -- the hook symlinks them there
echo "Downloading native modules..."
MODULES_DIR=./AppDir/bin/modules
mkdir -p "$MODULES_DIR"

TMP_MODS=/tmp/discord-modules
rm -rf "$TMP_MODS"
mkdir -p "$TMP_MODS"
INSTALLED_JSON='{}'

for mod in discord_desktop_core discord_erlpack discord_spellcheck discord_utils discord_voice discord_zstd; do
	mod_url=$(echo "$MANIFEST" | jq -r ".modules.\"$mod\".full.url")
	mod_ver=$(echo "$MANIFEST" | jq -r ".modules.\"$mod\".full.module_version")
	mkdir -p "$TMP_MODS"/"$mod"
	wget --header="User-Agent: Discord-Updater/1" "$mod_url" -O - \
		| brotli -d | tar xf - --strip-components=1 -C "$TMP_MODS"/"$mod"
	mv "$TMP_MODS"/"$mod" "$MODULES_DIR"/"$mod"
	INSTALLED_JSON=$(echo "$INSTALLED_JSON" \
		| jq --arg k "$mod" --arg v "$mod_ver" '.[$k] = {"installedVersion": ($v | tonumber)}')
done
rm -rf "$TMP_MODS"

# Write installed.json so the hook can copy it into Discord's config dir
echo "$INSTALLED_JSON" > "$MODULES_DIR"/installed.json
