#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
cd "$ROOT"

bash -n install.sh restore.sh config/hypr/scripts/*.sh config/waybar/scripts/*.sh

if command -v shellcheck >/dev/null; then
    shellcheck install.sh restore.sh scripts/validate.sh \
        config/hypr/scripts/*.sh config/waybar/scripts/*.sh
else
    printf 'warn: shellcheck is not installed; skipping it\n' >&2
fi

if command -v zsh >/dev/null; then
    zsh -n home/.zshrc
fi

if command -v jq >/dev/null; then
    jq empty config/swaync/config.json
    grep -vE '^[[:space:]]*//' config/waybar/config.jsonc | jq empty
fi

python - <<'PY'
import configparser
import pathlib
import tomllib

root = pathlib.Path.cwd()

with (root / "system/greetd/config.toml").open("rb") as stream:
    tomllib.load(stream)

for path in (
    root / "config/waypaper/config.ini",
    root / "config/gtk-3.0/settings.ini",
    root / "config/gtk-4.0/settings.ini",
):
    parser = configparser.ConfigParser()
    with path.open(encoding="utf-8") as stream:
        parser.read_file(stream)
PY

wallpaper_blob=$(git hash-object --no-filters assets/wallpapers/autumns.hues.png)
[[ $wallpaper_blob == 12c83ce734b7bc01ed8869fec5921f27c36ed427 ]]

license_blob=$(git hash-object --no-filters assets/wallpapers/LICENSE.GPL-2.0)
[[ $license_blob == ce5dccf2cfeb934f88fe9a917342e54519813145 ]]

if command -v Hyprland >/dev/null; then
    Hyprland --verify-config --config "$ROOT/config/hypr/hyprland.lua"
fi

printf 'Validation passed.\n'
