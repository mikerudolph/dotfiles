#!/usr/bin/env bash
set -euo pipefail
source "$ROOT/test/helpers.sh"
source "$ROOT/lib/logging.sh"
source "$ROOT/lib/state.sh"
source "$ROOT/lib/migrations.sh"

sandbox="$(new_sandbox)"
trap 'rm -rf "$sandbox"' EXIT
DOTFILES_ROOT="$sandbox/repo"
DOTFILES_STATE_HOME="$sandbox/state/dotfiles"
mkdir -p "$DOTFILES_ROOT/migrations"
printf '#!/usr/bin/env bash\nprintf "ran\\n" >>"%s"\n' "$sandbox/result" >"$DOTFILES_ROOT/migrations/0001-test.sh"

report_init
DOTFILES_DRY_RUN=1
run_pending_migrations
[[ ! -e "$sandbox/state" ]] || fail "migration dry-run created state"
[[ ! -e "$sandbox/result" ]] || fail "migration dry-run executed migration"

report_init
DOTFILES_DRY_RUN=0
run_pending_migrations
run_pending_migrations
assert_eq 1 "$(wc -l <"$sandbox/result" | tr -d ' ')" "migration ran more than once"
[[ -f "$DOTFILES_STATE_HOME/migrations/0001-test.done" ]] || fail "migration marker missing"

