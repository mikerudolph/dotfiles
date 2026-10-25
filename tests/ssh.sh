#!/usr/bin/env bash
set -euo pipefail

DOTFILES_ROOT="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
source "$DOTFILES_ROOT/lib/paths.sh"
source "$DOTFILES_ROOT/lib/logging.sh"
source "$DOTFILES_ROOT/lib/files.sh"
source "$DOTFILES_ROOT/lib/ssh.sh"

test_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-ssh-test.XXXXXX")"
trap 'rm -rf -- "$test_directory"' EXIT
mkdir "$test_directory/bin"

# These mocks contain placeholders, never a real private key or credential.
cat >"$test_directory/bin/op" <<'SH'
#!/usr/bin/env bash
set -eu
printf 'called\n' >> "$TEST_OP_CALLS"
[[ "$1" == read && "$2" == 'op://test/item/private key?ssh-format=openssh' ]]
[[ "$3" == --out-file && "$5" == --file-mode && "$6" == 0600 ]]
printf 'mock-export-placeholder\n' > "$4"
printf 'mock-sensitive-output-must-be-discarded\n'
[[ "${TEST_OP_FAIL:-0}" == 0 ]]
SH
cat >"$test_directory/bin/ssh-keygen" <<'SH'
#!/usr/bin/env bash
set -eu
[[ "${TEST_KEY_FAIL:-0}" == 0 ]] || exit 1
printf 'mock-public-placeholder\n'
SH
chmod +x "$test_directory/bin/op" "$test_directory/bin/ssh-keygen"
export PATH="$test_directory/bin:$PATH"
export TEST_OP_CALLS="$test_directory/op-calls"
reference='op://test/item/private key'
key="$test_directory/ssh/id_dotfiles"

DOTFILES_DRY_RUN=1
provision_local_ssh_key "$reference" "$key"
[[ ! -e "$test_directory/ssh" && ! -e "$TEST_OP_CALLS" ]]
echo 'PASS: provisioning dry-run creates nothing and never calls 1Password'

DOTFILES_DRY_RUN=0
provision_local_ssh_key "$reference" "$key"
local_ssh_key_is_private "$key"
[[ -f "$key.pub" && "$(wc -l < "$TEST_OP_CALLS" | tr -d ' ')" == 1 ]]
[[ -z "$(find "$test_directory/ssh" -name '.dotfiles-key.*' -print)" ]]
if provision_local_ssh_key "$reference" "$key" 2>/dev/null; then exit 1; fi
[[ "$(wc -l < "$TEST_OP_CALLS" | tr -d ' ')" == 1 ]]
echo 'PASS: provisioning sets private permissions, cleans staging, and refuses replacement'

chmod 644 "$key"
if local_ssh_key_is_private "$key"; then exit 1; fi
chmod 600 "$key"
ln -s "$key" "$test_directory/symlink-key"
if local_ssh_key_is_private "$test_directory/symlink-key"; then exit 1; fi
echo 'PASS: public permissions and symlinked keys are rejected'

export TEST_OP_FAIL=1
if provision_local_ssh_key "$reference" "$test_directory/ssh/failed-export" 2>/dev/null; then exit 1; fi
unset TEST_OP_FAIL
export TEST_KEY_FAIL=1
if provision_local_ssh_key "$reference" "$test_directory/ssh/invalid-key" 2>/dev/null; then exit 1; fi
unset TEST_KEY_FAIL
[[ ! -e "$test_directory/ssh/failed-export" && ! -e "$test_directory/ssh/invalid-key" ]]
[[ -z "$(find "$test_directory/ssh" -name '.dotfiles-key.*' -print)" ]]
echo 'PASS: failed exports and invalid keys are never installed'

ssh_config="$test_directory/ssh/config"
git_local="$test_directory/git.local"
printf 'Host *\n    IdentityAgent /old/1password.sock\nHost example.com\n    Port 2222\n' > "$ssh_config"
printf '[credential]\n    helper = keep-me\n' > "$git_local"
cp "$ssh_config" "$test_directory/original-ssh"
cp "$git_local" "$test_directory/original-git"
report_init
DOTFILES_DRY_RUN=1
reconcile_local_ssh_configuration "$key" "$ssh_config" "$git_local"
cmp "$ssh_config" "$test_directory/original-ssh"
cmp "$git_local" "$test_directory/original-git"
echo 'PASS: configuration dry-run leaves existing files intact'

DOTFILES_DRY_RUN=0
reconcile_local_ssh_configuration "$key" "$ssh_config" "$git_local"
[[ "$(head -n 1 "$ssh_config")" == '# >>> dotfiles:local-ssh-key >>>' ]]
ssh -G -F "$ssh_config" example.com 2>/dev/null > "$test_directory/effective-ssh"
rg -q '^identityagent none$' "$test_directory/effective-ssh"
rg -q '^identitiesonly yes$' "$test_directory/effective-ssh"
rg -q '^port 2222$' "$test_directory/effective-ssh"
[[ "$(git config --file "$git_local" --get credential.helper)" == keep-me ]]
[[ "$(git config --file "$git_local" --get user.signingKey)" == "$key" ]]
[[ "$(git config --file "$git_local" --get gpg.ssh.program)" == ssh-keygen ]]
awk '/^# <<< dotfiles:local-ssh-key <<<$/{rest=1;next} rest' "$ssh_config" > "$test_directory/preserved-ssh"
cmp "$test_directory/original-ssh" "$test_directory/preserved-ssh"
cp "$ssh_config" "$test_directory/configured-ssh"
cp "$git_local" "$test_directory/configured-git"
reconcile_local_ssh_configuration "$key" "$ssh_config" "$git_local"
cmp "$ssh_config" "$test_directory/configured-ssh"
cmp "$git_local" "$test_directory/configured-git"
echo 'PASS: agent bypass, host settings, Git helpers, and idempotency are preserved'

# A managed SSH block moved behind local settings must regain first precedence.
printf 'Host *\n    IdentityAgent /another/agent.sock\n' > "$test_directory/moved-ssh"
cat "$ssh_config" >> "$test_directory/moved-ssh"
cp "$test_directory/moved-ssh" "$ssh_config"
reconcile_local_ssh_configuration "$key" "$ssh_config" "$git_local"
ssh -G -F "$ssh_config" example.com 2>/dev/null > "$test_directory/effective-ssh"
rg -q '^identityagent none$' "$test_directory/effective-ssh"
[[ "$(rg -c '^# >>> dotfiles:local-ssh-key >>>$' "$ssh_config")" == 1 ]]
echo 'PASS: a displaced SSH block regains precedence without duplication'

printf '[invalid\n' > "$test_directory/invalid-git"
cp "$ssh_config" "$test_directory/before-invalid-git"
if reconcile_local_ssh_configuration "$key" "$ssh_config" "$test_directory/invalid-git"; then exit 1; fi
cmp "$ssh_config" "$test_directory/before-invalid-git"
echo 'PASS: invalid Git overrides prevent configuration changes'

printf '# >>> dotfiles:local-ssh-key >>>\n' > "$ssh_config"
cp "$ssh_config" "$test_directory/malformed-ssh"
if reconcile_local_ssh_configuration "$key" "$ssh_config" "$git_local"; then exit 1; fi
cmp "$ssh_config" "$test_directory/malformed-ssh"
echo 'PASS: malformed managed blocks are left untouched'
