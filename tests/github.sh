#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$DOTFILES_ROOT/lib/logging.sh"
source "$DOTFILES_ROOT/lib/github.sh"

test_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-github-test.XXXXXX")"
trap 'rm -rf -- "$test_directory"' EXIT
mkdir "$test_directory/bin"
export GH_CONFIG_DIR="$test_directory/auth"
export TEST_GITHUB_CALLS="$test_directory/calls"

# Only synthetic placeholders cross these mock pipes; no real token is used.
cat > "$test_directory/bin/op" <<'SH'
#!/usr/bin/env bash
set -eu
printf 'op\n' >> "$TEST_GITHUB_CALLS"
[[ "${TEST_OP_FAIL:-0}" == 0 ]] || exit 1
case "$1" in
  read) [[ "$2" == op://test/item/token ]] || exit 1 ;;
  plugin) [[ "$*" == 'plugin run -- gh auth token --hostname github.com' ]] || exit 1 ;;
  *) exit 1 ;;
esac
printf 'mock-token-placeholder\n'
SH
cat > "$test_directory/bin/gh" <<'SH'
#!/usr/bin/env bash
set -eu
case "$1 $2 $3" in
  'config get user') [[ "${TEST_LOCAL_AUTH:-0}" == 1 ]] ;;
  'config get git_protocol') printf 'ssh\n' ;;
  'auth login --hostname')
    [[ "$*" == 'auth login --hostname github.com --with-token --git-protocol ssh' ]] || exit 1
    [[ -z "${GH_TOKEN:-}${GITHUB_TOKEN:-}" ]] || exit 1
    IFS= read -r placeholder || exit 1
    [[ "$placeholder" == mock-token-placeholder ]] || exit 1
    printf 'login\n' >> "$TEST_GITHUB_CALLS"
    ;;
  *) exit 1 ;;
esac
SH
chmod +x "$test_directory/bin/op" "$test_directory/bin/gh"
export PATH="$test_directory/bin:$PATH"
executable="$(github_cli_path)"
[[ "$executable" == "$test_directory/bin/gh" ]]

DOTFILES_DRY_RUN=1
provision_local_github_auth "$executable"
[[ ! -e "$TEST_GITHUB_CALLS" && ! -e "$GH_CONFIG_DIR" ]]
echo 'PASS: auth dry-run calls no vault, creates no files, and performs no login'

DOTFILES_DRY_RUN=0
export GH_TOKEN=mock-environment-placeholder GITHUB_TOKEN=mock-environment-placeholder
provision_local_github_auth "$executable"
[[ "$(cat "$TEST_GITHUB_CALLS")" == $'op\nlogin' ]]
[[ "$GH_TOKEN" == mock-environment-placeholder ]]
echo 'PASS: the existing plugin token streams into local login without changing the parent environment'

provision_local_github_auth "$executable" op://test/item/token
[[ "$(wc -l < "$TEST_GITHUB_CALLS" | tr -d ' ')" == 4 ]]
echo 'PASS: an explicit token reference supports fresh machines without plugin configuration'

export TEST_LOCAL_AUTH=1
if provision_local_github_auth "$executable" 2>/dev/null; then exit 1; fi
[[ "$(wc -l < "$TEST_GITHUB_CALLS" | tr -d ' ')" == 4 ]]
report_init
ensure_local_github_auth
[[ "$REPORT_UNCHANGED_COUNT" == 1 ]]
[[ "$(wc -l < "$TEST_GITHUB_CALLS" | tr -d ' ')" == 4 ]]
unset TEST_LOCAL_AUTH
echo 'PASS: existing local accounts are preserved and ordinary checks never call 1Password'

export TEST_OP_FAIL=1
if provision_local_github_auth "$executable" 2>/dev/null; then exit 1; fi
unset TEST_OP_FAIL
[[ "$(tail -n 1 "$TEST_GITHUB_CALLS")" == op ]]
echo 'PASS: vault failures do not report successful login'

original_config_directory="$GH_CONFIG_DIR"
export GH_CONFIG_DIR="$DOTFILES_ROOT/config/gh-test"
if provision_local_github_auth "$executable" 2>/dev/null; then exit 1; fi
[[ ! -e "$GH_CONFIG_DIR" ]]
export GH_CONFIG_DIR="$original_config_directory"
mkdir "$test_directory/auth"
ln -s "$test_directory/not-a-config" "$GH_CONFIG_DIR/hosts.yml"
if provision_local_github_auth "$executable" 2>/dev/null; then exit 1; fi
echo 'PASS: checkout storage and symlinked credential files are rejected'

report_init
destination="$test_directory/legacy-gh"
ln -s "$DOTFILES_ROOT/config/bin/gh" "$destination"
DOTFILES_DRY_RUN=1
ensure_legacy_github_shim_absent "$destination"
[[ -L "$destination" ]]
DOTFILES_DRY_RUN=0
ensure_legacy_github_shim_absent "$destination"
[[ ! -L "$destination" && ! -e "$destination" ]]
ensure_legacy_github_shim_absent "$destination"
printf 'machine-local executable placeholder\n' > "$destination"
ensure_legacy_github_shim_absent "$destination"
[[ -f "$destination" ]]
ln -s "$DOTFILES_ROOT/config/git/config" "$test_directory/other-gh"
ensure_legacy_github_shim_absent "$test_directory/other-gh"
[[ -L "$test_directory/other-gh" ]]
echo 'PASS: only the exact retired symlink is removed; dry-run and unmanaged files are preserved'
