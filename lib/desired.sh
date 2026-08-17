#!/usr/bin/env bash

# Declarations are deliberately tiny. Installed software is not evidence for
# this list; additions require an explicit environment decision.
desired_packages() {
  declare_package "1Password CLI" op 1password-cli 1password-cli
  declare_package "mise" mise mise mise
  declare_package "bat" bat bat bat
  declare_package "glow" glow glow glow
  declare_package "GitHub CLI" gh gh github-cli
  declare_package "ffmpeg" ffmpeg ffmpeg ffmpeg
  declare_package "AWS CLI" aws awscli aws-cli-v2
  declare_package "Neovim" nvim neovim neovim
  declare_package "lazygit" lazygit lazygit lazygit
  declare_package "lazydocker" lazydocker lazydocker lazydocker
  declare_package "k9s" k9s k9s k9s
  declare_package "Starship" starship starship starship
  declare_package "zoxide" zoxide zoxide zoxide
  if [[ "${OS:-}" == "macos" ]]; then
    declare_package "mactop" mactop mactop ""
    declare_package "zsh-autosuggestions" zsh-autosuggestions zsh-autosuggestions ""
    declare_package "zsh-syntax-highlighting" zsh-syntax-highlighting zsh-syntax-highlighting ""
    declare_package "Mac App Store CLI" mas mas ""
  fi
}

desired_mise_tools() {
  declare_mise_tool "Node.js LTS" node lts
  declare_mise_tool "Bun" bun latest
  declare_mise_tool "pnpm" pnpm latest
  declare_mise_tool "Go" go latest
  declare_mise_tool "Python" python latest
  declare_mise_tool "Ruby" ruby latest
  declare_mise_tool "Rust" rust stable
  declare_mise_tool "Terraform" terraform latest
}

desired_macos_state() {
  [[ "${OS:-}" == "macos" ]] || return 0
  [[ "${DOTFILES_TEST_SKIP_MACOS_STATE:-0}" != "1" ]] || return 0
  desired_macos_applications
  macos_defaults_init
  desired_macos_defaults
  apply_macos_default_restarts
  declare_macos_app "Xcode" 497799835 /Applications/Xcode.app
  declare_xcode_developer_directory
  declare_command_line_tools
  declare_rosetta
}

desired_managed_files() {
  declare_managed_file "mise" \
    "$DOTFILES_ROOT/config/mise/config.toml" \
    "$DOTFILES_CONFIG_HOME/mise/config.toml" \
    "mise configuration"
}

desired_git_includes() {
  local machine_config
  if [[ -e "$HOME/.gitconfig" || -L "$HOME/.gitconfig" ]]; then
    machine_config="$HOME/.gitconfig"
  else
    machine_config="$DOTFILES_CONFIG_HOME/git/config"
  fi
  declare_git_include "$DOTFILES_ROOT/config/git/config" "$machine_config"
}

desired_shell_blocks() {
  local root_quoted content brew_path brew_quoted brew_prefix brew_prefix_quoted
  printf -v root_quoted '%q' "$DOTFILES_ROOT"
  case "${OS:-}:${FLAVOR:-}" in
    macos:)
      content="export DOTFILES_ROOT=$root_quoted
[ -r \"\$DOTFILES_ROOT/shell/zsh.sh\" ] && . \"\$DOTFILES_ROOT/shell/zsh.sh\""
      if brew_path="$(find_brew 2>/dev/null)"; then
        brew_prefix="$("$brew_path" --prefix 2>/dev/null || true)"
        if [[ -n "$brew_prefix" ]]; then
          printf -v brew_prefix_quoted '%q' "$brew_prefix"
          content="export DOTFILES_BREW_PREFIX=$brew_prefix_quoted
$content"
        fi
      fi
      declare_shell_block "$HOME/.zshrc" "shell-zsh" "$content" "Zsh integration"
      content="export DOTFILES_ROOT=$root_quoted"
      if brew_path="$(find_brew 2>/dev/null)"; then
        printf -v brew_quoted '%q' "$brew_path"
        content="$content
if [ -x $brew_quoted ]; then eval \"\$($brew_quoted shellenv)\"; fi"
      fi
      content="$content
[ -r \"\$DOTFILES_ROOT/shell/zprofile.sh\" ] && . \"\$DOTFILES_ROOT/shell/zprofile.sh\""
      declare_shell_block "$HOME/.zprofile" "shell-zprofile" "$content" "Zsh login integration"
      ;;
    linux:omarchy)
      content="export DOTFILES_ROOT=$root_quoted
[ -r \"\$DOTFILES_ROOT/shell/bash.sh\" ] && . \"\$DOTFILES_ROOT/shell/bash.sh\""
      declare_shell_block "$HOME/.bashrc" "shell-bash" "$content" "Bash integration"
      ;;
  esac
}

reconcile_desired_state() {
  desired_packages
  desired_managed_files
  desired_mise_tools
  desired_git_includes
  desired_shell_blocks
  desired_macos_state
  run_pending_migrations
  onepassword_manual_guidance
}
