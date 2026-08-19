#!/usr/bin/env bash

macos_defaults_init() {
  MACOS_DEFAULT_RESTARTS=()
  MACOS_DEFAULTS_DIRTY=0
}

_normalize_macos_default() {
  local type="$1" value="$2"
  case "$type" in
    bool)
      case "$value" in
        1|true|TRUE|yes|YES) printf '1\n' ;;
        0|false|FALSE|no|NO) printf '0\n' ;;
        *) printf '%s\n' "$value" ;;
      esac
      ;;
    int|string|float) printf '%s\n' "$value" ;;
    *) return 1 ;;
  esac
}

queue_macos_default_restart() {
  local process="$1" existing
  [[ -n "$process" ]] || return 0
  for existing in "${MACOS_DEFAULT_RESTARTS[@]-}"; do
    [[ "$existing" == "$process" ]] && return 0
  done
  MACOS_DEFAULT_RESTARTS[${#MACOS_DEFAULT_RESTARTS[@]}]="$process"
}

_ensure_macos_default() {
  local scope="$1" label="$2" domain="$3" key="$4" type="$5" desired="$6" restart_process="${7:-}"
  local current normalized_current normalized_desired
  [[ "${OS:-}" == "macos" ]] || return 0

  normalized_desired="$(_normalize_macos_default "$type" "$desired")" || {
    report_conflict "Unsupported macOS default type '$type' for $label"
    return 1
  }
  if [[ "$scope" == "host" ]]; then
    current="$(defaults -currentHost read "$domain" "$key" 2>/dev/null || true)"
  else
    current="$(defaults read "$domain" "$key" 2>/dev/null || true)"
  fi
  normalized_current="$(_normalize_macos_default "$type" "$current" 2>/dev/null || printf '%s\n' "$current")"
  if [[ "$normalized_current" == "$normalized_desired" ]]; then
    report_add unchanged "$label"
    return 0
  fi

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add configure "$label ($domain $key = $desired)"
    MACOS_DEFAULTS_DIRTY=1
    queue_macos_default_restart "$restart_process"
    return 0
  fi
  local -a defaults_command=(defaults)
  [[ "$scope" == "host" ]] && defaults_command+=(-currentHost)
  if "${defaults_command[@]}" write "$domain" "$key" "-$type" "$desired"; then
    report_add changed "configured $label"
    MACOS_DEFAULTS_DIRTY=1
    queue_macos_default_restart "$restart_process"
  else
    report_conflict "Failed to configure macOS default: $label"
    return 1
  fi
}

ensure_macos_default() {
  _ensure_macos_default user "$@"
}

ensure_macos_host_default() {
  _ensure_macos_default host "$@"
}

_macos_symbolic_hotkey_field() {
  local plist="$1" hotkey_id="$2" field="$3"
  printf '%s' "$plist" |
    plutil -extract "AppleSymbolicHotKeys.$hotkey_id.$field" raw -o - - 2>/dev/null
}

ensure_macos_symbolic_hotkey() {
  local label="$1" hotkey_id="$2" keycode="$3" modifiers="$4"
  local plist enabled type first second third payload
  [[ "${OS:-}" == "macos" ]] || return 0

  plist="$(defaults export com.apple.symbolichotkeys - 2>/dev/null || true)"
  enabled="$(_macos_symbolic_hotkey_field "$plist" "$hotkey_id" enabled || true)"
  type="$(_macos_symbolic_hotkey_field "$plist" "$hotkey_id" value.type || true)"
  first="$(_macos_symbolic_hotkey_field "$plist" "$hotkey_id" value.parameters.0 || true)"
  second="$(_macos_symbolic_hotkey_field "$plist" "$hotkey_id" value.parameters.1 || true)"
  third="$(_macos_symbolic_hotkey_field "$plist" "$hotkey_id" value.parameters.2 || true)"

  if [[ "$enabled" == "true" && "$type" == "standard" && "$first" == "65535" && \
        "$second" == "$keycode" && "$third" == "$modifiers" ]]; then
    report_add unchanged "$label"
    return 0
  fi

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add configure "$label (macOS symbolic hotkey $hotkey_id)"
    MACOS_DEFAULTS_DIRTY=1
    return 0
  fi

  payload="<dict><key>enabled</key><true/><key>value</key><dict><key>parameters</key><array><integer>65535</integer><integer>$keycode</integer><integer>$modifiers</integer></array><key>type</key><string>standard</string></dict></dict>"
  if defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add "$hotkey_id" "$payload"; then
    report_add changed "configured $label"
    MACOS_DEFAULTS_DIRTY=1
  else
    report_conflict "Failed to configure macOS keyboard shortcut: $label"
    return 1
  fi
}

macos_main_user_space_count() {
  if [[ -n "${DOTFILES_TEST_SPACE_COUNT:-}" ]]; then
    printf '%s\n' "$DOTFILES_TEST_SPACE_COUNT"
    return 0
  fi

  local plist index identifier spaces
  plist="$(defaults export com.apple.spaces - 2>/dev/null || true)"
  [[ -n "$plist" ]] || return 1
  for index in 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
    identifier="$(printf '%s' "$plist" |
      plutil -extract "SpacesDisplayConfiguration.Management Data.Monitors.$index.Display Identifier" \
        raw -o - - 2>/dev/null || true)"
    [[ "$identifier" == "Main" ]] || continue
    spaces="$(printf '%s' "$plist" |
      plutil -extract "SpacesDisplayConfiguration.Management Data.Monitors.$index.Spaces" \
        xml1 -o - - 2>/dev/null || true)"
    [[ -n "$spaces" ]] || return 1
    printf '%s\n' "$spaces" | awk '
      previous_type && /<integer>0<\/integer>/ { count++ }
      { previous_type = /<key>type<\/key>/ }
      END { print count + 0 }
    '
    return 0
  done
  return 1
}

check_macos_workspace_count() {
  local desired="$1" count
  [[ "${OS:-}" == "macos" ]] || return 0
  count="$(macos_main_user_space_count 2>/dev/null || true)"
  if [[ -z "$count" || "$count" -lt "$desired" ]]; then
    report_manual \
      "Create $desired Desktop Spaces in Mission Control; Command-1 through Command-$desired are already managed"
  else
    report_add unchanged "$desired Desktop Spaces are available"
  fi
}

ensure_macos_dark_mode() {
  local label="$1" desired="$2" current
  [[ "${OS:-}" == "macos" ]] || return 0
  desired="$(_normalize_macos_default bool "$desired")" || return 1
  current="$(defaults read NSGlobalDomain AppleInterfaceStyle 2>/dev/null || true)"
  if [[ "$current" == "Dark" ]]; then current=1; else current=0; fi
  if [[ "$current" == "$desired" ]]; then
    report_add unchanged "$label"
    return 0
  fi

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add configure "$label (dark mode = $desired)"
    MACOS_DEFAULTS_DIRTY=1
    return 0
  fi
  if osascript -e "tell application \"System Events\" to tell appearance preferences to set dark mode to $([[ "$desired" == 1 ]] && printf true || printf false)"; then
    report_add changed "configured $label"
    MACOS_DEFAULTS_DIRTY=1
  else
    report_conflict "Failed to configure macOS appearance: $label"
    report_manual "Set Appearance to Dark in System Settings, then rerun apply"
    return 1
  fi
}

ensure_macos_wallpaper() {
  local label="$1" source="$2" script current
  [[ "${OS:-}" == "macos" ]] || return 0
  script="$DOTFILES_ROOT/platform/macos/wallpaper.applescript"

  if [[ ! -f "$source" ]]; then
    report_conflict "$label source is missing: $source"
    return 1
  fi
  if [[ ! -f "$script" ]]; then
    report_conflict "$label helper is missing: $script"
    return 1
  fi

  current="$(osascript "$script" check "$source" 2>/dev/null || true)"
  if [[ "$current" == "true" ]]; then
    report_add unchanged "$label"
    return 0
  fi

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add configure "$label ($source on every Desktop Space)"
    return 0
  fi

  if [[ "$(osascript "$script" set "$source" 2>/dev/null || true)" == "true" ]]; then
    report_add changed "configured $label"
  else
    report_conflict "Failed to configure $label"
    report_manual "Set $source as the wallpaper on all Spaces in System Settings"
    return 1
  fi
}

macos_path_flags() {
  if [[ -n "${DOTFILES_TEST_PATH_FLAGS+x}" ]]; then
    printf '%s\n' "$DOTFILES_TEST_PATH_FLAGS"
  else
    /usr/bin/stat -f '%Sf' "$1"
  fi
}

ensure_macos_visible_directory() {
  local label="$1" path="$2" flags
  [[ "${OS:-}" == "macos" ]] || return 0
  if [[ ! -d "$path" ]]; then
    report_conflict "$label cannot be configured because $path is not a directory"
    return 1
  fi
  flags="$(macos_path_flags "$path" 2>/dev/null || true)"
  if [[ "$flags" != *hidden* ]]; then
    report_add unchanged "$label"
    return 0
  fi
  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add configure "$label ($path)"
    MACOS_DEFAULTS_DIRTY=1
    queue_macos_default_restart Finder
    return 0
  fi
  if chflags nohidden "$path"; then
    report_add changed "configured $label"
    MACOS_DEFAULTS_DIRTY=1
    queue_macos_default_restart Finder
  else
    report_conflict "Failed to configure $label"
    return 1
  fi
}

ensure_macos_capslock_control() {
  local label="Caps Lock as Control" helper
  [[ "${OS:-}" == "macos" ]] || return 0
  helper="$DOTFILES_ROOT/platform/macos/capslock-control.sh"

  if [[ ! -x "$helper" ]]; then
    report_conflict "$label helper is missing or not executable: $helper"
    return 1
  fi
  if "$helper" check >/dev/null 2>&1; then
    report_add unchanged "$label"
    return 0
  fi
  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add configure "$label for all keyboards"
    return 0
  fi
  if "$helper" apply; then
    report_add changed "configured $label"
  else
    report_conflict "Failed to configure $label"
    return 1
  fi
}

apply_macos_default_restarts() {
  local process
  [[ "${OS:-}" == "macos" ]] || return 0
  for process in "${MACOS_DEFAULT_RESTARTS[@]-}"; do
    [[ -n "$process" ]] || continue
    if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
      report_add configure "restart $process to load changed macOS defaults"
    elif pgrep -x "$process" >/dev/null 2>&1; then
      killall "$process"
      report_add changed "restarted $process"
    fi
  done
}
