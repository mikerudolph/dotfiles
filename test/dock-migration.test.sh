#!/usr/bin/env bash
set -euo pipefail
source "$ROOT/test/helpers.sh"

sandbox="$(new_sandbox)"
trap 'rm -rf "$sandbox"' EXIT
fakebin="$sandbox/bin"
mkdir -p "$fakebin"

cat >"$fakebin/defaults" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$DOTFILES_TEST_DOCK_LOG"
EOF
cat >"$fakebin/pgrep" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
cat >"$fakebin/killall" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "killall $*" >>"$DOTFILES_TEST_DOCK_LOG"
EOF
chmod +x "$fakebin/defaults" "$fakebin/pgrep" "$fakebin/killall"

PATH="$fakebin:$PATH"
DOTFILES_TEST_DOCK_LOG="$sandbox/dock-log"
export PATH DOTFILES_TEST_DOCK_LOG

DOTFILES_TEST_UNAME=Linux bash "$ROOT/migrations/0001-clear-macos-dock-apps.sh"
[[ ! -e "$DOTFILES_TEST_DOCK_LOG" ]] || fail "Dock migration ran on Linux"

DOTFILES_TEST_UNAME=Darwin bash "$ROOT/migrations/0001-clear-macos-dock-apps.sh"
assert_file_contains "$DOTFILES_TEST_DOCK_LOG" 'write com.apple.dock persistent-apps -array'
assert_file_contains "$DOTFILES_TEST_DOCK_LOG" 'killall Dock'
