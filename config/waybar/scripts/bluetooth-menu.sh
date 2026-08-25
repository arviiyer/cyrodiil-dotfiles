#!/usr/bin/env bash

set -euo pipefail

if command -v blueman-manager >/dev/null; then
    exec blueman-manager
fi

if command -v blueberry >/dev/null; then
    exec blueberry
fi

notify-send "Bluetooth" "No supported Bluetooth manager is installed"
