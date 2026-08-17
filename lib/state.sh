#!/usr/bin/env bash

migration_state_directory() {
  printf '%s/migrations\n' "$DOTFILES_STATE_HOME"
}

migration_marker() {
  printf '%s/%s.done\n' "$(migration_state_directory)" "$(basename -- "$1" .sh)"
}

migration_is_complete() {
  [[ -f "$(migration_marker "$1")" ]]
}

