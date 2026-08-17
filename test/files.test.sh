#!/usr/bin/env bash
set -euo pipefail
source "$ROOT/test/helpers.sh"
source "$ROOT/lib/paths.sh"
source "$ROOT/lib/logging.sh"
source "$ROOT/lib/files.sh"

sandbox="$(new_sandbox)"
trap 'rm -rf "$sandbox"' EXIT
HOME="$sandbox/home"
DOTFILES_ROOT="$sandbox/repo"
mkdir -p "$HOME" "$DOTFILES_ROOT/config" "$DOTFILES_ROOT/lib"
printf 'one\n' >"$DOTFILES_ROOT/config/one"
printf 'two\n' >"$DOTFILES_ROOT/config/two"
dotfiles_paths_init

report_init
DOTFILES_DRY_RUN=0
ensure_symlink "$DOTFILES_ROOT/config/one" "$HOME/.config/example" "example"
[[ -L "$HOME/.config/example" ]] || fail "managed symlink was not created"
assert_eq "$DOTFILES_ROOT/config/one" "$(readlink "$HOME/.config/example")" "symlink target"

report_init
ensure_symlink "$DOTFILES_ROOT/config/one" "$HOME/.config/example" "example"
assert_eq 0 "${#REPORT_CHANGED[@]}" "repeat reconciliation changed state"

ln -sfn "$DOTFILES_ROOT/config/two" "$HOME/.config/example"
report_init
ensure_symlink "$DOTFILES_ROOT/config/one" "$HOME/.config/example" "example"
assert_eq "$DOTFILES_ROOT/config/one" "$(readlink "$HOME/.config/example")" "managed link reconciliation"

printf 'keep me\n' >"$HOME/.config/unmanaged"
before="$(cat "$HOME/.config/unmanaged")"
report_init
ensure_symlink "$DOTFILES_ROOT/config/one" "$HOME/.config/unmanaged" "unmanaged" || true
assert_eq "$before" "$(cat "$HOME/.config/unmanaged")" "unmanaged file was modified"
assert_eq 1 "${#REPORT_CONFLICT[@]}" "unmanaged file did not conflict"

dry_destination="$HOME/dry/deep/example"
report_init
DOTFILES_DRY_RUN=1
ensure_symlink "$DOTFILES_ROOT/config/one" "$dry_destination" "dry link"
[[ ! -e "$HOME/dry" ]] || fail "dry-run created a directory"

printf 'local-before\n' >"$HOME/.zshrc"
report_init
DOTFILES_DRY_RUN=0
ensure_source_block "$HOME/.zshrc" shell-test '. /managed/shell.sh' "shell test"
assert_file_contains "$HOME/.zshrc" "local-before"
assert_file_contains "$HOME/.zshrc" "# >>> dotfiles:shell-test >>>"
block_before="$(cat "$HOME/.zshrc")"
report_init
ensure_source_block "$HOME/.zshrc" shell-test '. /managed/shell.sh' "shell test"
assert_eq "$block_before" "$(cat "$HOME/.zshrc")" "managed block was not idempotent"

printf '# >>> dotfiles:broken >>>\nunclosed\n' >"$HOME/.brokenrc"
broken_before="$(cat "$HOME/.brokenrc")"
report_init
ensure_source_block "$HOME/.brokenrc" broken 'replacement' "broken block" || true
assert_eq "$broken_before" "$(cat "$HOME/.brokenrc")" "malformed block was modified"
assert_eq 1 "${#REPORT_CONFLICT[@]}" "malformed block did not conflict"
