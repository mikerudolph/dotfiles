#!/usr/bin/env bash
set -euo pipefail

repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$repository_root/lib/ssh.sh"
source "$repository_root/lib/github.sh"
source "$repository_root/lib/onboarding.sh"

test_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-onboarding-test.XXXXXX")"
trap 'rm -rf -- "$test_directory"' EXIT
mkdir "$test_directory/bin"
export TEST_CREDENTIAL_CALLS="$test_directory/calls"
export TEST_LOCAL_SSH_KEY="$test_directory/local-key"
export TEST_GITHUB_STATE="$test_directory/github-state"
export TEST_GIT_SIGNING_FILE="$test_directory/gitconfig.local"
export GIT_CONFIG_GLOBAL="$test_directory/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
git config --file "$GIT_CONFIG_GLOBAL" include.path "$TEST_GIT_SIGNING_FILE"

# Synthetic provisioning stubs; no real keys, tokens, or vault access.
cat > "$test_directory/bin/provision-ssh-key" <<'SH'
#!/usr/bin/env bash
set -eu
[[ "$1" == 'op://test/item/private key' ]] || exit 1
printf 'ssh\n' >> "$TEST_CREDENTIAL_CALLS"
printf 'mock-key-placeholder\n' > "$TEST_LOCAL_SSH_KEY"
chmod 600 "$TEST_LOCAL_SSH_KEY"
git config --file "$TEST_GIT_SIGNING_FILE" user.signingKey "$TEST_LOCAL_SSH_KEY"
SH
cat > "$test_directory/bin/provision-github-auth" <<'SH'
#!/usr/bin/env bash
set -eu
[[ "$1" == op://test/item/token ]] || exit 1
printf 'github\n' >> "$TEST_CREDENTIAL_CALLS"
touch "$TEST_GITHUB_STATE"
SH
cat > "$test_directory/bin/gh" <<'SH'
#!/usr/bin/env bash
[[ "$*" == 'config get user --host github.com' && -f "$TEST_GITHUB_STATE" ]]
SH
cat > "$test_directory/bin/op" <<'SH'
#!/usr/bin/env bash
echo 'Unexpected vault access' >&2
exit 97
SH
chmod +x "$test_directory/bin/"*
export PATH="$test_directory/bin:$PATH"
DOTFILES_ROOT="$test_directory"
local_ssh_key_path() { printf '%s\n' "$TEST_LOCAL_SSH_KEY"; }
onboard_status() { printf '  %s: %s\n' "$1" "$2"; }
onboard_can_prompt() { [[ "$test_interactive" == 1 ]]; }

dry_run=1
test_interactive=1
onboard_local_credentials > "$test_directory/dry-run-output"
rg -q 'run bin/provision-ssh-key' "$test_directory/dry-run-output"
rg -q 'run bin/provision-github-auth' "$test_directory/dry-run-output"
rg -q 'Git signing key: not configured' "$test_directory/dry-run-output"
[[ ! -e "$TEST_CREDENTIAL_CALLS" && ! -e "$TEST_LOCAL_SSH_KEY" && ! -e "$TEST_GITHUB_STATE" ]]
echo 'PASS: first-run dry-run describes both provisions without reading a vault or creating credentials'

dry_run=0
test_interactive=0
onboard_local_credentials > "$test_directory/noninteractive-output"
[[ ! -e "$TEST_CREDENTIAL_CALLS" ]]
rg -q 'interactive terminal' "$test_directory/noninteractive-output"
echo 'PASS: non-interactive onboarding leaves explicit manual provisioning commands'

test_interactive=1
for OS in macos linux; do
  onboard_local_credentials > "$test_directory/interactive-output" <<'INPUT'
op://test/item/private key
op://test/item/token
INPUT
  [[ "$(cat "$TEST_CREDENTIAL_CALLS")" == $'ssh\ngithub' ]]
  rg -q 'Git signing key: configured' "$test_directory/interactive-output"
  if rg -q 'Git signing key: not configured' "$test_directory/interactive-output"; then exit 1; fi
  if git config --global --get user.signingKey > /dev/null 2>&1; then exit 1; fi
  [[ "$(git config --global --includes --get user.signingKey)" == "$TEST_LOCAL_SSH_KEY" ]]
  onboard_local_credentials > "$test_directory/repeated-output" < /dev/null
  rg -q 'Git signing key: configured' "$test_directory/repeated-output"
  [[ "$(cat "$TEST_CREDENTIAL_CALLS")" == $'ssh\ngithub' ]]
  rm "$TEST_CREDENTIAL_CALLS" "$TEST_LOCAL_SSH_KEY" "$TEST_GITHUB_STATE" "$TEST_GIT_SIGNING_FILE"
done
echo 'PASS: both platforms provision selected references once and skip completed credentials on reruns'
echo 'PASS: signing status is checked after provisioning and follows global Git includes on first runs and reruns'

onboard_local_credentials > "$test_directory/skipped-output" <<'INPUT'


INPUT
[[ ! -e "$TEST_CREDENTIAL_CALLS" ]]
echo 'PASS: blank answers skip provisioning'

if onboard_local_credentials > "$test_directory/invalid-output" 2>&1 <<'INPUT'
invalid-reference-placeholder
INPUT
then
  exit 1
fi
[[ ! -e "$TEST_CREDENTIAL_CALLS" ]]
if rg -q invalid-reference-placeholder "$test_directory/invalid-output"; then exit 1; fi
echo 'PASS: invalid input is rejected without echoing it or invoking provisioning'

printf 'existing-machine-local-placeholder\n' > "$TEST_LOCAL_SSH_KEY"
chmod 644 "$TEST_LOCAL_SSH_KEY"
touch "$TEST_GITHUB_STATE"
cp "$TEST_LOCAL_SSH_KEY" "$test_directory/original-key"
onboard_local_credentials > "$test_directory/conflict-output" < /dev/null
cmp "$TEST_LOCAL_SSH_KEY" "$test_directory/original-key"
[[ ! -e "$TEST_CREDENTIAL_CALLS" ]]
echo 'PASS: existing unsafe key files are left untouched'
