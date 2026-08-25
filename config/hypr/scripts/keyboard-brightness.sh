#!/usr/bin/env bash

set -euo pipefail

direction=${1:-}
device=$(brightnessctl --list --class=leds | awk -F\' '/^Device / && $2 ~ /(kbd|keyboard)_backlight/ { print $2; exit }')

if [[ -z $device ]]; then
    notify-send "Keyboard brightness" "No keyboard backlight device was detected"
    exit 1
fi

case $direction in
    up) brightnessctl --quiet --device="$device" set +1 ;;
    down) brightnessctl --quiet --device="$device" set 1- ;;
    *) printf 'Usage: %s {up|down}\n' "${0##*/}" >&2; exit 2 ;;
esac
