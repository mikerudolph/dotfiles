#!/usr/bin/env bash

github_cli_path() {
  type -P gh
}

ensure_legacy_github_shim_absent() {
  local destination="$1"
  # Older apply versions created this exact absolute symlink. Recognize it even
  # after the tracked shim has been deleted and its target no longer exists.
  if [[ -L "$destination" && "$(readlink "$destination")" == "$DOTFILES_ROOT/config/bin/gh" ]]; then
    if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
      report_add configure "remove the retired managed GitHub CLI shim"
    elif rm -- "$destination"; then
      report_add changed "removed the retired managed GitHub CLI shim"
    else
      report_conflict "Could not remove the retired managed GitHub CLI shim"
      return 1
    fi
  else
    report_add unchanged "retired GitHub CLI shim is absent or the destination is machine-local"
  fi
}

github_local_auth_configured() (
  local executable="$1"
  # Inspect local account metadata, without reading a token or contacting GitHub.
  unset GH_TOKEN GITHUB_TOKEN GH_ENTERPRISE_TOKEN GITHUB_ENTERPRISE_TOKEN
  "$executable" config get user --host github.com >/dev/null 2>&1
)

ensure_local_github_auth() {
  local executable
  executable="$(github_cli_path 2>/dev/null || true)"
  if [[ -n "$executable" ]] && github_local_auth_configured "$executable"; then
    report_add unchanged "GitHub CLI local account configuration"
  else
    report_manual "Provision local GitHub CLI authentication once with bin/provision-github-auth (or supply an op:// token reference)"
  fi
}

provision_local_github_auth() (
  set +x
  set -o pipefail
  umask 077
  local executable="$1" reference="${2:-}" directory ancestor suffix="" resolved protocol path
  unset GH_TOKEN GITHUB_TOKEN GH_ENTERPRISE_TOKEN GITHUB_ENTERPRISE_TOKEN
  directory="${GH_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/gh}"
  case "$directory" in
    /*) ;;
    *) echo "GitHub CLI's configuration directory must be an absolute path" >&2; return 1 ;;
  esac
  case "/$directory/" in
    */../*|*/./*) echo "GitHub CLI's configuration path must not contain dot segments" >&2; return 1 ;;
  esac
  ancestor="$directory"
  while [[ ! -d "$ancestor" ]]; do
    if [[ -e "$ancestor" || -L "$ancestor" ]]; then
      echo "GitHub CLI's configuration path is not a directory" >&2
      return 1
    fi
    suffix="/$(basename -- "$ancestor")$suffix"
    ancestor="$(dirname -- "$ancestor")"
  done
  resolved="$(CDPATH= cd -- "$ancestor" && pwd -P)$suffix"
  case "$resolved" in
    "$DOTFILES_ROOT"|"$DOTFILES_ROOT"/*)
      echo "GitHub credentials must be stored outside the dotfiles checkout" >&2
      return 1
      ;;
  esac
  for path in "$directory/hosts.yml" "$directory/config.yml"; do
    if [[ -L "$path" || ( -e "$path" && ! -f "$path" ) ]]; then
      echo "GitHub CLI configuration must use regular machine-local files" >&2
      return 1
    fi
  done
  if github_local_auth_configured "$executable"; then
    echo "GitHub CLI already has a local account; refusing to replace its credentials" >&2
    return 1
  fi
  if [[ -n "$reference" && "$reference" != op://* ]]; then
    echo "Expected an op://vault/item/token reference" >&2
    return 1
  fi
  [[ "${DOTFILES_DRY_RUN:-0}" != "1" ]] || return 0
  command -v op >/dev/null 2>&1 || { echo "1Password CLI is required for provisioning" >&2; return 1; }
  protocol="$("$executable" config get git_protocol --host github.com 2>/dev/null || true)"
  case "$protocol" in ssh|https) ;; *) protocol=https ;; esac

  # The token travels only over a pipe into gh's native login; it never enters
  # a shell variable, command argument, temporary file, or parent environment.
  # Put the native binary first so the legacy 1Password plugin cannot recurse.
  export PATH="$(dirname -- "$executable"):$PATH"
  if [[ -n "$reference" ]]; then
    if ! op read "$reference" 2>/dev/null |
        "$executable" auth login --hostname github.com --with-token --git-protocol "$protocol" >/dev/null 2>&1; then
      echo "Could not import the selected GitHub token; check vault access, token validity, and scopes" >&2
      return 1
    fi
  elif ! op plugin run -- gh auth token --hostname github.com 2>/dev/null |
      "$executable" auth login --hostname github.com --with-token --git-protocol "$protocol" >/dev/null 2>&1; then
    echo "Could not import the 1Password GitHub credential; check plugin setup or supply an op:// token reference" >&2
    return 1
  fi
)
