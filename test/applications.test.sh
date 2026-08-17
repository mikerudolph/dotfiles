#!/usr/bin/env bash
set -euo pipefail
source "$ROOT/test/helpers.sh"
source "$ROOT/lib/macos.sh"
source "$ROOT/packages/macos.sh"

APP_DECLARATIONS=()
MANUAL_DECLARATIONS=()

declare_direct_macos_app() {
  APP_DECLARATIONS[${#APP_DECLARATIONS[@]}]="direct:$1:$3"
}

declare_macos_cask() {
  APP_DECLARATIONS[${#APP_DECLARATIONS[@]}]="cask:$1:$2"
}

report_manual() {
  MANUAL_DECLARATIONS[${#MANUAL_DECLARATIONS[@]}]="$1"
}

OS=linux
FLAVOR=omarchy
desired_macos_applications
assert_eq 0 "${#APP_DECLARATIONS[@]}" "macOS applications leaked into Omarchy"

OS=macos
FLAVOR=""
DOTFILES_TEST_ARCH=x86_64
desired_macos_applications
assert_eq 11 "${#APP_DECLARATIONS[@]}" "Intel macOS application count"
printf '%s\n' "${APP_DECLARATIONS[@]}" | grep -Fq 'cask:ChatGPT:chatgpt' || \
  fail "Intel ChatGPT did not use the architecture-aware cask"

APP_DECLARATIONS=()
MANUAL_DECLARATIONS=()
DOTFILES_TEST_ARCH=arm64
desired_macos_applications
assert_eq 11 "${#APP_DECLARATIONS[@]}" "Apple silicon application count"
printf '%s\n' "${APP_DECLARATIONS[@]}" | grep -Fq \
  'direct:ChatGPT:https://persistent.oaistatic.com/codex-app-prod/Codex.dmg' || \
  fail "Apple silicon ChatGPT did not use OpenAI's current direct download"
printf '%s\n' "${APP_DECLARATIONS[@]}" | grep -Fq \
  'direct:Alacritty:https://github.com/alacritty/alacritty/releases/download/v0.17.0/Alacritty-v0.17.0.dmg' || \
  fail "Alacritty release URL is not declared"
printf '%s\n' "${APP_DECLARATIONS[@]}" | grep -Fq 'cask:Dropbox:dropbox' || \
  fail "Dropbox cask is not declared"
