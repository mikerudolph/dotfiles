#!/usr/bin/env bash

local_ssh_key_path() {
  printf '%s/.ssh/id_dotfiles\n' "$HOME"
}

local_ssh_key_is_private() {
  local key="$1" mode
  [[ -f "$key" && ! -L "$key" && -O "$key" ]] || return 1
  mode="$(stat -f '%Lp' "$key" 2>/dev/null)" || mode="$(stat -c '%a' "$key" 2>/dev/null)" || return 1
  [[ "$mode" == "600" || "$mode" == "400" ]]
}

reconcile_local_ssh_configuration() {
  local key="$1" ssh_config="$2" git_local="$3" content
  if [[ -f "$git_local" ]] && ! git config --file "$git_local" --list >/dev/null 2>&1; then
    report_conflict "The machine-local Git overrides are invalid; leaving them untouched"
    return 1
  fi
  # SSH takes the first scalar value, so this bounded block must come first.
  # End in Host * so any following machine-local options retain global scope.
  content="Host *
    IdentityAgent none
    IdentityFile \"$key\"
    IdentitiesOnly yes
Host *"
  ensure_source_block "$ssh_config" local-ssh-key "$content" \
    "SSH authentication with the local key" '#' prepend || return 1

  content="[gpg]
    format = ssh
[gpg \"ssh\"]
    program = ssh-keygen
[user]
    signingKey = \"$key\""
  ensure_source_block "$git_local" local-ssh-key "$content" \
    "Git signing with the local SSH key"
}

ensure_local_ssh() {
  local key
  key="$(local_ssh_key_path)"
  if [[ -L "$HOME/.ssh" ]]; then
    report_conflict "The SSH directory is a symlink; leaving it untouched"
    return 1
  fi
  if [[ ! -e "$key" && ! -L "$key" ]]; then
    report_manual "Provision the local SSH/signing key once with bin/provision-ssh-key 'op://vault/item/private key'"
    return 0
  fi
  if ! local_ssh_key_is_private "$key"; then
    report_conflict "The local SSH key must be an owner-only regular file (mode 600 or 400); leaving it untouched"
    return 1
  fi
  reconcile_local_ssh_configuration "$key" "$HOME/.ssh/config" "$HOME/.gitconfig.local"
}

# Explicit, one-time credential provisioning; ordinary apply never reads a vault.
# A subshell confines the cleanup trap and never holds key material in a variable.
provision_local_ssh_key() (
  set +x
  umask 077
  local reference="$1" key="$2" directory temporary
  directory="$(dirname -- "$key")"
  if [[ -e "$key" || -L "$key" || -e "$key.pub" || -L "$key.pub" ]]; then
    echo "Refusing to replace an existing local SSH key or public key" >&2
    return 1
  fi
  if [[ -L "$directory" || ( -e "$directory" && ! -d "$directory" ) ]]; then
    echo "The SSH directory must be a regular, machine-local directory" >&2
    return 1
  fi
  case "$reference" in
    op://*\?*) echo "Provide a private-key reference without query parameters" >&2; return 1 ;;
    op://*) ;;
    *) echo "Expected an op://vault/item/private key reference" >&2; return 1 ;;
  esac
  if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
    return 0
  fi
  command -v op >/dev/null 2>&1 || { echo "1Password CLI is required" >&2; return 1; }
  command -v ssh-keygen >/dev/null 2>&1 || { echo "OpenSSH is required" >&2; return 1; }
  [[ -d "$directory" ]] || mkdir -m 700 "$directory" || return 1
  temporary="$(mktemp -d "$directory/.dotfiles-key.XXXXXX")" || return 1
  trap 'rm -rf -- "$temporary"' EXIT
  trap 'exit 1' HUP INT TERM
  if ! op read "$reference?ssh-format=openssh" --out-file "$temporary/private" \
      --file-mode 0600 >/dev/null 2>&1; then
    echo "Could not export the selected SSH key; check 1Password sign-in and CLI approval" >&2
    return 1
  fi
  chmod 600 "$temporary/private" || return 1
  if ! SSH_ASKPASS_REQUIRE=never ssh-keygen -y -P '' -f "$temporary/private" \
      >"$temporary/public" 2>/dev/null; then
    echo "The export is not a valid, unencrypted OpenSSH private key; nothing was installed" >&2
    return 1
  fi
  chmod 600 "$temporary/public" || return 1
  # Hard links publish each file without ever replacing an existing destination.
  ln "$temporary/private" "$key" || return 1
  ln "$temporary/public" "$key.pub" || return 1
)
