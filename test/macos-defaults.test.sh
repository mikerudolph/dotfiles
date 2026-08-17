#!/usr/bin/env bash
set -euo pipefail
source "$ROOT/test/helpers.sh"
source "$ROOT/lib/logging.sh"
source "$ROOT/lib/macos-defaults.sh"

sandbox="$(new_sandbox)"
trap 'rm -rf "$sandbox"' EXIT
fakebin="$sandbox/bin"
mkdir -p "$fakebin"

cat >"$fakebin/defaults" <<'EOF'
#!/usr/bin/env bash
scope=user
if [[ "$1" == "-currentHost" ]]; then
  scope=host
  shift
fi
case "$1" in
  read)
    if [[ "${3:-}" == "AppleInterfaceStyle" ]]; then
      [[ -f "$DOTFILES_TEST_DARK_MODE" ]] || exit 1
      grep -Fq true "$DOTFILES_TEST_DARK_MODE" && printf 'Dark\n'
      exit
    fi
    if [[ "$scope" == "host" ]]; then
      [[ -f "$DOTFILES_TEST_HOST_DEFAULT_VALUE" ]] || exit 1
      cat "$DOTFILES_TEST_HOST_DEFAULT_VALUE"
    else
      [[ -f "$DOTFILES_TEST_DEFAULT_VALUE" ]] || exit 1
      cat "$DOTFILES_TEST_DEFAULT_VALUE"
    fi
    ;;
  write)
    if [[ "$2" == "com.apple.symbolichotkeys" ]]; then
      printf '%s\n' "$*" >"$DOTFILES_TEST_HOTKEY_LOG"
      printf '%s|%s|%s\n' "$5" "$DOTFILES_TEST_HOTKEY_KEYCODE" \
        "$DOTFILES_TEST_HOTKEY_MODIFIERS" >"$DOTFILES_TEST_HOTKEY_STATE"
    elif [[ "$scope" == "host" ]]; then
      printf '%s\n' "$5" >"$DOTFILES_TEST_HOST_DEFAULT_VALUE"
    else
      printf '%s\n' "$5" >"$DOTFILES_TEST_DEFAULT_VALUE"
    fi
    ;;
  export) printf '<plist version="1.0"><dict/></plist>\n' ;;
  *) exit 2 ;;
esac
EOF
cat >"$fakebin/plutil" <<'EOF'
#!/usr/bin/env bash
[[ -f "$DOTFILES_TEST_HOTKEY_STATE" ]] || exit 1
IFS='|' read -r hotkey_id keycode modifiers <"$DOTFILES_TEST_HOTKEY_STATE"
path="$2"
case "$path" in
  "AppleSymbolicHotKeys.$hotkey_id.enabled") printf 'true\n' ;;
  "AppleSymbolicHotKeys.$hotkey_id.value.type") printf 'standard\n' ;;
  "AppleSymbolicHotKeys.$hotkey_id.value.parameters.0") printf '65535\n' ;;
  "AppleSymbolicHotKeys.$hotkey_id.value.parameters.1") printf '%s\n' "$keycode" ;;
  "AppleSymbolicHotKeys.$hotkey_id.value.parameters.2") printf '%s\n' "$modifiers" ;;
  *) exit 1 ;;
esac
EOF
cat >"$fakebin/osascript" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  *"get dark mode"*)
    [[ -f "$DOTFILES_TEST_DARK_MODE" ]] || exit 1
    cat "$DOTFILES_TEST_DARK_MODE"
    ;;
  *"set dark mode to true"*) printf 'true\n' >"$DOTFILES_TEST_DARK_MODE" ;;
  *"set dark mode to false"*) printf 'false\n' >"$DOTFILES_TEST_DARK_MODE" ;;
  *) exit 2 ;;
esac
EOF
chmod +x "$fakebin/defaults" "$fakebin/plutil" "$fakebin/osascript"

PATH="$fakebin:$PATH"
DOTFILES_TEST_DEFAULT_VALUE="$sandbox/default-value"
DOTFILES_TEST_HOST_DEFAULT_VALUE="$sandbox/host-default-value"
DOTFILES_TEST_DARK_MODE="$sandbox/dark-mode"
DOTFILES_TEST_HOTKEY_LOG="$sandbox/hotkey-log"
DOTFILES_TEST_HOTKEY_STATE="$sandbox/hotkey-state"
DOTFILES_TEST_HOTKEY_KEYCODE=18
DOTFILES_TEST_HOTKEY_MODIFIERS=1048576
export PATH DOTFILES_TEST_DEFAULT_VALUE DOTFILES_TEST_HOST_DEFAULT_VALUE DOTFILES_TEST_DARK_MODE
export DOTFILES_TEST_HOTKEY_LOG DOTFILES_TEST_HOTKEY_STATE
export DOTFILES_TEST_HOTKEY_KEYCODE DOTFILES_TEST_HOTKEY_MODIFIERS
OS=macos

report_init
macos_defaults_init
DOTFILES_DRY_RUN=1
ensure_macos_default "Dock size" com.apple.dock tilesize int 43 Dock
apply_macos_default_restarts
assert_eq 2 "${#REPORT_CONFIGURE[@]}" "dry-run did not plan the default and restart"
[[ ! -e "$DOTFILES_TEST_DEFAULT_VALUE" ]] || fail "macOS defaults dry-run wrote a value"

report_init
macos_defaults_init
DOTFILES_DRY_RUN=0
ensure_macos_default "Dock size" com.apple.dock tilesize int 43
assert_file_contains "$DOTFILES_TEST_DEFAULT_VALUE" 43
assert_eq 1 "${#REPORT_CHANGED[@]}" "macOS default was not written"

report_init
macos_defaults_init
ensure_macos_default "Dock size" com.apple.dock tilesize int 43
assert_eq 0 "${#REPORT_CHANGED[@]}" "macOS default was not idempotent"
assert_eq 1 "$REPORT_UNCHANGED_COUNT" "matching macOS default was not recognized"

report_init
macos_defaults_init
ensure_macos_host_default "Battery percentage" com.apple.controlcenter BatteryShowPercentage bool true
assert_file_contains "$DOTFILES_TEST_HOST_DEFAULT_VALUE" true
report_init
macos_defaults_init
ensure_macos_host_default "Battery percentage" com.apple.controlcenter BatteryShowPercentage bool true
assert_eq 1 "$REPORT_UNCHANGED_COUNT" "matching host-specific default was not recognized"

report_init
macos_defaults_init
DOTFILES_DRY_RUN=1
ensure_macos_symbolic_hotkey "Desktop 1" 118 18 1048576
[[ ! -e "$DOTFILES_TEST_HOTKEY_LOG" ]] || fail "symbolic-hotkey dry-run wrote a value"

report_init
macos_defaults_init
DOTFILES_DRY_RUN=0
ensure_macos_symbolic_hotkey "Desktop 1" 118 18 1048576
assert_file_contains "$DOTFILES_TEST_HOTKEY_LOG" 'AppleSymbolicHotKeys -dict-add 118'
assert_file_contains "$DOTFILES_TEST_HOTKEY_LOG" '<integer>65535</integer><integer>18</integer><integer>1048576</integer>'
report_init
macos_defaults_init
ensure_macos_symbolic_hotkey "Desktop 1" 118 18 1048576
assert_eq 1 "$REPORT_UNCHANGED_COUNT" "matching symbolic hotkey was not recognized"

DOTFILES_TEST_SPACE_COUNT=2
export DOTFILES_TEST_SPACE_COUNT
report_init
check_macos_workspace_count 9
assert_eq 1 "${#REPORT_MANUAL[@]}" "missing Desktop Spaces did not require manual action"
DOTFILES_TEST_SPACE_COUNT=9
report_init
check_macos_workspace_count 9
assert_eq 1 "$REPORT_UNCHANGED_COUNT" "available Desktop Spaces were not recognized"
unset DOTFILES_TEST_SPACE_COUNT

report_init
macos_defaults_init
DOTFILES_DRY_RUN=1
ensure_macos_dark_mode "Dark appearance" true
assert_eq 1 "${#REPORT_CONFIGURE[@]}" "dark-mode dry-run did not plan a change"
[[ ! -e "$DOTFILES_TEST_DARK_MODE" ]] || fail "dark-mode dry-run changed appearance"

report_init
macos_defaults_init
DOTFILES_DRY_RUN=0
ensure_macos_dark_mode "Dark appearance" true
assert_file_contains "$DOTFILES_TEST_DARK_MODE" true
report_init
macos_defaults_init
ensure_macos_dark_mode "Dark appearance" true
assert_eq 1 "$REPORT_UNCHANGED_COUNT" "dark mode was not idempotent"

report_init
macos_defaults_init
DOTFILES_DRY_RUN=1
ensure_macos_default "Invalid" example.domain ExampleKey unsupported value || true
assert_eq 1 "${#REPORT_CONFLICT[@]}" "invalid macOS default type did not conflict"

mkdir -p "$sandbox/Library"
DOTFILES_TEST_PATH_FLAGS=hidden
export DOTFILES_TEST_PATH_FLAGS
report_init
macos_defaults_init
DOTFILES_DRY_RUN=1
ensure_macos_visible_directory "Show Library" "$sandbox/Library"
assert_eq 1 "${#REPORT_CONFIGURE[@]}" "hidden directory dry-run was not planned"

assert_file_contains "$ROOT/platform/macos/defaults.sh" 'com.apple.screencapture captureHDR bool false'
assert_file_contains "$ROOT/platform/macos/defaults.sh" 'com.apple.screencapture type string png'
assert_file_contains "$ROOT/platform/macos/defaults.sh" 'com.apple.screencapture show-thumbnail bool false'
assert_file_contains "$ROOT/platform/macos/defaults.sh" 'com.apple.screencapture disable-shadow bool true'
