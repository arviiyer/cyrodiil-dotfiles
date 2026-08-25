#!/bin/bash
# Toggle gsimplecal, positioned below the waybar clock (top center)

if pgrep -x gsimplecal > /dev/null; then
    pkill gsimplecal
    exit 0
fi

gsimplecal &

# Wait until hyprctl can see the window (up to 1s)
for _ in {1..20}; do
    sleep 0.05
    WIN_W=$(hyprctl clients -j 2>/dev/null | jq -r '.[] | select(.class=="gsimplecal") | .size[0]' | head -1)
    [ -n "$WIN_W" ] && [ "$WIN_W" -gt 0 ] && break
done

[ -z "$WIN_W" ] || [ "$WIN_W" -eq 0 ] && WIN_W=325

# Logical monitor width
MON_W=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0] | (.width / .scale)' | awk '{print int($1)}')
[ -z "$MON_W" ] && MON_W=1600

# Center horizontally, just below waybar (36px height + 6px margin-top + ~12px gap)
X=$(( (MON_W - WIN_W) / 2 ))
Y=54

hyprctl dispatch movewindowpixel "exact ${X} ${Y},class:gsimplecal" 2>/dev/null
