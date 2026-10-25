#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$DOTFILES_ROOT/lib/platform.sh"

test_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-platform.XXXXXX")"
trap 'rm -rf -- "$test_directory"' EXIT
mkdir -p "$test_directory/omarchy/bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$test_directory/omarchy/bin/omarchy"
chmod +x "$test_directory/omarchy/bin/omarchy"

check_platform() (
  local label="$1" kernel="$2" release="$3" installation="$4"
  local expected="$5" expected_status="$6" status=0
  printf '%s\n' "$release" > "$test_directory/os-release"
  export DOTFILES_TEST_UNAME="$kernel"
  export DOTFILES_TEST_OS_RELEASE="$test_directory/os-release"
  export DOTFILES_TEST_OMARCHY_ROOT="$test_directory/$installation"

  if platform_detect; then
    platform_validate_supported || status=$?
  else
    status=$?
  fi
  if [[ "$OS:$DISTRO:$FLAVOR" != "$expected" || "$status" != "$expected_status" ]]; then
    printf 'FAIL: %s (got %s, status %s)\n' "$label" "$OS:$DISTRO:$FLAVOR" "$status" >&2
    printf '%s\n' "$PLATFORM_ERROR" >&2
    exit 1
  fi
  if [[ "$status" != 0 && -z "$PLATFORM_ERROR" ]]; then
    printf 'FAIL: %s did not explain the unsupported platform\n' "$label" >&2
    exit 1
  fi
  printf 'PASS: %s\n' "$label"
)

check_platform 'Omarchy identity' Linux $'ID=omarchy\nID_LIKE=arch' omarchy linux:arch:omarchy 0
check_platform 'Omarchy identity without ID_LIKE' Linux 'ID=omarchy' omarchy linux:arch:omarchy 0
check_platform 'Legacy Arch identity with Omarchy' Linux 'ID=arch' omarchy linux:arch:omarchy 0
check_platform 'Bare Arch' Linux 'ID=arch' absent linux:arch: 1
check_platform 'Omarchy identity without installation' Linux $'ID=omarchy\nID_LIKE=arch' absent linux:arch: 1
check_platform 'Other Arch derivative with Omarchy files' Linux $'ID=manjaro\nID_LIKE=arch' omarchy linux:manjaro: 1
check_platform 'Other Linux with Omarchy files' Linux $'ID=ubuntu\nID_LIKE=debian' omarchy linux:ubuntu: 1
check_platform 'macOS' Darwin '' absent macos:: 0
check_platform 'Unsupported kernel' FreeBSD '' absent unsupported:: 1
