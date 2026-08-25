#!/usr/bin/env bash

set -euo pipefail

if command -v waypaper >/dev/null; then
    exec waypaper
fi

notify-send "Wallpaper picker" "Install the optional Waypaper package with ./install.sh --with-aur"
