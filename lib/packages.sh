#!/usr/bin/env bash

workbrew_brew_path() {
  printf '%s\n' "${DOTFILES_WORKBREW_BREW:-/opt/workbrew/bin/brew}"
}

workbrew_is_present() {
  local path
  path="$(workbrew_brew_path)"
  [[ -e "$path" || -L "$path" ]]
}

find_brew() {
  local workbrew_path
  workbrew_path="$(workbrew_brew_path)"
  if workbrew_is_present; then
    [[ -x "$workbrew_path" ]] || return 126
    printf '%s\n' "$workbrew_path"
    return 0
  fi
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi
  local candidate
  for candidate in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  done
  return 1
}

brew_backend_name() {
  local brew_path workbrew_path
  workbrew_path="$(workbrew_brew_path)"
  if workbrew_is_present; then
    printf 'Workbrew\n'
    return 0
  fi
  brew_path="$(find_brew 2>/dev/null)" || { printf 'Homebrew\n'; return 0; }
  if [[ "$brew_path" == "$workbrew_path" ]]; then
    printf 'Workbrew\n'
  else
    printf 'Homebrew\n'
  fi
}

find_omarchy_package_helper() {
  if command -v omarchy-pkg-add >/dev/null 2>&1; then
    command -v omarchy-pkg-add
  elif [[ -x /usr/share/omarchy/bin/omarchy-pkg-add ]]; then
    printf '/usr/share/omarchy/bin/omarchy-pkg-add\n'
  else
    return 1
  fi
}

package_backend_name() {
  case "${OS:-}:${FLAVOR:-}" in
    macos:) brew_backend_name ;;
    linux:omarchy) printf 'Omarchy package helper\n' ;;
    *) printf 'unsupported\n' ;;
  esac
}

ensure_package() {
  local label="$1" command_name="$2" macos_package="$3" omarchy_package="$4"
  local package helper
  if command -v "$command_name" >/dev/null 2>&1; then
    report_add unchanged "$label"
    return 0
  fi

  case "${OS:-}:${FLAVOR:-}" in
    macos:) package="$macos_package" ;;
    linux:omarchy) package="$omarchy_package" ;;
    *) report_conflict "No supported package backend is available for $label"; return 1 ;;
  esac

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add install "$label ($package via $(package_backend_name))"
    return 0
  fi

  case "${OS:-}:${FLAVOR:-}" in
    macos:)
      helper="$(find_brew)" || {
        report_conflict "Homebrew is unavailable; run ./setup before apply"
        return 1
      }
      if ! "$helper" install "$package"; then
        report_conflict "$(package_backend_name) failed to install $label ($package)"
        return 1
      fi
      ;;
    linux:omarchy)
      helper="$(find_omarchy_package_helper)" || {
        report_conflict "Omarchy's package helper is unavailable"
        return 1
      }
      if ! "$helper" "$package"; then
        report_conflict "Omarchy's package helper failed to install $label ($package)"
        return 1
      fi
      ;;
  esac
  report_add changed "installed $label"
}

activate_brew_environment() {
  local brew_path environment
  brew_path="$(find_brew)" || return 1
  environment="$("$brew_path" shellenv)" || return 1
  eval "$environment"
}

bootstrap_package_backend() {
  local dry_run="${1:-0}" installer brew_path
  case "${OS:-}:${FLAVOR:-}" in
    macos:)
      if find_brew >/dev/null 2>&1; then
        activate_brew_environment || {
          echo "The detected $(brew_backend_name) installation could not initialize its shell environment" >&2
          return 1
        }
        return 0
      fi
      if workbrew_is_present; then
        echo "Workbrew is installed at $(workbrew_brew_path), but this user cannot execute its managed brew wrapper" >&2
        echo "Request Workbrew access instead of installing or bypassing it with vanilla Homebrew" >&2
        return 1
      fi
      if [[ "$dry_run" == "1" ]]; then
        printf 'Would install Homebrew from its official installer.\n'
        return 0
      fi
      command -v curl >/dev/null 2>&1 || {
        echo "curl is required to install Homebrew" >&2
        return 1
      }
      installer="$(mktemp "${TMPDIR:-/tmp}/dotfiles-homebrew.XXXXXX")"
      curl -fsSLo "$installer" https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh
      /bin/bash "$installer"
      rm -f "$installer"
      brew_path="$(find_brew)" || {
        echo "Homebrew installed but its executable could not be located" >&2
        return 1
      }
      activate_brew_environment
      ;;
    linux:omarchy)
      find_omarchy_package_helper >/dev/null 2>&1 || {
        echo "Omarchy's supported package helper (omarchy-pkg-add) is unavailable" >&2
        return 1
      }
      ;;
  esac
}
