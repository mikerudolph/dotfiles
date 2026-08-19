#!/usr/bin/env bash

canonical_existing_path() {
  local path="$1" parent base
  parent="$(dirname -- "$path")"
  base="$(basename -- "$path")"
  [[ -d "$parent" ]] || return 1
  parent="$(CDPATH= cd -- "$parent" && pwd -P)" || return 1
  printf '%s/%s\n' "$parent" "$base"
}

symlink_target_path() {
  local destination="$1" target
  [[ -L "$destination" ]] || return 1
  target="$(readlink "$destination")" || return 1
  case "$target" in
    /*) ;;
    *) target="$(dirname -- "$destination")/$target" ;;
  esac
  canonical_existing_path "$target"
}

is_managed() {
  local destination="$1" target
  target="$(symlink_target_path "$destination" 2>/dev/null)" || return 1
  case "$target" in
    "$DOTFILES_ROOT"|"$DOTFILES_ROOT"/*) return 0 ;;
    *) return 1 ;;
  esac
}

ensure_directory() {
  local destination="$1" pretty
  pretty="$(dotfiles_pretty_path "$destination")"
  if [[ -d "$destination" && ! -L "$destination" ]]; then
    report_add unchanged "$pretty"
    return 0
  fi
  if [[ -e "$destination" || -L "$destination" ]]; then
    report_conflict "$pretty exists and is not a directory managed by dotfiles"
    return 1
  fi

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add directory "$pretty"
  else
    mkdir -p "$destination"
    report_add changed "created directory $pretty"
  fi
}

ensure_symlink() {
  local source="$1" destination="$2" label="${3:-}" pretty current desired
  pretty="$(dotfiles_pretty_path "$destination")"
  [[ -n "$label" ]] || label="$pretty"

  if [[ ! -e "$source" ]]; then
    report_conflict "$label source is missing: $source"
    return 1
  fi
  desired="$(canonical_existing_path "$source")" || {
    report_conflict "$label source cannot be resolved: $source"
    return 1
  }

  if [[ -L "$destination" ]]; then
    if ! is_managed "$destination"; then
      report_conflict "$pretty exists but is not managed by dotfiles"
      return 1
    fi
    current="$(symlink_target_path "$destination")"
    if [[ "$current" == "$desired" ]]; then
      report_add unchanged "$pretty"
      return 0
    fi
  elif [[ -e "$destination" ]]; then
    report_conflict "$pretty exists but is not managed by dotfiles"
    return 1
  fi

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add link "$pretty -> $source"
  else
    mkdir -p "$(dirname -- "$destination")"
    ln -sfn "$source" "$destination"
    report_add changed "linked $pretty"
  fi
}

managed_block_text() {
  local block_id="$1" content="$2" comment_prefix="${3:-#}"
  printf '%s >>> dotfiles:%s >>>\n%s\n%s <<< dotfiles:%s <<<\n' \
    "$comment_prefix" "$block_id" "$content" "$comment_prefix" "$block_id"
}

ensure_source_block() {
  local destination="$1" block_id="$2" content="$3" label="${4:-}" comment_prefix="${5:-#}" pretty
  local start end start_count end_count expected current temp mode
  pretty="$(dotfiles_pretty_path "$destination")"
  [[ -n "$label" ]] || label="$pretty"
  start="$comment_prefix >>> dotfiles:$block_id >>>"
  end="$comment_prefix <<< dotfiles:$block_id <<<"
  expected="$(managed_block_text "$block_id" "$content" "$comment_prefix")"

  if [[ -L "$destination" || ( -e "$destination" && ! -f "$destination" ) ]]; then
    report_conflict "$pretty is not a regular machine-local file; refusing to add a managed block"
    return 1
  fi

  if [[ -f "$destination" ]]; then
    start_count="$(grep -Fxc -- "$start" "$destination" 2>/dev/null || true)"
    end_count="$(grep -Fxc -- "$end" "$destination" 2>/dev/null || true)"
    if [[ "$start_count" != "$end_count" || "$start_count" -gt 1 ]]; then
      report_conflict "$pretty has malformed dotfiles block markers for $block_id"
      return 1
    fi
    if [[ "$start_count" == "1" ]]; then
      current="$(awk -v start="$start" -v end="$end" '
        $0 == start { capture=1 }
        capture { print }
        $0 == end && capture { exit }
      ' "$destination")"
      if [[ "$current" == "$expected" ]]; then
        report_add unchanged "$pretty ($block_id block)"
        return 0
      fi
      if [[ "$current" != *"$end" ]]; then
        report_conflict "$pretty has an unterminated dotfiles block for $block_id"
        return 1
      fi
    fi
  else
    start_count=0
  fi

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add configure "$label (managed block in $pretty)"
    return 0
  fi

  mkdir -p "$(dirname -- "$destination")"
  temp="$(mktemp "$(dirname -- "$destination")/.dotfiles-block.XXXXXX")"
  if [[ -f "$destination" ]]; then
    if stat -f '%Lp' "$destination" >/dev/null 2>&1; then
      mode="$(stat -f '%Lp' "$destination")"
    else
      mode="$(stat -c '%a' "$destination")"
    fi

    if [[ "$start_count" == "1" ]]; then
      DOTFILES_BLOCK_REPLACEMENT="$expected" awk -v start="$start" -v end="$end" '
        $0 == start {
          count=split(ENVIRON["DOTFILES_BLOCK_REPLACEMENT"], lines, "\n")
          for (i=1; i<=count; i++) print lines[i]
          skipping=1
          next
        }
        skipping && $0 == end { skipping=0; next }
        !skipping { print }
      ' "$destination" >"$temp"
    else
      awk '1' "$destination" >"$temp"
      [[ ! -s "$destination" ]] || printf '\n' >>"$temp"
      printf '%s\n' "$expected" >>"$temp"
    fi
    chmod "$mode" "$temp"
  else
    printf '%s\n' "$expected" >"$temp"
    chmod 644 "$temp"
  fi
  mv "$temp" "$destination"
  report_add changed "configured $label in $pretty"
}

ensure_git_include() {
  local source="$1" destination="$2" pretty includes include
  pretty="$(dotfiles_pretty_path "$destination")"

  if [[ -L "$destination" || ( -e "$destination" && ! -f "$destination" ) ]]; then
    report_conflict "$pretty is not a regular machine-local Git config"
    return 1
  fi
  if [[ -f "$destination" ]] && ! git config --file "$destination" --list >/dev/null 2>&1; then
    report_conflict "$pretty is not valid Git configuration; refusing to modify it"
    return 1
  fi

  includes="$(git config --file "$destination" --get-all include.path 2>/dev/null || true)"
  while IFS= read -r include; do
    if [[ "$include" == "$source" ]]; then
      report_add unchanged "$pretty (Git include)"
      return 0
    fi
  done <<<"$includes"

  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    report_add configure "$pretty: include $source"
  else
    mkdir -p "$(dirname -- "$destination")"
    touch "$destination"
    git config --file "$destination" --add include.path "$source"
    report_add changed "added shared include to $pretty"
  fi
}
