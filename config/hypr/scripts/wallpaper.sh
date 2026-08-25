#!/usr/bin/env bash

set -euo pipefail

wallpaper="$HOME/.local/share/cyrodiil/wallpapers/autumns.hues.png"

if ! pgrep -x awww-daemon >/dev/null; then
    awww-daemon >/dev/null 2>&1 &
fi

for _ in {1..20}; do
    awww query >/dev/null 2>&1 && break
    sleep 0.1
done

waypaper --restore >/dev/null 2>&1 || waypaper --backend awww --wallpaper "$wallpaper" >/dev/null 2>&1
