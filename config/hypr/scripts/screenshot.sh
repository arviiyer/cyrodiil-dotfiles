#!/usr/bin/env bash
# Screenshot helper — uses grim + slurp
# Usage: screenshot.sh [--full] [--area]
#   default / no flag: region select with slurp
#   --full: instant full screen
#   --area: select an area (same as the default)

PICTURES_DIR=$(xdg-user-dir PICTURES 2>/dev/null || true)
PICTURES_DIR=${PICTURES_DIR:-$HOME/Pictures}
SAVEDIR="$PICTURES_DIR/Screenshots"
mkdir -p "$SAVEDIR"
FILENAME="$SAVEDIR/$(date +%Y-%m-%d_%H-%M-%S).png"
captured=false

case "$1" in
    --full)
        grim "$FILENAME" && captured=true
        ;;
    --area)
        geometry=$(slurp) || exit 0
        grim -g "$geometry" "$FILENAME" && captured=true
        ;;
    *)
        geometry=$(slurp) || exit 0
        grim -g "$geometry" "$FILENAME" && captured=true
        ;;
esac

if $captured; then
    notify-send "Screenshot" "Saved to $FILENAME" -t 2000
    wl-copy < "$FILENAME"
fi
