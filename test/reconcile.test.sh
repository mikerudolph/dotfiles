#!/usr/bin/env bash
set -euo pipefail
source "$ROOT/test/helpers.sh"

sandbox="$(new_sandbox)"
trap 'rm -rf "$sandbox"' EXIT
home="$sandbox/home"
fakebin="$sandbox/bin"
mkdir -p "$home" "$fakebin"
for command_name in brew mise op; do
  printf '#!/usr/bin/env bash\nexit 0\n' >"$fakebin/$command_name"
  chmod +x "$fakebin/$command_name"
done
printf '#!/usr/bin/env bash\nexit 0\n' >"$fakebin/defaults"
printf '#!/usr/bin/env bash\nexit 1\n' >"$fakebin/pgrep"
chmod +x "$fakebin/defaults" "$fakebin/pgrep"

env HOME="$home" \
  XDG_CONFIG_HOME="$home/xdg/config" \
  XDG_STATE_HOME="$home/xdg/state" \
  XDG_DATA_HOME="$home/xdg/data" \
  XDG_CACHE_HOME="$home/xdg/cache" \
  DOTFILES_TEST_UNAME=Darwin \
  DOTFILES_TEST_SKIP_MACOS_STATE=1 \
  PATH="$fakebin:$PATH" \
  "$ROOT/bin/apply" --dry-run >"$sandbox/dry-output"

[[ ! -e "$home/xdg" ]] || fail "full dry-run created XDG state"
[[ ! -e "$home/.zshrc" ]] || fail "full dry-run created shell config"
assert_file_contains "$sandbox/dry-output" "No changes made."

common_env=(
  HOME="$home"
  XDG_CONFIG_HOME="$home/xdg/config"
  XDG_STATE_HOME="$home/xdg/state"
  XDG_DATA_HOME="$home/xdg/data"
  XDG_CACHE_HOME="$home/xdg/cache"
  DOTFILES_TEST_UNAME=Darwin
  DOTFILES_TEST_SKIP_MACOS_STATE=1
  PATH="$fakebin:$PATH"
)
env "${common_env[@]}" "$ROOT/bin/apply" >"$sandbox/first-output"
[[ -L "$home/xdg/config/mise/config.toml" ]] || fail "full apply did not create managed link"
assert_file_contains "$home/.zshrc" "# >>> dotfiles:shell-zsh >>>"
assert_file_contains "$home/xdg/config/git/config" "$ROOT/config/git/config"

find "$home" -type f -exec shasum {} + | sort >"$sandbox/before"
find "$home" -type l -exec sh -c 'for p do printf "%s %s\n" "$p" "$(readlink "$p")"; done' sh {} + | sort >>"$sandbox/before"
env "${common_env[@]}" "$ROOT/bin/apply" >"$sandbox/second-output"
find "$home" -type f -exec shasum {} + | sort >"$sandbox/after"
find "$home" -type l -exec sh -c 'for p do printf "%s %s\n" "$p" "$(readlink "$p")"; done' sh {} + | sort >>"$sandbox/after"
cmp "$sandbox/before" "$sandbox/after" >/dev/null || fail "repeated full reconciliation was not idempotent"
