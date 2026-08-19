#!/usr/bin/env bash

onepassword_desktop_present() {
  case "${OS:-}:${FLAVOR:-}" in
    macos:)
      [[ -d /Applications/1Password.app || -d "$HOME/Applications/1Password.app" ]]
      ;;
    linux:omarchy)
      command -v 1password >/dev/null 2>&1 || [[ -x /opt/1Password/1password ]]
      ;;
    *) return 1 ;;
  esac
}

onepassword_manual_guidance() {
  if ! onepassword_desktop_present; then
    report_manual "Install, sign in to, and unlock the 1Password desktop app before setup"
    return 0
  fi
  case "${OS:-}:${FLAVOR:-}" in
    macos:)
      report_manual "In 1Password Settings > Developer, confirm 'Integrate with 1Password CLI' is enabled"
      ;;
    linux:omarchy)
      report_manual "In 1Password Settings > Security enable system authentication, then in Developer enable CLI integration; a PolKit agent must be running"
      ;;
  esac
  report_manual "Run 'op plugin init gh' once and choose a global GitHub credential; the managed gh shim replaces the shell alias"
}
