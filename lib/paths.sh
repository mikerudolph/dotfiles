#!/usr/bin/env bash

# Central path initialization. Entry points set DOTFILES_ROOT from their own
# location before sourcing this file, so the checkout can live anywhere.
dotfiles_paths_init() {
  if [[ -z "${DOTFILES_ROOT:-}" || ! -d "$DOTFILES_ROOT/lib" ]]; then
    echo "DOTFILES_ROOT does not identify a dotfiles checkout" >&2
    return 1
  fi

  DOTFILES_ROOT="$(CDPATH= cd -- "$DOTFILES_ROOT" && pwd -P)"
  DOTFILES_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
  DOTFILES_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
  DOTFILES_XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
  DOTFILES_STATE_HOME="$DOTFILES_XDG_STATE_HOME/dotfiles"
  DOTFILES_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}/dotfiles"

  export DOTFILES_ROOT DOTFILES_CONFIG_HOME DOTFILES_DATA_HOME
  export DOTFILES_XDG_STATE_HOME DOTFILES_STATE_HOME DOTFILES_CACHE_HOME
}

dotfiles_pretty_path() {
  case "$1" in
    "$HOME") printf '~\n' ;;
    "$HOME"/*) printf '~/%s\n' "${1#"$HOME"/}" ;;
    *) printf '%s\n' "$1" ;;
  esac
}
