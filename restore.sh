#!/usr/bin/env bash

set -euo pipefail

STATE_HOME=${XDG_STATE_HOME:-$HOME/.local/state}/cyrodiil-dotfiles
BACKUP_DIR=${1:-}

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

restore_user_target() {
    local target=$1
    local state=$2
    local backup=$BACKUP_DIR/files/${target#/}

    rm -rf -- "$target"
    if [[ $state == present ]]; then
        [[ -e $backup || -L $backup ]] || die "Missing backup for $target"
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
        sudo test -e "$backup" || die "Missing backup for $target"
        sudo mkdir -p "$(dirname -- "$target")"
        sudo cp -a -- "$backup" "$target"
    fi
    printf ' restored %s\n' "$target"
}

restore_display_manager() {
    local sddm_state
    local greetd_state

    [[ -f $BACKUP_DIR/display-manager ]] || return 0
    sddm_state=$(awk -F= '$1 == "sddm" { print $2 }' "$BACKUP_DIR/display-manager")
    greetd_state=$(awk -F= '$1 == "greetd" { print $2 }' "$BACKUP_DIR/display-manager")

    sudo systemctl disable greetd.service >/dev/null 2>&1 || true
    sudo systemctl disable sddm.service >/dev/null 2>&1 || true
    [[ $sddm_state == enabled ]] && sudo systemctl enable sddm.service
    [[ $greetd_state == enabled ]] && sudo systemctl enable greetd.service
    printf ' restored display-manager enablement\n'
}

if [[ -z $BACKUP_DIR ]]; then
    [[ -L $STATE_HOME/latest ]] || die "No latest backup was found."
    BACKUP_DIR=$(readlink -f "$STATE_HOME/latest")
fi

[[ -d $BACKUP_DIR ]] || die "Backup directory does not exist: $BACKUP_DIR"
[[ -f $BACKUP_DIR/manifest.tsv ]] || die "Backup manifest is missing."

printf 'Restoring backup: %s\n' "$BACKUP_DIR"
read -r -p 'Continue? [y/N] ' answer
[[ $answer =~ ^[Yy]$ ]] || exit 0

mapfile -t records < "$BACKUP_DIR/manifest.tsv"
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

restore_display_manager

printf '\nRestore complete. Reboot only if the display manager was changed.\n'
