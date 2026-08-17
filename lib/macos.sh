#!/usr/bin/env bash

macos_architecture() {
  printf '%s\n' "${DOTFILES_TEST_ARCH:-$(uname -m)}"
}

ensure_macos_cask() {
  local label="$1" cask="$2" application_path="$3" command_name="${4:-}"
  local brew_path
  [[ "${OS:-}" == "macos" ]] || return 0

  if [[ -n "$application_path" && -d "$application_path" ]]; then
    report_add unchanged "$label"
    return 0
  fi
  if [[ -n "$command_name" ]] && command -v "$command_name" >/dev/null 2>&1; then
    report_add unchanged "$label"
    return 0
  fi
  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add install "$label ($cask cask via $(package_backend_name))"
    return 0
  fi

  brew_path="$(find_brew)" || {
    report_conflict "Homebrew is unavailable; cannot install $label"
    return 1
  }
  if ! "$brew_path" install --cask "$cask"; then
    report_conflict "$(package_backend_name) failed to install $label ($cask cask)"
    return 1
  fi
  report_add changed "installed $label"
}

_direct_app_bundle_id() {
  /usr/bin/plutil -extract CFBundleIdentifier raw "$1/Contents/Info.plist" 2>/dev/null
}

_direct_app_team_id() {
  /usr/bin/codesign -dvvv "$1" 2>&1 | /usr/bin/sed -n 's/^TeamIdentifier=//p' | /usr/bin/head -1
}

_copy_app_to_applications() {
  local source_app="$1" destination="$2"
  if [[ -w "$(dirname -- "$destination")" ]]; then
    /usr/bin/ditto "$source_app" "$destination"
  else
    sudo /usr/bin/ditto "$source_app" "$destination"
  fi
}

_install_direct_macos_app() {
  local label="$1" destination="$2" url="$3" archive_type="$4"
  local bundle_name="$5" expected_bundle_id="$6" expected_team_id="$7" expected_sha256="$8"
  local work_dir artifact mount_dir source_app actual_sha256 actual_bundle_id actual_team_id

  work_dir="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-app.XXXXXX")" || return 1
  artifact="$work_dir/download.$archive_type"
  mount_dir="$work_dir/mount"
  mkdir -p "$mount_dir"

  if ! curl --proto '=https' --tlsv1.2 --fail --location --silent --show-error \
      "$url" --output "$artifact"; then
    rm -rf -- "$work_dir"
    return 1
  fi

  if [[ -n "$expected_sha256" ]]; then
    actual_sha256="$(/usr/bin/shasum -a 256 "$artifact" | awk '{print $1}')"
    if [[ "$actual_sha256" != "$expected_sha256" ]]; then
      echo "$label download failed its SHA-256 check" >&2
      rm -rf -- "$work_dir"
      return 1
    fi
  fi

  case "$archive_type" in
    dmg)
      if ! /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mount_dir" "$artifact" >/dev/null; then
        rm -rf -- "$work_dir"
        return 1
      fi
      source_app="$mount_dir/$bundle_name"
      ;;
    zip)
      if ! /usr/bin/ditto -x -k "$artifact" "$mount_dir"; then
        rm -rf -- "$work_dir"
        return 1
      fi
      source_app="$mount_dir/$bundle_name"
      ;;
    *)
      echo "Unsupported direct application archive: $archive_type" >&2
      rm -rf -- "$work_dir"
      return 1
      ;;
  esac

  if [[ ! -d "$source_app" ]]; then
    [[ "$archive_type" == "dmg" ]] && /usr/bin/hdiutil detach "$mount_dir" >/dev/null 2>&1 || true
    rm -rf -- "$work_dir"
    return 1
  fi
  actual_bundle_id="$(_direct_app_bundle_id "$source_app")"
  if [[ "$actual_bundle_id" != "$expected_bundle_id" ]] || \
     ! /usr/bin/codesign --verify --deep --strict "$source_app" >/dev/null 2>&1; then
    [[ "$archive_type" == "dmg" ]] && /usr/bin/hdiutil detach "$mount_dir" >/dev/null 2>&1 || true
    rm -rf -- "$work_dir"
    return 1
  fi
  if [[ -n "$expected_team_id" ]]; then
    actual_team_id="$(_direct_app_team_id "$source_app")"
    if [[ "$actual_team_id" != "$expected_team_id" ]]; then
      [[ "$archive_type" == "dmg" ]] && /usr/bin/hdiutil detach "$mount_dir" >/dev/null 2>&1 || true
      rm -rf -- "$work_dir"
      return 1
    fi
  fi

  # Recheck immediately before the only write to avoid replacing an app that
  # appeared while the download was in progress.
  if [[ ! -e "$destination" ]]; then
    _copy_app_to_applications "$source_app" "$destination" || {
      [[ "$archive_type" == "dmg" ]] && /usr/bin/hdiutil detach "$mount_dir" >/dev/null 2>&1 || true
      rm -rf -- "$work_dir"
      return 1
    }
  fi

  [[ "$archive_type" == "dmg" ]] && /usr/bin/hdiutil detach "$mount_dir" >/dev/null 2>&1 || true
  rm -rf -- "$work_dir"
}

ensure_direct_macos_app() {
  local label="$1" application_path="$2" url="$3" archive_type="$4"
  local bundle_name="$5" bundle_id="$6" team_id="$7" sha256="$8"
  [[ "${OS:-}" == "macos" ]] || return 0

  if [[ -d "$application_path" ]]; then
    report_add unchanged "$label"
    return 0
  fi
  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add install "$label (verified $archive_type from $url)"
    return 0
  fi
  if _install_direct_macos_app "$label" "$application_path" "$url" "$archive_type" \
      "$bundle_name" "$bundle_id" "$team_id" "$sha256"; then
    report_add changed "installed $label"
  else
    report_conflict "Failed to download, verify, or install $label; no existing application was replaced"
    return 1
  fi
}

ensure_macos_app_store_app() {
  local label="$1" app_id="$2" application_path="$3"
  [[ "${OS:-}" == "macos" ]] || return 0
  if [[ -d "$application_path" ]]; then
    report_add unchanged "$label"
    return 0
  fi
  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add install "$label (Mac App Store application $app_id)"
    return 0
  fi
  if ! command -v mas >/dev/null 2>&1; then
    report_conflict "mas is unavailable; cannot install $label"
    return 1
  fi
  if mas get "$app_id"; then
    report_add changed "installed $label from the Mac App Store"
  else
    report_manual "Sign in to the Mac App Store and install $label (App Store ID $app_id)"
  fi
}

ensure_command_line_tools() {
  [[ "${OS:-}" == "macos" ]] || return 0
  if xcode-select -p >/dev/null 2>&1; then
    report_add unchanged "Apple command-line developer tools"
    return 0
  fi
  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add install "Apple command-line developer tools (system installer)"
    report_manual "Complete Apple's Command Line Tools installation dialog and license agreement"
    return 0
  fi
  xcode-select --install >/dev/null 2>&1 || true
  report_manual "Complete Apple's Command Line Tools installation dialog and license agreement, then rerun apply"
}

ensure_xcode_developer_directory() {
  local expected="/Applications/Xcode.app/Contents/Developer" current
  [[ "${OS:-}" == "macos" ]] || return 0
  [[ -d "$expected" ]] || return 0
  current="$(xcode-select -p 2>/dev/null || true)"
  if [[ "$current" == "$expected" ]]; then
    report_add unchanged "Xcode developer directory"
  elif [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add configure "select $expected as the active developer directory"
  else
    sudo xcode-select --switch "$expected"
    report_add changed "selected Xcode developer directory"
  fi

  if ! "$expected/usr/bin/xcodebuild" -checkFirstLaunchStatus >/dev/null 2>&1; then
    report_manual "Open Xcode, accept its license, and complete first-launch component installation"
  fi
}

ensure_rosetta() {
  [[ "${OS:-}" == "macos" ]] || return 0
  [[ "$(macos_architecture)" == "arm64" ]] || {
    report_add unchanged "Rosetta (not applicable on Intel Mac)"
    return 0
  }
  if pkgutil --pkg-info com.apple.pkg.RosettaUpdateAuto >/dev/null 2>&1; then
    report_add unchanged "Rosetta"
    return 0
  fi
  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add install "Rosetta (Apple software update)"
    return 0
  fi
  sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license
  report_add changed "installed Rosetta"
}
