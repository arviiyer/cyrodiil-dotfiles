#!/usr/bin/env bash

set -euo pipefail

action=${1:-}
marker=${XDG_RUNTIME_DIR:-/tmp}/cyrodiil-brightness-$(id -u)

case $action in
    dim)
        value=$(brightnessctl -m 2>/dev/null | awk -F, 'NR == 1 { gsub("%", "", $4); print $4 }')
        [[ $value =~ ^[0-9]+$ ]] || exit 0
        if ((value > 20)); then
            brightnessctl -q -s set 20%
            : > "$marker"
        fi
        ;;
    restore)
        [[ -f $marker ]] || exit 0
        brightnessctl -q -r 2>/dev/null || true
        rm -f -- "$marker"
        ;;
    *)
        printf 'Usage: %s {dim|restore}\n' "${0##*/}" >&2
        exit 2
        ;;
esac
