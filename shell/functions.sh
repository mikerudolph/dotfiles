# Open Neovim in the current directory when no path is supplied.
n() {
  if (( $# == 0 )); then
    command nvim .
  else
    command nvim "$@"
  fi
}

# Preserve normal cd behavior for real paths, otherwise ask zoxide to resolve
# the query. zoxide's shell hook records the final directory as usual.
zd() {
  local destination
  if (( $# == 0 )); then
    builtin cd "$HOME" || return
  elif (( $# == 1 )) && [[ "$1" == "-" ]]; then
    builtin cd - || return
  elif [[ -d "$1" ]]; then
    builtin cd -- "$1" || return
  elif command -v zoxide >/dev/null 2>&1; then
    destination="$(zoxide query -- "$@")" || {
      echo "Directory not found: $*" >&2
      return 1
    }
    builtin cd -- "$destination" || return
  else
    echo "Directory not found and zoxide is unavailable: $*" >&2
    return 1
  fi

  printf '\U000F17A9 %s\n' "$PWD"
}

# Select a file with fzf and preview it with Bat. The leading ./ is removed to
# keep the picker readable; no file is opened or copied until selection succeeds.
ff() {
  command -v fzf >/dev/null 2>&1 || {
    echo "fzf is unavailable" >&2
    return 1
  }

  find . -type f ! -path './.git/*' -print 2>/dev/null |
    sed 's#^\./##' |
    fzf --preview 'bat --style=numbers --color=always -- {}' "$@"
}

eff() {
  local file
  file="$(ff)" || return
  [[ -n "$file" ]] || return 1
  "$EDITOR" "$file"
}

sff() {
  local destination file
  if (( $# != 1 )); then
    echo "Usage: sff <destination> (for example, host:/tmp/)" >&2
    return 1
  fi
  destination="$1"
  file="$(ff)" || return
  [[ -n "$file" ]] || return 1
  command scp -- "$file" "$destination"
}
