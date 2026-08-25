#!/usr/bin/env bash

set -euo pipefail

STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}/cyrodiil-dotfiles
BACKUP_DIR=${1:-}
PREVIOUS_UNIT=
PREVIOUS_STATE=not-found
GREETD_STATE=not-found

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
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

enable_unit_for_state() {
    local unit=$1
    local state=$2

    if [[ $state == enabled-runtime ]]; then
        sudo systemctl enable --runtime "$unit"
    else
        sudo systemctl enable "$unit"
    fi
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

load_display_manager_state() {
    local legacy_sddm
    local legacy_greetd

    [[ -f $BACKUP_DIR/display-manager ]] || return 0
    if grep -q '^previous_unit=' "$BACKUP_DIR/display-manager"; then
        if ! grep -q '^previous_state=' "$BACKUP_DIR/display-manager" \
            || ! grep -q '^greetd_state=' "$BACKUP_DIR/display-manager"; then
            die "Display-manager backup metadata is incomplete."
        fi
        PREVIOUS_UNIT=$(awk -F= '$1 == "previous_unit" { print $2 }' "$BACKUP_DIR/display-manager")
        PREVIOUS_STATE=$(awk -F= '$1 == "previous_state" { print $2 }' "$BACKUP_DIR/display-manager")
        GREETD_STATE=$(awk -F= '$1 == "greetd_state" { print $2 }' "$BACKUP_DIR/display-manager")
    else
        if ! grep -q '^sddm=' "$BACKUP_DIR/display-manager" \
            || ! grep -q '^greetd=' "$BACKUP_DIR/display-manager"; then
            die "Display-manager backup metadata is incomplete."
        fi
        legacy_sddm=$(awk -F= '$1 == "sddm" { print $2 }' "$BACKUP_DIR/display-manager")
        legacy_greetd=$(awk -F= '$1 == "greetd" { print $2 }' "$BACKUP_DIR/display-manager")
        PREVIOUS_UNIT=sddm.service
        PREVIOUS_STATE=$legacy_sddm
        GREETD_STATE=$legacy_greetd
    fi

    state_is_supported "$PREVIOUS_STATE" \
        || die "Unsupported previous display-manager state: $PREVIOUS_STATE"
    state_is_supported "$GREETD_STATE" \
        || die "Unsupported greetd state: $GREETD_STATE"
}

preflight_display_manager() {
    [[ -f $BACKUP_DIR/display-manager ]] || return 0

    if [[ -n $PREVIOUS_UNIT && $PREVIOUS_UNIT != greetd.service ]] \
        && state_is_enabled "$PREVIOUS_STATE"; then
        systemctl cat "$PREVIOUS_UNIT" >/dev/null 2>&1 \
            || die "Previous display manager is unavailable: $PREVIOUS_UNIT"
    fi
}

preflight_records() {
    local record
    local target
    local state
    local scope
    local backup

    for record in "${records[@]}"; do
        IFS=$'\t' read -r target state scope <<< "$record"
        [[ $target == /* ]] || die "Refusing non-absolute restore target: $target"
        [[ $state == present || $state == absent ]] || die "Invalid state for $target"
        [[ $scope == user || $scope == system ]] || die "Invalid scope for $target"
        [[ $state == present ]] || continue

        backup=$BACKUP_DIR/files/${target#/}
        if [[ $scope == system ]]; then
            sudo test -e "$backup" || sudo test -L "$backup" \
                || die "Missing backup for $target"
        else
            [[ -e $backup || -L $backup ]] || die "Missing backup for $target"
        fi
    done
}

restore_user_target() {
    local target=$1
    local state=$2
    local backup=$BACKUP_DIR/files/${target#/}

    rm -rf -- "$target"
    if [[ $state == present ]]; then
        mkdir -p "$(dirname -- "$target")"
        cp -a --no-dereference -- "$backup" "$target"
    fi
    printf ' restored %s\n' "$target"
}

restore_system_target() {
    local target=$1
    local state=$2
    local backup=$BACKUP_DIR/files/${target#/}

    sudo rm -rf -- "$target"
    if [[ $state == present ]]; then
        sudo mkdir -p "$(dirname -- "$target")"
        sudo cp -a --no-dereference -- "$backup" "$target"
    fi
    printf ' restored %s\n' "$target"
}

restore_display_manager() {
    local current_greetd_state

    [[ -f $BACKUP_DIR/display-manager ]] || return 0
    current_greetd_state=$(systemctl is-enabled greetd.service 2>/dev/null || true)
    disable_unit_for_state greetd.service "$current_greetd_state" >/dev/null 2>&1 || true

    if [[ -n $PREVIOUS_UNIT && $PREVIOUS_UNIT != greetd.service ]] \
        && state_is_enabled "$PREVIOUS_STATE"; then
        if ! enable_unit_for_state "$PREVIOUS_UNIT" "$PREVIOUS_STATE"; then
            printf 'error: Could not restore the previous display manager; re-enabling greetd.\n' >&2
            disable_unit_for_state "$PREVIOUS_UNIT" "$PREVIOUS_STATE" >/dev/null 2>&1 || true
            if state_is_enabled "$current_greetd_state"; then
                enable_unit_for_state greetd.service "$current_greetd_state" \
                    || die "Neither display manager could be enabled. Run: sudo systemctl enable greetd.service"
            fi
            die "Display-manager restoration failed."
        fi
    elif state_is_enabled "$GREETD_STATE"; then
        enable_unit_for_state greetd.service "$GREETD_STATE"
    fi
    printf ' restored display-manager enablement\n'
}

((EUID == 0)) && die "Run this restore as your normal user, not root."

if [[ -z $BACKUP_DIR ]]; then
    [[ -L $STATE_HOME/latest ]] || die "No latest backup was found."
    BACKUP_DIR=$(readlink -f "$STATE_HOME/latest")
fi

[[ -d $BACKUP_DIR ]] || die "Backup directory does not exist: $BACKUP_DIR"
[[ -f $BACKUP_DIR/manifest.tsv ]] || die "Backup manifest is missing."

mapfile -t records < "$BACKUP_DIR/manifest.tsv"
preflight_records
load_display_manager_state
preflight_display_manager

printf 'Restoring backup: %s\n' "$BACKUP_DIR"
read -r -p 'Continue? [y/N] ' answer
[[ $answer =~ ^[Yy]$ ]] || exit 0

# Recover graphical login first so a later user-file error cannot block it.
restore_display_manager

for ((i=${#records[@]} - 1; i >= 0; i--)); do
    IFS=$'\t' read -r target state scope <<< "${records[i]}"
    if [[ $scope == system ]]; then
        restore_system_target "$target" "$state"
    else
        restore_user_target "$target" "$state"
    fi
done

if [[ -f $BACKUP_DIR/login-shell ]]; then
    previous_shell=$(<"$BACKUP_DIR/login-shell")
    chsh -s "$previous_shell" "$USER"
    printf ' restored login shell to %s\n' "$previous_shell"
fi

printf '\nRestore complete. Reboot only if the display manager was changed.\n'
