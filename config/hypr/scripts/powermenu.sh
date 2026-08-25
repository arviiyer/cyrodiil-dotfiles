#!/usr/bin/env bash
# Power menu via rofi

chosen=$(printf "󰌾  Lock\n󰒲  Sleep\n󰜉  Restart\n󰐥  Shutdown" | rofi -dmenu \
    -theme ~/.config/rofi/theme.rasi \
    -theme-str 'window { width: 220px; anchor: north east; location: north east; x-offset: -12; y-offset: 6; } listview { lines: 4; } inputbar { enabled: false; } element.normal.normal { text-color: #d4c5b0; }')

case "$chosen" in
    *Lock)     pidof hyprlock || hyprlock ;;
    *Sleep)    systemctl suspend ;;
    *Restart)  systemctl reboot ;;
    *Shutdown) systemctl poweroff ;;
esac
