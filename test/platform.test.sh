#!/usr/bin/env bash
set -euo pipefail
source "$ROOT/test/helpers.sh"
source "$ROOT/lib/platform.sh"

DOTFILES_TEST_UNAME=Darwin
platform_detect
assert_eq macos "$OS" "Darwin detection"
platform_validate_supported

sandbox="$(new_sandbox)"
trap 'rm -rf "$sandbox"' EXIT
printf 'ID=arch\n' >"$sandbox/arch-release"

DOTFILES_TEST_UNAME=Linux
DOTFILES_TEST_OS_RELEASE="$sandbox/arch-release"
DOTFILES_TEST_OMARCHY_ROOT="$sandbox/no-omarchy"
platform_detect
assert_eq linux "$OS" "Linux detection"
assert_eq arch "$DISTRO" "Arch detection"
assert_eq "" "$FLAVOR" "generic Arch flavor"
if platform_validate_supported; then
  fail "generic Arch must not be accepted as Omarchy"
fi

mkdir -p "$sandbox/omarchy/bin"
printf '#!/usr/bin/env bash\n' >"$sandbox/omarchy/bin/omarchy"
chmod +x "$sandbox/omarchy/bin/omarchy"
DOTFILES_TEST_OMARCHY_ROOT="$sandbox/omarchy"
platform_detect
assert_eq omarchy "$FLAVOR" "Omarchy detection"
platform_validate_supported

printf 'ID=ubuntu\n' >"$sandbox/ubuntu-release"
DOTFILES_TEST_OS_RELEASE="$sandbox/ubuntu-release"
platform_detect
assert_eq ubuntu "$DISTRO" "unsupported distro detection"
if platform_validate_supported; then
  fail "unsupported Linux distribution was accepted"
fi
[[ "$PLATFORM_ERROR" == *"Unsupported Linux distribution"* ]] || fail "unsafe failure message missing"

mkdir -p "$sandbox/unsupported-home"
if env HOME="$sandbox/unsupported-home" \
  DOTFILES_TEST_UNAME=Linux \
  DOTFILES_TEST_OS_RELEASE="$sandbox/ubuntu-release" \
  DOTFILES_TEST_OMARCHY_ROOT="$sandbox/no-omarchy" \
  "$ROOT/bin/apply" --dry-run >"$sandbox/unsupported-output" 2>&1; then
  fail "apply accepted an unsupported Linux distribution"
fi
assert_file_contains "$sandbox/unsupported-output" "Unsupported Linux distribution"
[[ -z "$(find "$sandbox/unsupported-home" -mindepth 1 -print -quit)" ]] || fail "unsupported apply changed HOME"
