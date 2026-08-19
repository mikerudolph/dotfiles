#!/usr/bin/env bash
set -euo pipefail

# hidutil's global UserKeyMapping applies to every keyboard but lasts only for
# the login session. This helper merges the one mapping owned by dotfiles and
# leaves every unrelated mapping intact.
HIDUTIL_BIN="${DOTFILES_TEST_HIDUTIL_BIN:-/usr/bin/hidutil}"
PLUTIL_BIN="${DOTFILES_TEST_PLUTIL_BIN:-/usr/bin/plutil}"
CAPS_LOCK_USAGE=30064771129 # 0x700000039
LEFT_CONTROL_USAGE=30064771296 # 0x7000000e0
TEMPORARY_DIRECTORY=""

usage() {
  echo "Usage: capslock-control.sh check|apply" >&2
  exit 2
}

load_mapping_plist() {
  local destination="$1" current
  if ! current="$($HIDUTIL_BIN property --get UserKeyMapping 2>/dev/null)"; then
    echo "Unable to read the current macOS keyboard mapping" >&2
    return 1
  fi

  if [[ -z "$current" || "$current" == "(null)" ]]; then
    printf '[]' | "$PLUTIL_BIN" -convert xml1 -o "$destination" -- -
  else
    printf '%s\n' "$current" | "$PLUTIL_BIN" -convert xml1 -o "$destination" -- -
  fi
}

mapping_status() {
  local plist="$1" index=0 source destination found=0
  while "$PLUTIL_BIN" -extract "$index" xml1 -o /dev/null "$plist" >/dev/null 2>&1; do
    source="$($PLUTIL_BIN -extract "$index.HIDKeyboardModifierMappingSrc" raw -o - "$plist" 2>/dev/null || true)"
    if [[ "$source" == "$CAPS_LOCK_USAGE" ]]; then
      found=1
      destination="$($PLUTIL_BIN -extract "$index.HIDKeyboardModifierMappingDst" raw -o - "$plist" 2>/dev/null || true)"
      [[ "$destination" == "$LEFT_CONTROL_USAGE" ]] || return 1
    fi
    index=$((index + 1))
  done
  [[ "$found" == "1" ]]
}

merge_mapping() {
  local plist="$1" index=0 source found=0 mapping_json
  while "$PLUTIL_BIN" -extract "$index" xml1 -o /dev/null "$plist" >/dev/null 2>&1; do
    source="$($PLUTIL_BIN -extract "$index.HIDKeyboardModifierMappingSrc" raw -o - "$plist" 2>/dev/null || true)"
    if [[ "$source" == "$CAPS_LOCK_USAGE" ]]; then
      found=1
      "$PLUTIL_BIN" -replace "$index.HIDKeyboardModifierMappingDst" \
        -integer "$LEFT_CONTROL_USAGE" "$plist"
    fi
    index=$((index + 1))
  done

  if [[ "$found" == "0" ]]; then
    "$PLUTIL_BIN" -insert "$index" -json \
      "{\"HIDKeyboardModifierMappingSrc\":$CAPS_LOCK_USAGE,\"HIDKeyboardModifierMappingDst\":$LEFT_CONTROL_USAGE}" \
      "$plist"
  fi

  mapping_json="$($PLUTIL_BIN -convert json -o - "$plist")"
  "$HIDUTIL_BIN" property --set "{\"UserKeyMapping\":$mapping_json}" >/dev/null
}

main() {
  local operation="${1:-}" plist
  [[ "$operation" == "check" || "$operation" == "apply" ]] || usage
  [[ -x "$HIDUTIL_BIN" ]] || { echo "hidutil is unavailable" >&2; return 1; }
  [[ -x "$PLUTIL_BIN" ]] || { echo "plutil is unavailable" >&2; return 1; }

  TEMPORARY_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-keyboard.XXXXXX")"
  trap '[[ -z "$TEMPORARY_DIRECTORY" ]] || rm -rf -- "$TEMPORARY_DIRECTORY"' EXIT
  plist="$TEMPORARY_DIRECTORY/UserKeyMapping.plist"
  load_mapping_plist "$plist"

  if [[ "$operation" == "check" ]]; then
    mapping_status "$plist"
  else
    merge_mapping "$plist"
  fi
}

main "$@"
