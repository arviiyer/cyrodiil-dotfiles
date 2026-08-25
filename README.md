# Cyrodiil Dotfiles

A warm, earthy Hyprland desktop for Arch Linux and Arch-based distributions.
It provides a complete compositor, bar, launcher, notifications, lock screen,
wallpaper workflow, terminal, and optional shell and application styling.

The installer is designed to add Hyprland alongside an existing desktop. It
does not replace the current display manager, audio stack, network manager,
Bluetooth stack, login shell, GTK theme, or Firefox profile unless the user
explicitly chooses that component.

## What You Get

- Hyprland 0.56 or newer with a modular Lua configuration
- Waybar with workspaces, updates, audio, network, battery, and system stats
- SwayNotificationCenter notifications
- Rofi launcher, calculator, clipboard menu, and power menu
- Ghostty with a matching warm palette
- Hyprlock, Hypridle, screenshots, and a blue-light filter
- Automatic monitor layout with a local override file
- Safe fallbacks for missing batteries, brightness controls, Bluetooth, and Waypaper
- Optional GTK, Firefox, cursor, Zsh, clipboard, PipeWire, and greetd integration
- The `autumns.hues.png` wallpaper that inspired the palette

## Supported Systems

The installer targets Arch Linux and distributions with `ID_LIKE=arch`, such
as CachyOS and EndeavourOS. Packages must be available under their standard
Arch names, and the installed Hyprland version must support Lua configuration.

The installer never replaces graphics drivers, kernels, boot configuration,
or distribution-specific hardware settings.

## Quick Start

Install Git and clone the repository:

```bash
sudo pacman -S --needed git
git clone https://github.com/arviiyer/cyrodiil-dotfiles.git
cd cyrodiil-dotfiles
```

Review the safe default installation:

```bash
./install.sh --dry-run --yes
```

Start the guided installer to choose optional components:

```bash
./install.sh
```

Do not use `sudo ./install.sh`. The script requests sudo only for package or
display-manager changes.

## Safe Defaults

The non-interactive command below installs and deploys the Hyprland desktop but
leaves optional integration disabled:

```bash
./install.sh --yes
```

It preserves:

- The current display manager
- The current audio and network stacks
- Bluetooth packages and service state
- GTK settings used by another desktop environment
- The login shell and existing `.zshrc`
- Firefox profile customization
- Existing default browser and file manager choices
- Clipboard privacy

Log out after installation and select Hyprland from the current login manager.

## Installer Options

```text
--dry-run              Show changes without making them
--yes                  Accept required confirmations without opting into extras
--no-packages          Skip pacman and AUR package installation
--with-aur             Install Waypaper and appearance packages from AUR
--no-aur               Do not install AUR packages
--aur-helper NAME      Use an existing AUR helper, such as paru or yay
--with-global-theme    Apply GTK and cursor settings outside Hyprland
--with-shell           Install Zsh config and offer to make Zsh the login shell
--with-firefox         Install Firefox userChrome styling
--with-clipboard       Enable persistent clipboard history with cliphist
--without-clipboard    Disable persistent clipboard history
--with-pipewire        Install PipeWire, pipewire-pulse, and WirePlumber
--without-pipewire     Preserve the current audio stack
--with-bluetooth       Install BlueZ and Blueman
--with-networkmanager  Install NetworkManager for the Waybar network menu
--enable-greetd        Replace the current display manager with greetd next boot
--full                 Enable visual, shell, Firefox, and clipboard extras
```

`--full` does not enable greetd, replace an existing audio stack, or install a
new network manager. Those remain separate decisions.

For a setup close to the original CachyOS desktop:

```bash
./install.sh --full --with-pipewire --with-bluetooth --with-networkmanager
```

Add `--enable-greetd` only if the current display manager should be replaced.

## Packages And AUR Helpers

Official packages are split by component under `packages/`. The core list is
`packages/pacman.txt`. Optional lists are loaded only when their corresponding
installer option is selected.

Waypaper and the Gruvbox/Bibata appearance packages are listed in
`packages/aur.txt`. When `--with-aur` is selected, the installer:

1. Uses the requested helper from `--aur-helper`, if provided.
2. Otherwise uses an existing `paru` or `yay`.
3. Installs `paru` from configured repositories when the distribution provides it.
4. On plain Arch, asks before building `paru` from its official AUR Git repository.

Use `--no-aur` to avoid all AUR operations. The default wallpaper still works
through `awww`; only the Waypaper picker and optional themes are unavailable.

## Existing Configurations

Every managed target is backed up before being replaced. The installer links
complete component directories for Hyprland, Waybar, SwayNC, Rofi, Ghostty,
Gsimplecal, and Waypaper. Users with an existing configuration for one of those
components should inspect the dry run carefully.

Backups are stored under:

```text
~/.local/state/cyrodiil-dotfiles/backups/
```

Restore the latest file and service state with:

```bash
./restore.sh
```

`restore.sh` verifies every required backup before removing deployed files. It
restores display-manager enablement first, then files and the previous login
shell. Installed packages are not automatically removed.

## Display Managers And Greetd

By default, SDDM, GDM, LightDM, Ly, greetd, and other display managers are left
unchanged. The Hyprland package installs a session entry that most display
managers discover automatically.

`--enable-greetd` is an advanced opt-in. The installer detects the current
`display-manager.service`, records its unit and state, disables only that unit,
and enables greetd for the next boot. The previous display manager remains
installed.

Tuigreet lists installed Wayland sessions. X11 sessions are intentionally not
listed because their startup requirements vary between systems.

If graphical login fails, switch to a TTY with `Ctrl+Alt+F3`, log in, and run:

```bash
cd ~/cyrodiil-dotfiles
./restore.sh
sudo reboot
```

## Optional Privacy Features

Clipboard history is disabled by default because it can retain copied secrets.
Enable it with `--with-clipboard`. The generated
`config/hypr/options.lua` records this choice and is ignored by Git. Noninteractive
installer reruns preserve the recorded choice; use `--without-clipboard` to turn
it off explicitly.

The context-sensitive middle-click autoscroll helper is also disabled by
default. Advanced users can enable it in `config/hypr/local.lua`:

```lua
cyrodiil_options.context_autoscroll = true
```

## Keybindings

| Keys | Action |
| --- | --- |
| `Super+Enter` | Open Ghostty |
| `Super+B` | Open the default browser |
| `Super+E` | Open the home folder in the default file manager |
| `Super+Ctrl+Enter` | Open Rofi |
| `Super+Ctrl+E` | Open calculator |
| `Super+V` | Open clipboard history |
| `Super+C` | Toggle calendar |
| `Super+Ctrl+P` | Open power menu |
| `Super+Shift+W` | Open Waypaper when installed |
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

## Monitor, Input, And GPU Overrides

The public configuration uses preferred monitor modes, automatic placement,
automatic scaling, and standard libinput defaults. It does not force a keyboard
layout, touchpad behavior, pointer acceleration profile, or raw hardware keycodes.

After logging into Hyprland, inspect outputs:

```bash
hyprctl monitors
```

Copy the local example and add exact declarations or input preferences:

```bash
cp ~/.config/hypr/local.lua.example ~/.config/hypr/local.lua
```

```lua
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 1.5 })
hl.monitor({ output = "DP-1", mode = "preferred", position = "1920x0", scale = 1 })
```

NVIDIA workarounds are documented in `local.lua.example` but are not enabled by
PCI-device detection. This avoids applying NVIDIA VA-API settings to hybrid,
Nouveau, NVK, AMD, or Intel-driven sessions.

Apply changes with:

```bash
hyprctl reload
hyprctl configerrors
```

## Firefox

Firefox customization is opt-in with `--with-firefox`. Firefox must have been
launched once so `profiles.ini` and a profile directory exist. The installer
detects the install-selected default profile before linking `userChrome.css`
and `user.js`.

## Updating

Pull changes and rerun the installer. Correct links are skipped:

```bash
git pull
./install.sh --yes
```

The Waybar update action uses `paru`, then `yay`, and finally `pacman`, depending
on what is installed. It does not remove orphaned packages, clear caches, or
vacuum the journal.

## Validation

Run repository checks with:

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
