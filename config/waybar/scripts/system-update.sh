#!/usr/bin/env bash
# Cyrodiil system update

set -euo pipefail

separator() {
    echo ""
    echo "─────────────────────────────────────────────"
    echo "  $1"
    echo "─────────────────────────────────────────────"
    echo ""
}

separator "Updating official and AUR packages"
paru -Syu --nodevel

echo ""
echo "─────────────────────────────────────────────"
echo "  System update complete."
echo "─────────────────────────────────────────────"
echo ""

# Refresh waybar so the update icon disappears immediately
pkill -SIGUSR2 waybar

read -r -p "Press Enter to close..."
