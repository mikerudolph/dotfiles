#!/usr/bin/env bash

mise_tool_is_installed() {
  local tool="$1" version="$2"
  command -v mise >/dev/null 2>&1 || return 1
  mise where "$tool@$version" >/dev/null 2>&1
}

ensure_mise_tool() {
  local label="$1" tool="$2" version="$3"
  if mise_tool_is_installed "$tool" "$version"; then
    report_add unchanged "$label ($tool@$version via mise)"
    return 0
  fi

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add install "$label ($tool@$version via mise)"
    return 0
  fi
  if ! command -v mise >/dev/null 2>&1; then
    report_conflict "mise is unavailable; cannot install $label"
    return 1
  fi

  mise install "$tool@$version"
  report_add changed "installed $label with mise"
}

