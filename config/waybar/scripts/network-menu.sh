#!/usr/bin/env bash

set -euo pipefail

if command -v nmtui >/dev/null; then
    exec ghostty -e nmtui
fi

if command -v iwctl >/dev/null; then
    exec ghostty -e iwctl
fi

notify-send "Network" "No supported terminal network manager is installed"
