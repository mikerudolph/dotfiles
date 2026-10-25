#!/usr/bin/env bash
set -euo pipefail

repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
test_directory="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-setup-test.XXXXXX")"
trap 'rm -rf -- "$test_directory"' EXIT
mkdir -p "$test_directory/lib" "$test_directory/bin" "$test_directory/omarchy/bin"
cp "$repository_root/setup" "$test_directory/setup"
for library in paths platform packages onepassword; do
  cp "$repository_root/lib/$library.sh" "$test_directory/lib/$library.sh"
done
cat > "$test_directory/bin/apply" <<'SH'
#!/usr/bin/env bash
printf 'apply %s\n' "$*" >> "$TEST_SETUP_CALLS"
exit "$TEST_APPLY_STATUS"
SH
cat > "$test_directory/bin/onboard" <<'SH'
#!/usr/bin/env bash
printf 'onboard %s\n' "$*" >> "$TEST_SETUP_CALLS"
exit "${TEST_ONBOARD_STATUS:-0}"
SH
for command in 1password omarchy-pkg-add; do
  printf '#!/usr/bin/env bash\nexit 97\n' > "$test_directory/bin/$command"
done
printf '#!/usr/bin/env bash\nexit 97\n' > "$test_directory/omarchy/bin/omarchy"
chmod +x "$test_directory/bin/"* "$test_directory/omarchy/bin/omarchy"
printf 'ID=omarchy\nID_LIKE=arch\n' > "$test_directory/os-release"
export PATH="$test_directory/bin:$PATH"
export DOTFILES_TEST_UNAME=Linux
export DOTFILES_TEST_OS_RELEASE="$test_directory/os-release"
export DOTFILES_TEST_OMARCHY_ROOT="$test_directory/omarchy"
export TEST_SETUP_CALLS="$test_directory/calls"

for TEST_APPLY_STATUS in 0 3 1; do
  export TEST_APPLY_STATUS
  status=0
  bash "$test_directory/setup" > /dev/null || status=$?
  [[ "$status" == "$TEST_APPLY_STATUS" ]]
  if [[ "$TEST_APPLY_STATUS" == 1 ]]; then
    [[ "$(cat "$TEST_SETUP_CALLS")" == 'apply ' ]]
  else
    [[ "$(cat "$TEST_SETUP_CALLS")" == $'apply \nonboard ' ]]
  fi
  rm "$TEST_SETUP_CALLS"
done
echo 'PASS: setup runs onboarding after success or safe conflicts, preserves conflicts, and stops on fatal apply errors'

export TEST_APPLY_STATUS=0 TEST_ONBOARD_STATUS=1
status=0
bash "$test_directory/setup" > /dev/null || status=$?
[[ "$status" == 1 ]]
rm "$TEST_SETUP_CALLS"
echo 'PASS: onboarding failure fails setup'

export TEST_ONBOARD_STATUS=0
for TEST_APPLY_STATUS in 0 3 1; do
  export TEST_APPLY_STATUS
  status=0
  bash "$test_directory/setup" --dry-run > /dev/null || status=$?
  [[ "$status" == "$TEST_APPLY_STATUS" ]]
  if [[ "$TEST_APPLY_STATUS" == 1 ]]; then
    [[ "$(cat "$TEST_SETUP_CALLS")" == 'apply --dry-run' ]]
  else
    [[ "$(cat "$TEST_SETUP_CALLS")" == $'apply --dry-run\nonboard --dry-run' ]]
  fi
  rm "$TEST_SETUP_CALLS"
done
echo 'PASS: setup dry-run uses the same onboarding and failure handling as execution'
