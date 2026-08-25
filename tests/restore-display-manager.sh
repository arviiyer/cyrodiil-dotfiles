#!/usr/bin/env bash

set -euo pipefail

ROOT=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)
TEST_ROOT=$(mktemp -d)
BACKUP=$TEST_ROOT/backup
LOG=$TEST_ROOT/systemctl.log

cleanup() {
    rm -rf -- "$TEST_ROOT"
}
trap cleanup EXIT

mkdir -p "$TEST_ROOT/bin" "$BACKUP"
: > "$BACKUP/manifest.tsv"

cat > "$TEST_ROOT/bin/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF

cat > "$TEST_ROOT/bin/systemctl" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$SYSTEMCTL_LOG"

case $1 in
    cat)
        [[ ${FAKE_MISSING_UNIT:-} != "$2" ]]
        ;;
    is-enabled)
        printf '%s\n' "${FAKE_GREETD_STATE:-enabled}"
        ;;
    enable)
        unit=${*: -1}
        [[ ,${FAKE_FAIL_ENABLE:-}, != *,$unit,* ]]
        ;;
esac
EOF

chmod +x "$TEST_ROOT/bin/sudo" "$TEST_ROOT/bin/systemctl"

cat > "$BACKUP/display-manager" <<'EOF'
sddm=enabled
greetd=disabled
EOF

SYSTEMCTL_LOG=$LOG PATH="$TEST_ROOT/bin:$PATH" \
    "$ROOT/restore.sh" "$BACKUP" <<< y >/dev/null
grep -Fx 'enable sddm.service' "$LOG" >/dev/null

: > "$LOG"
if SYSTEMCTL_LOG=$LOG FAKE_MISSING_UNIT=sddm.service PATH="$TEST_ROOT/bin:$PATH" \
    "$ROOT/restore.sh" "$BACKUP" <<< y >/dev/null 2>&1; then
    printf 'restore unexpectedly accepted a missing display manager\n' >&2
    exit 1
fi
if grep -F 'disable greetd.service' "$LOG" >/dev/null; then
    printf 'restore disabled greetd before completing preflight\n' >&2
    exit 1
fi

: > "$LOG"
if SYSTEMCTL_LOG=$LOG FAKE_FAIL_ENABLE=sddm.service PATH="$TEST_ROOT/bin:$PATH" \
    "$ROOT/restore.sh" "$BACKUP" <<< y >/dev/null 2>&1; then
    printf 'restore unexpectedly accepted a display-manager enable failure\n' >&2
    exit 1
fi
grep -Fx 'enable greetd.service' "$LOG" >/dev/null

: > "$LOG"
if SYSTEMCTL_LOG=$LOG FAKE_FAIL_ENABLE=sddm.service,greetd.service PATH="$TEST_ROOT/bin:$PATH" \
    "$ROOT/restore.sh" "$BACKUP" <<< y >/dev/null 2>&1; then
    printf 'restore unexpectedly accepted failure of both display managers\n' >&2
    exit 1
fi
grep -Fx 'enable greetd.service' "$LOG" >/dev/null

cat > "$BACKUP/display-manager" <<'EOF'
previous_unit=sddm.service
previous_state=static
greetd_state=disabled
EOF
: > "$LOG"
if SYSTEMCTL_LOG=$LOG PATH="$TEST_ROOT/bin:$PATH" \
    "$ROOT/restore.sh" "$BACKUP" <<< y >/dev/null 2>&1; then
    printf 'restore unexpectedly accepted an unsupported service state\n' >&2
    exit 1
fi
if grep -F 'disable greetd.service' "$LOG" >/dev/null; then
    printf 'restore changed services with unsupported metadata\n' >&2
    exit 1
fi

cat > "$BACKUP/display-manager" <<'EOF'
previous_unit=sddm.service
previous_state=enabled
EOF
: > "$LOG"
if SYSTEMCTL_LOG=$LOG PATH="$TEST_ROOT/bin:$PATH" \
    "$ROOT/restore.sh" "$BACKUP" <<< y >/dev/null 2>&1; then
    printf 'restore unexpectedly accepted incomplete metadata\n' >&2
    exit 1
fi
if grep -F 'disable greetd.service' "$LOG" >/dev/null; then
    printf 'restore changed services with incomplete metadata\n' >&2
    exit 1
fi

cat > "$BACKUP/display-manager" <<'EOF'
previous_unit=ly.service
previous_state=enabled-runtime
greetd_state=disabled
EOF
: > "$LOG"
SYSTEMCTL_LOG=$LOG PATH="$TEST_ROOT/bin:$PATH" \
    "$ROOT/restore.sh" "$BACKUP" <<< y >/dev/null
grep -Fx 'enable --runtime ly.service' "$LOG" >/dev/null

printf 'Display-manager restore tests passed.\n'
