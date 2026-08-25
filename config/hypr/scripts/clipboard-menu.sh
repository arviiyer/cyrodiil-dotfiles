#!/usr/bin/env bash

set -euo pipefail

if ! command -v cliphist >/dev/null; then
    notify-send "Clipboard history" "Enable it with ./install.sh --with-clipboard"
    exit 0
fi

selection=$(cliphist list | rofi -dmenu -p "Clipboard")
[[ -n $selection ]] || exit 0
cliphist decode <<< "$selection" | wl-copy
