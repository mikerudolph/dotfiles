#!/usr/bin/env bash

# Test overrides intentionally make detection independent from the running host:
# DOTFILES_TEST_UNAME, DOTFILES_TEST_OS_RELEASE, DOTFILES_TEST_OMARCHY_ROOT.
platform_detect() {
  OS=""
  DISTRO=""
  FLAVOR=""

  local kernel os_release omarchy_root
  kernel="${DOTFILES_TEST_UNAME:-$(uname -s)}"

  case "$kernel" in
    Darwin)
      OS="macos"
      ;;
    Linux)
      OS="linux"
      os_release="${DOTFILES_TEST_OS_RELEASE:-/etc/os-release}"
      if [[ ! -r "$os_release" ]]; then
        PLATFORM_ERROR="Linux detected but $os_release is unavailable"
        export OS DISTRO FLAVOR PLATFORM_ERROR
        return 1
      fi

      local ID="" ID_LIKE=""
      # os-release is a platform-owned shell-compatible data file.
      # shellcheck disable=SC1090
      source "$os_release"
      if [[ "${ID:-}" == "arch" ]]; then
        DISTRO="arch"
      else
        DISTRO="${ID:-unknown}"
      fi

      if [[ "$DISTRO" == "arch" ]]; then
        omarchy_root="${DOTFILES_TEST_OMARCHY_ROOT:-/usr/share/omarchy}"
        if [[ -x "$omarchy_root/bin/omarchy" ]] || {
          [[ -d "$omarchy_root" ]] && command -v omarchy >/dev/null 2>&1
        }; then
          FLAVOR="omarchy"
        fi
      fi
      ;;
    *)
      OS="unsupported"
      PLATFORM_ERROR="Unsupported operating system kernel: $kernel"
      export OS DISTRO FLAVOR PLATFORM_ERROR
      return 1
      ;;
  esac

  PLATFORM_ERROR=""
  export OS DISTRO FLAVOR PLATFORM_ERROR
}

platform_validate_supported() {
  case "${OS:-}:${DISTRO:-}:${FLAVOR:-}" in
    macos::) return 0 ;;
    linux:arch:omarchy) return 0 ;;
    linux:arch:)
      PLATFORM_ERROR="Arch Linux is detected, but this system supports Arch only when running Omarchy"
      ;;
    linux:*)
      PLATFORM_ERROR="Unsupported Linux distribution: ${DISTRO:-unknown}; expected Arch Linux running Omarchy"
      ;;
    *)
      PLATFORM_ERROR="${PLATFORM_ERROR:-Unsupported operating system}"
      ;;
  esac
  export PLATFORM_ERROR
  return 1
}

platform_label() {
  case "${OS:-}:${FLAVOR:-}" in
    macos:) printf 'macOS\n' ;;
    linux:omarchy) printf 'Arch Linux (Omarchy)\n' ;;
    linux:) printf 'Linux (%s)\n' "${DISTRO:-unknown}" ;;
    *) printf '%s\n' "${OS:-unknown}" ;;
  esac
}

