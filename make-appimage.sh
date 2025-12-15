#!/bin/sh

set -eu

ARCH=$(uname -m)
VERSION=$(pacman -Q discord | awk '{print $2; exit}') # example command to get version of application here
VERSION=${VERSION#*:}
export ARCH VERSION
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook:fix-namespaces.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DEPLOY_PULSE=1
export DEPLOY_OPENGL=1
export DEPLOY_VULKAN=1

# Deploy dependencies
quick-sharun \
	./AppDir/bin/* \
	/usr/lib/libappindicator3.so*

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage
