#!/usr/bin/env bash
set -euo pipefail
source "$ROOT/test/helpers.sh"
source "$ROOT/lib/logging.sh"
source "$ROOT/lib/packages.sh"
source "$ROOT/lib/mise.sh"
source "$ROOT/lib/macos.sh"

sandbox="$(new_sandbox)"
trap 'rm -rf "$sandbox"' EXIT
fakebin="$sandbox/bin"
mkdir -p "$fakebin"

cat >"$sandbox/workbrew" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  shellenv) printf 'export DOTFILES_WORKBREW_ACTIVATED=1\n' ;;
  --prefix) printf '/opt/homebrew\n' ;;
  install) printf '%s\n' "$2" >>"$DOTFILES_TEST_PACKAGE_LOG" ;;
esac
EOF
cat >"$fakebin/brew" <<'EOF'
#!/usr/bin/env bash
echo "vanilla brew should not run" >&2
exit 9
EOF
chmod +x "$sandbox/workbrew" "$fakebin/brew"

PATH="$fakebin:$PATH"
DOTFILES_WORKBREW_BREW="$sandbox/workbrew"
DOTFILES_TEST_PACKAGE_LOG="$sandbox/packages"
export PATH DOTFILES_WORKBREW_BREW DOTFILES_TEST_PACKAGE_LOG
OS=macos
FLAVOR=""

assert_eq "$sandbox/workbrew" "$(find_brew)" "Workbrew was not preferred"
assert_eq Workbrew "$(package_backend_name)" "backend name"
bootstrap_package_backend 0
assert_eq 1 "${DOTFILES_WORKBREW_ACTIVATED:-0}" "Workbrew environment was not activated"

report_init
DOTFILES_DRY_RUN=0
ensure_package "Example" command-that-does-not-exist example-formula ""
assert_file_contains "$sandbox/packages" "example-formula"

chmod -x "$sandbox/workbrew"
if bootstrap_package_backend 1 >"$sandbox/inaccessible-output" 2>&1; then
  fail "inaccessible Workbrew incorrectly fell back to vanilla Homebrew"
fi
assert_file_contains "$sandbox/inaccessible-output" "Request Workbrew access"
chmod +x "$sandbox/workbrew"

cat >"$fakebin/mise" <<'EOF'
#!/usr/bin/env bash
case "${1:-}" in
  where) [[ -f "$DOTFILES_TEST_MISE_MARKER" ]] ;;
  install) : >"$DOTFILES_TEST_MISE_MARKER" ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$fakebin/mise"
DOTFILES_TEST_MISE_MARKER="$sandbox/mise-installed"
export DOTFILES_TEST_MISE_MARKER

report_init
DOTFILES_DRY_RUN=1
ensure_mise_tool "Terraform" terraform latest
[[ ! -e "$DOTFILES_TEST_MISE_MARKER" ]] || fail "mise dry-run installed a tool"
assert_eq 1 "${#REPORT_INSTALL[@]}" "mise dry-run did not plan an install"

report_init
DOTFILES_DRY_RUN=0
ensure_mise_tool "Terraform" terraform latest
[[ -f "$DOTFILES_TEST_MISE_MARKER" ]] || fail "mise tool was not installed"
report_init
ensure_mise_tool "Terraform" terraform latest
assert_eq 0 "${#REPORT_CHANGED[@]}" "mise tool reconciliation was not idempotent"

cat >"$fakebin/pkgutil" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
cat >"$fakebin/xcode-select" <<'EOF'
#!/usr/bin/env bash
exit 1
EOF
chmod +x "$fakebin/pkgutil" "$fakebin/xcode-select"

report_init
DOTFILES_DRY_RUN=1
DOTFILES_TEST_ARCH=arm64
ensure_macos_app_store_app "Xcode" 497799835 "$sandbox/Applications/Xcode.app"
ensure_command_line_tools
ensure_rosetta
assert_eq 3 "${#REPORT_INSTALL[@]}" "macOS prerequisite dry-run plan"
[[ ! -e "$sandbox/Applications" ]] || fail "macOS prerequisite dry-run changed files"

report_init
DOTFILES_DRY_RUN=1
ensure_macos_cask "Example App" example-app "$sandbox/Applications/Example.app"
ensure_direct_macos_app \
  "Direct App" \
  "$sandbox/Applications/Direct.app" \
  "https://example.invalid/Direct.dmg" \
  dmg \
  Direct.app \
  example.direct \
  TEAMID \
  deadbeef
assert_eq 2 "${#REPORT_INSTALL[@]}" "macOS app dry-run plan"
[[ ! -e "$sandbox/Applications" ]] || fail "macOS application dry-run changed files"

mkdir -p "$sandbox/Applications/Example.app" "$sandbox/Applications/Direct.app"
report_init
DOTFILES_DRY_RUN=0
ensure_macos_cask "Example App" example-app "$sandbox/Applications/Example.app"
ensure_direct_macos_app \
  "Direct App" \
  "$sandbox/Applications/Direct.app" \
  "https://example.invalid/Direct.dmg" \
  dmg \
  Direct.app \
  example.direct \
  TEAMID \
  deadbeef
assert_eq 0 "${#REPORT_CHANGED[@]}" "existing macOS apps were unexpectedly changed"
assert_eq 2 "$REPORT_UNCHANGED_COUNT" "existing macOS apps were not idempotent"

assert_file_contains "$ROOT/config/mise/config.toml" 'node = "lts"'
assert_file_contains "$ROOT/config/mise/config.toml" 'terraform = "latest"'
assert_file_contains "$ROOT/config/mise/config.toml" 'go = "latest"'
