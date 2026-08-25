#!/usr/bin/env bash
# Screenshot helper — uses grim + slurp
# Usage: screenshot.sh [--full] [--area]
#   default / no flag: region select with slurp
#   --full: instant full screen
#   --area: select an area (same as the default)

SAVEDIR="$HOME/Pictures/Screenshots"
mkdir -p "$SAVEDIR"
FILENAME="$SAVEDIR/$(date +%Y-%m-%d_%H-%M-%S).png"

case "$1" in
    --full)
        grim "$FILENAME" && notify-send "Screenshot" "Saved to $FILENAME" -t 2000
        ;;
    --area)
        grim -g "$(slurp)" "$FILENAME" && notify-send "Screenshot" "Saved to $FILENAME" -t 2000
        ;;
    *)
        grim -g "$(slurp)" "$FILENAME" && notify-send "Screenshot" "Saved to $FILENAME" -t 2000
        ;;
esac

# Copy to clipboard as well
wl-copy < "$FILENAME"
