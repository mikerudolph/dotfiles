#!/usr/bin/env bash

run_pending_migrations() {
  local migration marker temporary
  for migration in "$DOTFILES_ROOT"/migrations/*.sh; do
    [[ -f "$migration" ]] || continue
    if migration_is_complete "$migration"; then
      report_add unchanged "migration $(basename -- "$migration")"
      continue
    fi

    if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
      report_add migration "$(basename -- "$migration")"
      continue
    fi

    DOTFILES_ROOT="$DOTFILES_ROOT" \
      DOTFILES_STATE_HOME="$DOTFILES_STATE_HOME" \
      bash "$migration"
    marker="$(migration_marker "$migration")"
    mkdir -p "$(dirname -- "$marker")"
    temporary="$marker.tmp.$$"
    : >"$temporary"
    mv "$temporary" "$marker"
    report_add changed "ran migration $(basename -- "$migration")"
  done
}

migration_counts() {
  local total=0 complete=0 migration
  for migration in "$DOTFILES_ROOT"/migrations/*.sh; do
    [[ -f "$migration" ]] || continue
    total=$((total + 1))
    migration_is_complete "$migration" && complete=$((complete + 1))
  done
  printf '%s %s\n' "$complete" "$total"
}

