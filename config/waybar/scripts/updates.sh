#!/usr/bin/env bash
# Count pending updates — output nothing if up to date (hides waybar module)

official=$(checkupdates 2>/dev/null | wc -l)
total=$official

[ "$total" -eq 0 ] && exit 0

echo "{\"text\": \"󰮯 ${total}\", \"tooltip\": \"${total} official updates pending\", \"class\": \"has-updates\"}"
