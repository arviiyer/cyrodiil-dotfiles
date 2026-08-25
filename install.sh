#!/usr/bin/env bash

set -Eeuo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}/cyrodiil-dotfiles
TIMESTAMP=$(date +%Y%m%d_%H%M%S_%N)
BACKUP_DIR=$STATE_HOME/backups/$TIMESTAMP
MANIFEST=$BACKUP_DIR/manifest.tsv

DRY_RUN=false
ASSUME_YES=false
INSTALL_PACKAGES=true
WITH_AUR=false
WITH_GLOBAL_THEME=false
WITH_SHELL=false
WITH_FIREFOX=false
WITH_CLIPBOARD=false
WITH_PIPEWIRE=auto
WITH_BLUETOOTH=false
WITH_NETWORKMANAGER=false
ENABLE_GREETD=false
AUR_HELPER=
BACKUP_READY=false
AUR_DENIED=false

AUR_SET=false
GLOBAL_THEME_SET=false
SHELL_SET=false
FIREFOX_SET=false
CLIPBOARD_SET=false
BLUETOOTH_SET=false
NETWORKMANAGER_SET=false

usage() {
    cat <<'EOF'
Usage: ./install.sh [options]

Options:
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
  -h, --help             Show this help
EOF
}

info() {
    printf '\033[1;34m==>\033[0m %s\n' "$*"
}

success() {
    printf '\033[1;32m ok\033[0m %s\n' "$*"
}

warn() {
    printf '\033[1;33mwarn\033[0m %s\n' "$*" >&2
}

remember_latest_backup() {
    $BACKUP_READY || return 0
    mkdir -p "$STATE_HOME"
    ln -sfn "$BACKUP_DIR" "$STATE_HOME/latest"
}

die() {
    printf '\033[1;31merror\033[0m %s\n' "$*" >&2
    if $BACKUP_READY; then
        remember_latest_backup
        warn "Restore completed changes with: $ROOT/restore.sh $BACKUP_DIR"
    fi
    exit 1
}

print_command() {
    printf '    '
    printf '%q ' "$@"
    printf '\n'
}

run() {
    if $DRY_RUN; then
        print_command "$@"
    else
        "$@"
    fi
}

confirm() {
    local prompt=$1
    local default=${2:-yes}
    local answer

    $ASSUME_YES && return 0

    if [[ $default == yes ]]; then
        read -r -p "$prompt [Y/n] " answer
        [[ -z $answer || $answer =~ ^[Yy]$ ]]
    else
        read -r -p "$prompt [y/N] " answer
        [[ $answer =~ ^[Yy]$ ]]
    fi
}

ensure_backup() {
    $BACKUP_READY && return
    mkdir -p "$BACKUP_DIR/files"
    chmod 700 "$BACKUP_DIR"
    : > "$MANIFEST"
    printf '%s\n' "$ROOT" > "$BACKUP_DIR/source-root"
    BACKUP_READY=true
}

on_error() {
    local status=$?
    trap - ERR
    remember_latest_backup
    warn "Installation stopped after an error."
    if $BACKUP_READY; then
        warn "Restore completed changes with: $ROOT/restore.sh $BACKUP_DIR"
    fi
    exit "$status"
}

trap on_error ERR

backup_user_target() {
    local target=$1
    local state=absent
    local backup=$BACKUP_DIR/files/${target#/}

    ensure_backup
    if [[ -e $target || -L $target ]]; then
        state=present
        mkdir -p "$(dirname -- "$backup")"
        cp -a --no-dereference -- "$target" "$backup"
    fi
    printf '%s\t%s\tuser\n' "$target" "$state" >> "$MANIFEST"
}

backup_system_target() {
    local target=$1
    local state=absent
    local backup=$BACKUP_DIR/files/${target#/}

    ensure_backup
    if sudo test -e "$target" || sudo test -L "$target"; then
        state=present
        mkdir -p "$(dirname -- "$backup")"
        sudo cp -a --no-dereference -- "$target" "$backup"
    fi
    printf '%s\t%s\tsystem\n' "$target" "$state" >> "$MANIFEST"
}

link_path() {
    local source=$1
    local target=$2

    [[ -e $source || -L $source ]] || die "Missing deployment source: $source"

    if [[ -L $target && $(readlink -- "$target") == "$source" ]]; then
        success " $target"
        return
    fi

    if $DRY_RUN; then
        printf ' link %s -> %s\n' "$target" "$source"
        return
    fi

    backup_user_target "$target"
    rm -rf -- "$target"
    mkdir -p "$(dirname -- "$target")"
    ln -s "$source" "$target"
    printf ' link %s -> %s\n' "$target" "$source"
}

install_system_file() {
    local source=$1
    local target=$2
    local mode=${3:-0644}

    [[ -f $source ]] || die "Missing system file: $source"

    if $DRY_RUN; then
        printf ' file %s <- %s\n' "$target" "$source"
        return
    fi

    backup_system_target "$target"
    sudo install -D -m "$mode" "$source" "$target"
    printf ' file %s <- %s\n' "$target" "$source"
}

load_package_file() {
    local file=$1
    local -n output=$2
    local package

    while IFS= read -r package || [[ -n $package ]]; do
        [[ -z $package || $package == \#* ]] && continue
        output+=("$package")
    done < "$file"
}

select_components() {
    if ! $ASSUME_YES; then
        if ! $AUR_SET; then
            if confirm "Install optional AUR appearance packages and Waypaper?" no; then
                WITH_AUR=true
            else
                WITH_AUR=false
            fi
        fi
        if $WITH_AUR && ! $GLOBAL_THEME_SET \
            && confirm "Apply the GTK and cursor theme to other desktop sessions too?" no; then
            WITH_GLOBAL_THEME=true
        fi
        if ! $SHELL_SET && confirm "Install the included Zsh configuration?" no; then
            WITH_SHELL=true
        fi
        if ! $FIREFOX_SET && confirm "Install Firefox userChrome styling?" no; then
            WITH_FIREFOX=true
        fi
        if ! $CLIPBOARD_SET; then
            if confirm "Enable persistent clipboard history?" no; then
                WITH_CLIPBOARD=true
            else
                WITH_CLIPBOARD=false
            fi
            CLIPBOARD_SET=true
        fi
        if ! $NETWORKMANAGER_SET && ! command -v nmtui >/dev/null \
            && confirm "Install NetworkManager for the Waybar network menu?" no; then
            WITH_NETWORKMANAGER=true
        fi
        if ! $BLUETOOTH_SET && ! command -v blueman-manager >/dev/null \
            && confirm "Install BlueZ and Blueman?" no; then
            WITH_BLUETOOTH=true
        fi
    fi

    if [[ $WITH_PIPEWIRE == auto ]]; then
        if command -v wpctl >/dev/null || pacman -Q pipewire-pulse >/dev/null 2>&1; then
            WITH_PIPEWIRE=false
        elif pacman -Q pulseaudio >/dev/null 2>&1; then
            warn "PulseAudio is installed; preserving the existing audio stack."
            WITH_PIPEWIRE=false
        elif ! $ASSUME_YES && confirm "No desktop audio stack was detected. Install PipeWire?" no; then
            WITH_PIPEWIRE=true
        else
            WITH_PIPEWIRE=false
        fi
    fi

    if $WITH_GLOBAL_THEME && ! $WITH_AUR; then
        warn "The global Gruvbox/Bibata theme needs the optional AUR packages; skipping global theming."
        WITH_GLOBAL_THEME=false
    fi
}

preflight_official_packages() {
    local package

    for package in "$@"; do
        pacman -Si "$package" >/dev/null 2>&1 \
            || die "Package '$package' is not available in configured repositories."
    done
}

bootstrap_paru() {
    local build_dir

    if $DRY_RUN; then
        printf ' build paru from https://aur.archlinux.org/paru.git\n'
        AUR_HELPER=paru
        return
    fi

    confirm "No AUR helper was found. Build paru from the AUR?" yes \
        || die "AUR packages were requested, but no helper is available."

    build_dir=$(mktemp -d)
    git clone https://aur.archlinux.org/paru.git "$build_dir/paru"
    (
        cd "$build_dir/paru"
        makepkg -si --needed
    )
    rm -rf -- "$build_dir"
    AUR_HELPER=paru
}

resolve_aur_helper() {
    local candidate

    if [[ -n $AUR_HELPER ]]; then
        [[ $AUR_HELPER == paru || $AUR_HELPER == yay ]] \
            || die "Supported AUR helpers are paru and yay."
        if $DRY_RUN || command -v "$AUR_HELPER" >/dev/null; then
            return
        fi
        die "Requested AUR helper '$AUR_HELPER' is not installed."
    fi

    for candidate in paru yay; do
        if command -v "$candidate" >/dev/null; then
            AUR_HELPER=$candidate
            return
        fi
    done

    if pacman -Si paru >/dev/null 2>&1; then
        info "Installing paru from the configured repositories"
        run sudo pacman -S --needed paru
        AUR_HELPER=paru
        return
    fi

    bootstrap_paru
}

install_packages() {
    local -a official=()
    local -a aur=()

    load_package_file "$ROOT/packages/pacman.txt" official
    $WITH_PIPEWIRE && load_package_file "$ROOT/packages/audio.txt" official
    $WITH_BLUETOOTH && load_package_file "$ROOT/packages/bluetooth.txt" official
    $WITH_CLIPBOARD && load_package_file "$ROOT/packages/clipboard.txt" official
    $ENABLE_GREETD && load_package_file "$ROOT/packages/greetd.txt" official
    $WITH_NETWORKMANAGER && load_package_file "$ROOT/packages/networkmanager.txt" official
    $WITH_SHELL && load_package_file "$ROOT/packages/shell.txt" official
    $WITH_FIREFOX && official+=(firefox)

    preflight_official_packages "${official[@]}"
    info "Installing official repository packages"
    run sudo pacman -S --needed "${official[@]}"

    $WITH_AUR || return 0
    load_package_file "$ROOT/packages/aur.txt" aur
    resolve_aur_helper
    info "Installing optional AUR packages with $AUR_HELPER"
    run "$AUR_HELPER" -S --needed "${aur[@]}"
}

generate_options_config() {
    local target=$ROOT/config/hypr/options.lua

    if $DRY_RUN; then
        printf ' file %s (generated feature options)\n' "$target"
        return
    fi

    backup_user_target "$target"
    rm -rf -- "$target"
    cat > "$target" <<EOF
-- Generated by install.sh; edit installer options instead of this file.
cyrodiil_options = {
    clipboard_history = $WITH_CLIPBOARD,
    context_autoscroll = false,
}
EOF
    printf ' file %s\n' "$target"
}

load_existing_options() {
    local target=$ROOT/config/hypr/options.lua

    if ! $CLIPBOARD_SET && [[ -f $target ]]; then
        if grep -Eq '^[[:space:]]*clipboard_history[[:space:]]*=[[:space:]]*true,?[[:space:]]*$' "$target"; then
            WITH_CLIPBOARD=true
        elif grep -Eq '^[[:space:]]*clipboard_history[[:space:]]*=[[:space:]]*false,?[[:space:]]*$' "$target"; then
            WITH_CLIPBOARD=false
        fi
    fi
}

find_firefox_profile() {
    local profiles=$HOME/.mozilla/firefox/profiles.ini
    local record
    local relative
    local path

    [[ -f $profiles ]] || return 1

    path=$(awk -F= '
        /^\[Install/ { install=1; next }
        /^\[/ { install=0 }
        install && $1 == "Default" { print $2; exit }
    ' "$profiles")
    if [[ -n $path ]]; then
        printf '%s\n' "$HOME/.mozilla/firefox/$path"
        return 0
    fi

    record=$(awk -F= '
        function emit() {
            if (section && path != "") {
                if (preferred == "1") print "0\t" relative "\t" path
                else if (name == "default-release") print "1\t" relative "\t" path
            }
        }
        /^\[Profile/ { emit(); section=1; name=""; path=""; preferred=""; relative="1"; next }
        /^\[/ { emit(); section=0; next }
        section && $1 == "Name" { name=$2 }
        section && $1 == "Path" { path=$2 }
        section && $1 == "Default" { preferred=$2 }
        section && $1 == "IsRelative" { relative=$2 }
        END { emit() }
    ' "$profiles" | sort -t $'\t' -k1,1 | head -n 1)

    [[ -n $record ]] || return 1
    IFS=$'\t' read -r _ relative path <<< "$record"

    if [[ $relative == 0 ]]; then
        printf '%s\n' "$path"
    else
        printf '%s\n' "$HOME/.mozilla/firefox/$path"
    fi
}

deploy_files() {
    local name
    local firefox_profile
    local -a config_dirs=(
        ghostty
        gsimplecal
        hypr
        rofi
        swaync
        waybar
        waypaper
    )

    info "Deploying Hyprland desktop configuration"
    for name in "${config_dirs[@]}"; do
        link_path "$ROOT/config/$name" "$HOME/.config/$name"
    done

    link_path "$ROOT/config/xdg-desktop-portal/hyprland-portals.conf" \
        "$HOME/.config/xdg-desktop-portal/hyprland-portals.conf"
    link_path "$ROOT/assets/wallpapers/autumns.hues.png" \
        "$HOME/.local/share/cyrodiil/wallpapers/autumns.hues.png"

    if $WITH_GLOBAL_THEME; then
        link_path "$ROOT/config/gtk-3.0" "$HOME/.config/gtk-3.0"
        link_path "$ROOT/config/gtk-4.0" "$HOME/.config/gtk-4.0"
        link_path "$ROOT/home/.icons/default" "$HOME/.icons/default"
    fi

    $WITH_SHELL && link_path "$ROOT/home/.zshrc" "$HOME/.zshrc"

    if $WITH_FIREFOX; then
        if firefox_profile=$(find_firefox_profile) && [[ -d $firefox_profile ]]; then
            link_path "$ROOT/config/firefox/chrome" "$firefox_profile/chrome"
            link_path "$ROOT/config/firefox/user.js" "$firefox_profile/user.js"
        else
            warn "Firefox profile not found. Launch Firefox once, then rerun with --with-firefox."
        fi
    fi
}

configure_shell() {
    local zsh_path
    local current_shell

    $WITH_SHELL || return 0
    zsh_path=$(command -v zsh || true)
    [[ -n $zsh_path ]] || return 0
    current_shell=$(getent passwd "$USER" | cut -d: -f7)
    [[ $current_shell != "$zsh_path" ]] || return 0

    if ! $ASSUME_YES && confirm "Make Zsh your login shell?" no; then
        if $DRY_RUN; then
            print_command chsh -s "$zsh_path" "$USER"
            return
        fi
        ensure_backup
        printf '%s\n' "$current_shell" > "$BACKUP_DIR/login-shell"
        chsh -s "$zsh_path" "$USER"
    fi
}

validate_config() {
    info "Validating repository sources before deployment"
    if command -v python >/dev/null && command -v git >/dev/null; then
        "$ROOT/scripts/validate.sh"
    else
        warn "Python or Git is unavailable; running reduced validation."
        bash -n "$ROOT/install.sh" "$ROOT/restore.sh" \
            "$ROOT"/config/hypr/scripts/*.sh "$ROOT"/config/waybar/scripts/*.sh
    fi
}

detect_display_manager() {
    local unit
    local target

    unit=$(systemctl show display-manager.service --property=Id --value 2>/dev/null || true)
    if [[ $unit == *.service && $unit != display-manager.service ]]; then
        printf '%s\n' "$unit"
        return 0
    fi

    for target in /etc/systemd/system/display-manager.service /run/systemd/system/display-manager.service; do
        [[ -L $target ]] || continue
        basename -- "$(readlink -f "$target")"
        return 0
    done
    return 1
}

state_is_enabled() {
    [[ $1 == enabled || $1 == enabled-runtime ]]
}

state_is_supported() {
    case $1 in
        enabled|enabled-runtime|disabled|not-found|masked|masked-runtime) return 0 ;;
        *) return 1 ;;
    esac
}

disable_unit_for_state() {
    local unit=$1
    local state=$2

    if [[ $state == enabled-runtime ]]; then
        sudo systemctl disable --runtime "$unit"
    else
        sudo systemctl disable "$unit"
    fi
}

enable_unit_for_state() {
    local unit=$1
    local state=$2

    if [[ $state == enabled-runtime ]]; then
        sudo systemctl enable --runtime "$unit"
    else
        sudo systemctl enable "$unit"
    fi
}

preflight_greetd() {
    $ENABLE_GREETD || return 0
    $DRY_RUN && return 0

    [[ -x /usr/bin/tuigreet ]] || die "/usr/bin/tuigreet is not installed"
    [[ -x /usr/bin/start-hyprland ]] || die "/usr/bin/start-hyprland is not installed"
    [[ -f /usr/share/wayland-sessions/hyprland.desktop || -f /usr/share/wayland-sessions/hyprland-uwsm.desktop ]] \
        || die "No Hyprland session entry was found"
}

configure_greetd() {
    local previous_unit=
    local previous_state=not-found
    local greetd_state

    $ENABLE_GREETD || return 0
    previous_unit=$(detect_display_manager || true)
    [[ -n $previous_unit ]] && previous_state=$(systemctl is-enabled "$previous_unit" 2>/dev/null || true)
    greetd_state=$(systemctl is-enabled greetd.service 2>/dev/null || true)
    state_is_supported "$previous_state" \
        || die "Unsupported display-manager state: $previous_state"
    state_is_supported "$greetd_state" \
        || die "Unsupported greetd state: $greetd_state"
    if [[ -n $previous_unit && $previous_unit != greetd.service ]] \
        && ! state_is_enabled "$previous_state"; then
        die "Cannot safely replace $previous_unit in state '$previous_state'."
    fi

    if $DRY_RUN; then
        install_system_file "$ROOT/system/greetd/config.toml" /etc/greetd/config.toml 0644
        if [[ -n $previous_unit && $previous_unit != greetd.service ]]; then
            print_command sudo systemctl disable "$previous_unit"
        else
            printf ' detect and preserve the current display manager\n'
        fi
        print_command sudo systemctl enable greetd.service
        return
    fi

    install_system_file "$ROOT/system/greetd/config.toml" /etc/greetd/config.toml 0644
    printf 'previous_unit=%s\nprevious_state=%s\ngreetd_state=%s\n' \
        "$previous_unit" "$previous_state" "$greetd_state" > "$BACKUP_DIR/display-manager"

    if [[ -n $previous_unit && $previous_unit != greetd.service ]]; then
        disable_unit_for_state "$previous_unit" "$previous_state" >/dev/null 2>&1 || true
    fi

    if ! sudo systemctl enable greetd.service; then
        warn "Could not enable greetd; restoring the previous display manager."
        sudo systemctl disable greetd.service >/dev/null 2>&1 || true
        if [[ -n $previous_unit ]] && state_is_enabled "$previous_state"; then
            enable_unit_for_state "$previous_unit" "$previous_state" \
                || warn "The previous display manager could not be re-enabled."
        fi
        return 1
    fi

    success " greetd will start on the next boot; the previous display manager remains installed"
}

while (($#)); do
    case $1 in
        --dry-run) DRY_RUN=true ;;
        --yes) ASSUME_YES=true ;;
        --no-packages) INSTALL_PACKAGES=false ;;
        --with-aur) WITH_AUR=true; AUR_SET=true; AUR_DENIED=false ;;
        --no-aur) WITH_AUR=false; AUR_SET=true; AUR_DENIED=true ;;
        --aur-helper)
            (($# >= 2)) || die "--aur-helper requires a command name"
            AUR_HELPER=$2
            shift
            ;;
        --with-global-theme) WITH_GLOBAL_THEME=true; GLOBAL_THEME_SET=true ;;
        --with-shell) WITH_SHELL=true; SHELL_SET=true ;;
        --with-firefox) WITH_FIREFOX=true; FIREFOX_SET=true ;;
        --with-clipboard) WITH_CLIPBOARD=true; CLIPBOARD_SET=true ;;
        --without-clipboard) WITH_CLIPBOARD=false; CLIPBOARD_SET=true ;;
        --with-pipewire) WITH_PIPEWIRE=true ;;
        --without-pipewire) WITH_PIPEWIRE=false ;;
        --with-bluetooth) WITH_BLUETOOTH=true; BLUETOOTH_SET=true ;;
        --with-networkmanager) WITH_NETWORKMANAGER=true; NETWORKMANAGER_SET=true ;;
        --enable-greetd) ENABLE_GREETD=true ;;
        --full)
            WITH_AUR=true
            WITH_GLOBAL_THEME=true
            WITH_SHELL=true
            WITH_FIREFOX=true
            WITH_CLIPBOARD=true
            AUR_SET=true
            GLOBAL_THEME_SET=true
            SHELL_SET=true
            FIREFOX_SET=true
            CLIPBOARD_SET=true
            ;;
        --skip-firefox) WITH_FIREFOX=false; FIREFOX_SET=true ;;
        --skip-greetd) ENABLE_GREETD=false ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; die "Unknown option: $1" ;;
    esac
    shift
done

if $WITH_GLOBAL_THEME; then
    $AUR_DENIED && die "--with-global-theme cannot be combined with --no-aur."
    WITH_AUR=true
    AUR_SET=true
fi

if [[ -n $AUR_HELPER && $AUR_HELPER != paru && $AUR_HELPER != yay ]]; then
    die "Supported AUR helpers are paru and yay."
fi

load_existing_options

((EUID == 0)) && die "Run this installer as your normal user, not root."
[[ -r /etc/os-release ]] || die "Cannot determine the operating system."

# shellcheck disable=SC1091
source /etc/os-release
if [[ ${ID:-} != arch && ${ID_LIKE:-} != *arch* ]]; then
    die "This installer supports Arch Linux and Arch-based distributions only."
fi

if $INSTALL_PACKAGES || $ENABLE_GREETD; then
    command -v sudo >/dev/null || die "sudo is required for package or display-manager changes."
fi

printf '\nCyrodiil Dotfiles Installer\n'
printf 'Repository: %s\n' "$ROOT"
printf 'Mode: %s\n\n' "$($DRY_RUN && printf 'dry run' || printf 'install')"

confirm "Continue with the Cyrodiil desktop installation?" yes || exit 0
select_components
if $INSTALL_PACKAGES && $WITH_AUR && [[ -n $AUR_HELPER ]] \
    && ! $DRY_RUN && ! command -v "$AUR_HELPER" >/dev/null; then
    die "Requested AUR helper '$AUR_HELPER' is not installed."
fi
validate_config
$INSTALL_PACKAGES && install_packages
$INSTALL_PACKAGES && validate_config
preflight_greetd
generate_options_config
deploy_files
configure_shell
configure_greetd
remember_latest_backup

printf '\nInstallation complete.\n'
if $BACKUP_READY; then
    printf 'Backup: %s\n' "$BACKUP_DIR"
    printf 'Restore: %s/restore.sh %s\n' "$ROOT" "$BACKUP_DIR"
fi

if $ENABLE_GREETD; then
    printf '\nDo not reboot until you have read the recovery instructions in README.md.\n'
    printf 'After reboot, tuigreet can start any installed Wayland session.\n'
else
    printf '\nYour current display manager was preserved. Log out and select Hyprland there.\n'
fi
