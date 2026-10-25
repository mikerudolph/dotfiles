#!/usr/bin/env bash

onboard_can_prompt() {
  [[ -t 0 ]]
}

onboard_provision_reference() {
  local label="$1" command="$2" field="$3" reference=""
  if [[ "$dry_run" == "1" ]]; then
    echo "  Would ask for the selected 1Password $field reference and run bin/$command."
    return 0
  fi
  if ! onboard_can_prompt; then
    echo "  Run bin/$command 'op://vault/item/$field' in an interactive terminal."
    return 0
  fi
  if ! command -v op >/dev/null 2>&1; then
    echo "  1Password CLI is missing; run setup/apply before provisioning $label."
    return 0
  fi

  echo "  Enable 1Password CLI integration manually and approve its prompt when requested."
  printf '  %s reference (op://vault/item/%s; Enter skips): ' "$label" "$field"
  IFS= read -r reference || reference=""
  if [[ -z "$reference" ]]; then
    echo "  Skipped. Rerun bin/onboard when ready."
    return 0
  fi
  if [[ "$reference" != op://* ]]; then
    echo "Expected a 1Password field reference, not a secret value; rerun bin/onboard." >&2
    return 1
  fi
  "$DOTFILES_ROOT/bin/$command" "$reference"
}

onboard_local_credentials() {
  local key executable
  key="$(local_ssh_key_path)"
  echo "Local credentials"
  if local_ssh_key_is_private "$key"; then
    onboard_status "Local SSH key" "available (owner-only permissions)"
  elif [[ -e "$key" || -L "$key" || -e "$key.pub" || -L "$key.pub" ]]; then
    onboard_status "Local SSH key" "existing files need review; provisioning will not replace them"
  else
    onboard_status "Local SSH key" "pending (unencrypted export, mode 600)"
    onboard_provision_reference "SSH private key" provision-ssh-key 'private key' || return 1
  fi

  if git config --global --includes --get user.signingKey >/dev/null 2>&1; then
    onboard_status "Git signing key" "configured"
  else
    onboard_status "Git signing key" "not configured"
  fi

  executable="$(github_cli_path 2>/dev/null || true)"
  if [[ -z "$executable" ]]; then
    onboard_status "GitHub CLI account" "GitHub CLI missing (run setup/apply)"
  elif github_local_auth_configured "$executable"; then
    onboard_status "GitHub CLI account" "configured locally"
  else
    onboard_status "GitHub CLI account" "pending (local token import)"
    onboard_provision_reference "GitHub token" provision-github-auth token || return 1
  fi
}
