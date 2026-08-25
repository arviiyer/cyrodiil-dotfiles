#!/usr/bin/env bash

set -uo pipefail

socket="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
mode=

set_mode() {
    local next_mode=$1

    [[ $next_mode == "$mode" ]] && return

    if [[ $next_mode == enabled ]]; then
        hyprctl --batch 'keyword input:scroll_method on_button_down; keyword input:scroll_button 274; keyword input:scroll_button_lock true' >/dev/null
    else
        hyprctl --batch 'keyword input:scroll_method 2fg; keyword input:scroll_button 0; keyword input:scroll_button_lock false' >/dev/null
    fi

    mode=$next_mode
}

set_mode_for_class() {
    case ${1,,} in
        nautilus|org.gnome.nautilus|okular|org.kde.okular|libreoffice*|soffice)
            set_mode enabled
            ;;
        *)
            set_mode disabled
            ;;
    esac
}

trap 'set_mode disabled' EXIT

set_mode_for_class "$(hyprctl activewindow -j | jq -r '.class // ""')"

while IFS= read -r event; do
    case $event in
        activewindow\>\>*)
            window=${event#activewindow>>}
            set_mode_for_class "${window%%,*}"
            ;;
    esac
done < <(nc -U "$socket")
