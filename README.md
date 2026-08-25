# Cyrodiil Dotfiles

A warm, earthy Hyprland desktop for CachyOS and Arch-based systems. It keeps
the setup small and explicit while providing a complete bar, launcher,
notifications, lock screen, wallpaper workflow, terminal, and shell theme.

## What You Get

- Hyprland with a modular Lua configuration
- Waybar with workspaces, updates, audio, network, battery, and system stats
- SwayNotificationCenter notifications
- Rofi launcher, calculator, clipboard menu, and power menu
- Ghostty and Zsh with a matching warm palette
- Hyprlock, Hypridle, screenshots, and a blue-light filter
- GTK3, GTK4, Firefox, cursor, icon, and Waypaper styling
- The `autumns.hues.png` wallpaper that inspired the palette
- Portable NVIDIA, AMD, and Intel behavior without changing graphics drivers

## Before Installing

This installer is intended for CachyOS or another Arch-based installation. It
can replace SDDM with greetd, but it does not uninstall SDDM or Plasma. Plasma
remains available as a fallback session from tuigreet.

The installer does not replace kernels, graphics drivers, or CachyOS hardware
configuration. Existing configuration is backed up before it is replaced.

Install Git and clone the repository:

```bash
sudo pacman -S --needed git
git clone https://github.com/arviiyer/cyrodiil-dotfiles.git
cd cyrodiil-dotfiles
```

Review the proposed changes first:

```bash
./install.sh --dry-run
```

Then start the guided installation:

```bash
./install.sh
```

Do not use `sudo ./install.sh`. The script asks for sudo only when pacman or a
system service needs it.

## Installer Options

```text
--dry-run         Show changes without making them
--yes             Accept installer prompts
--no-packages     Skip pacman and AUR package installation
--skip-firefox    Do not modify a Firefox profile
--skip-greetd     Keep the current display manager
```

Packages from the official repositories are listed in `packages/pacman.txt`.
The three visual-theme packages installed through paru are listed in
`packages/aur.txt`.

## First Login

The installer never stops the current desktop and never reboots automatically.
After it finishes, reboot when you are ready. Tuigreet remembers the selected
user and session. Choose Hyprland for this setup or Plasma for the existing KDE
desktop.

If the Hyprland session opens, the default wallpaper, Waybar, notifications,
clipboard history, idle handling, and polkit agent start automatically.

## Emergency Recovery

If greetd or Hyprland does not start, press `Ctrl+Alt+F3`, log in, and restore
SDDM:

```bash
sudo systemctl disable greetd
sudo systemctl enable sddm
sudo reboot
```

You can also restore all files changed by the installer:

```bash
cd ~/cyrodiil-dotfiles
./restore.sh
```

Backups are stored under:

```text
~/.local/state/cyrodiil-dotfiles/backups/
```

`restore.sh` uses the latest backup by default. A specific backup can be
provided as its first argument.

## Keybindings

| Keys | Action |
| --- | --- |
| `Super+Enter` | Open Ghostty |
| `Super+B` | Open Firefox |
| `Super+E` | Open Nautilus |
| `Super+Ctrl+Enter` | Open Rofi |
| `Super+Ctrl+E` | Open calculator |
| `Super+V` | Open clipboard history |
| `Super+C` | Toggle calendar |
| `Super+Ctrl+P` | Open power menu |
| `Super+Shift+W` | Open Waypaper |
| `Super+Q` | Close window |
| `Super+F` | Fullscreen window |
| `Super+M` | Maximize window |
| `Super+T` | Toggle floating |
| `Super+1` through `Super+0` | Change workspace |
| `Super+Shift+1` through `Super+Shift+0` | Move window to workspace |
| `Super+Print` | Select screenshot area |
| `Super+Alt+F` | Full screenshot |
| `Super+Shift+H` | Toggle blue-light filter |
| `Super+Ctrl+L` | Lock screen |

The complete list is in `config/hypr/keybinds.lua`.

## Monitor Setup

The public configuration starts with a safe automatic layout. After logging
into Hyprland, inspect available outputs:

```bash
hyprctl monitors
```

Add exact declarations to `~/.config/hypr/local.lua`. This file is generated
by the installer and ignored by Git:

```lua
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.5 })
hl.monitor({ output = "DP-1", mode = "preferred", position = "1920x0", scale = 1 })
```

Apply changes with:

```bash
hyprctl reload
hyprctl configerrors
```

NVIDIA-specific environment and cursor settings are added to `local.lua` only
when an NVIDIA GPU is detected. Driver installation remains managed by
CachyOS.

## Firefox

Firefox must have been launched once so that `profiles.ini` and a profile
directory exist. The installer detects Firefox's install-selected default
profile and offers to link `userChrome.css` and `user.js` into it.

If Firefox was not initialized during installation, launch it once and rerun:

```bash
./install.sh --no-packages --skip-greetd
```

## Updating

Pull changes and rerun the installer. Existing correct links are skipped:

```bash
git pull
./install.sh
```

The Waybar update button runs a normal `paru -Syu`. It does not remove orphaned
packages, clear caches, or vacuum the journal.

## Validation

Run the repository checks with:

```bash
./scripts/validate.sh
```

Inside Hyprland, also run:

```bash
hyprctl configerrors
```

## License

Original scripts and configuration are available under the MIT license. The
bundled wallpaper remains under its upstream GPL-2.0 license. See
`THIRD_PARTY_NOTICES.md` for its source, integrity hashes, and attribution.
