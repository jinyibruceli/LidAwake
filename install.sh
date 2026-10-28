#!/bin/bash
# One-line installer: downloads the latest LidAwake release into ~/Applications and starts it.
set -e
TMP=$(mktemp -d)
curl -fsSL https://github.com/jinyibruceli/LidAwake/releases/latest/download/LidAwake.zip -o "$TMP/LidAwake.zip"
mkdir -p "$HOME/Applications"
# stop a running copy so the new version takes over
launchctl bootout "gui/$(id -u)/com.lidawake.agent" 2>/dev/null || true
rm -rf "$HOME/Applications/LidAwake.app"
ditto -x -k "$TMP/LidAwake.zip" "$HOME/Applications"
rm -rf "$TMP"
open "$HOME/Applications/LidAwake.app"
echo "LidAwake is in your menu bar now. / LidAwake 已经出现在菜单栏。"
