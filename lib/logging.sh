#!/usr/bin/env bash

report_init() {
  REPORT_INSTALL=()
  REPORT_LINK=()
  REPORT_CONFIGURE=()
  REPORT_DIRECTORY=()
  REPORT_MIGRATION=()
  REPORT_CONFLICT=()
  REPORT_MANUAL=()
  REPORT_CHANGED=()
  REPORT_UNCHANGED_COUNT=0
}

report_add() {
  local category="$1" message="$2"
  case "$category" in
    install) REPORT_INSTALL[${#REPORT_INSTALL[@]}]="$message" ;;
    link) REPORT_LINK[${#REPORT_LINK[@]}]="$message" ;;
    configure) REPORT_CONFIGURE[${#REPORT_CONFIGURE[@]}]="$message" ;;
    directory) REPORT_DIRECTORY[${#REPORT_DIRECTORY[@]}]="$message" ;;
    migration) REPORT_MIGRATION[${#REPORT_MIGRATION[@]}]="$message" ;;
    conflict) REPORT_CONFLICT[${#REPORT_CONFLICT[@]}]="$message" ;;
    manual) REPORT_MANUAL[${#REPORT_MANUAL[@]}]="$message" ;;
    changed) REPORT_CHANGED[${#REPORT_CHANGED[@]}]="$message" ;;
    unchanged) REPORT_UNCHANGED_COUNT=$((REPORT_UNCHANGED_COUNT + 1)) ;;
    *) echo "Unknown report category: $category" >&2; return 1 ;;
  esac
}

report_conflict() {
  report_add conflict "$1"
}

report_manual() {
  local message="$1" existing
  for existing in "${REPORT_MANUAL[@]-}"; do
    [[ "$existing" == "$message" ]] && return 0
  done
  report_add manual "$message"
}

report_section() {
  local heading="$1"
  shift
  (( $# > 0 )) || return 0
  printf '%s\n' "$heading"
  local item
  for item in "$@"; do
    printf '  %s\n' "$item"
  done
  printf '\n'
}

report_render() {
  printf 'Platform\n  %s\n\n' "$(platform_label)"
  report_section "Would install" ${REPORT_INSTALL[@]+"${REPORT_INSTALL[@]}"}
  report_section "Would create directories" ${REPORT_DIRECTORY[@]+"${REPORT_DIRECTORY[@]}"}
  report_section "Would link" ${REPORT_LINK[@]+"${REPORT_LINK[@]}"}
  report_section "Would configure" ${REPORT_CONFIGURE[@]+"${REPORT_CONFIGURE[@]}"}
  report_section "Would run migrations" ${REPORT_MIGRATION[@]+"${REPORT_MIGRATION[@]}"}
  report_section "Applied" ${REPORT_CHANGED[@]+"${REPORT_CHANGED[@]}"}
  report_section "Conflicts" ${REPORT_CONFLICT[@]+"${REPORT_CONFLICT[@]}"}
  report_section "Manual action required" ${REPORT_MANUAL[@]+"${REPORT_MANUAL[@]}"}

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    printf 'No changes made.\n'
  elif (( ${#REPORT_CONFLICT[@]} == 0 )); then
    printf 'Dotfiles are reconciled.\n'
  else
    printf 'Reconciliation completed with conflicts; unmanaged files were left untouched.\n'
  fi
}
