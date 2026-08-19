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
  declare_package "eza" eza eza eza
  declare_package "fzf" fzf fzf fzf
  declare_package "kubectl" kubectl kubectl kubectl
  if [[ "${OS:-}" == "macos" ]]; then
    declare_package "mactop" mactop mactop ""
    declare_package "zsh-autosuggestions" zsh-autosuggestions zsh-autosuggestions ""
    declare_package "zsh-syntax-highlighting" zsh-syntax-highlighting zsh-syntax-highlighting ""
    declare_package "Mac App Store CLI" mas mas ""
  elif [[ "${OS:-}:${FLAVOR:-}" == "linux:omarchy" ]]; then
    declare_package "Tailscale" tailscale "" tailscale
    declare_package "Dropbox" dropbox "" dropbox
  fi
}

desired_directories() {
  if [[ "${OS:-}" == "macos" ]]; then
    declare_directory "$DOTFILES_XDG_STATE_HOME/zsh"
    declare_directory "$DOTFILES_CACHE_HOME/completions/zsh"
  fi
}

desired_static_completions() {
  [[ "${OS:-}" == "macos" ]] || return 0
  declare_static_completion "Codex CLI" codex codex completion zsh
  declare_static_completion "GitHub CLI" gh gh completion -s zsh
  declare_static_completion "kubectl" kubectl kubectl completion zsh
  declare_static_completion "mise" mise mise completion zsh
  declare_static_completion "1Password CLI" op op completion zsh
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
  declare_macos_capslock_control
  apply_macos_default_restarts
  declare_macos_app "Xcode" 497799835 /Applications/Xcode.app
  declare_xcode_developer_directory
  declare_command_line_tools
  declare_rosetta
}

desired_managed_files() {
  declare_managed_file "gh-shim" \
    "$DOTFILES_ROOT/config/bin/gh" \
    "$HOME/.local/bin/gh" \
    "1Password-backed GitHub CLI shim"
  declare_managed_file "mise" \
    "$DOTFILES_ROOT/config/mise/config.toml" \
    "$DOTFILES_CONFIG_HOME/mise/config.toml" \
    "mise configuration"
  declare_managed_file "nvim" \
    "$DOTFILES_ROOT/config/nvim" \
    "$DOTFILES_CONFIG_HOME/nvim" \
    "Neovim configuration"
  if [[ "${OS:-}" == "macos" ]]; then
    local codex_config_home="${CODEX_HOME:-$HOME/.codex}"
    declare_managed_file "starship" \
      "$DOTFILES_ROOT/config/starship.toml" \
      "$DOTFILES_CONFIG_HOME/starship.toml" \
      "Starship configuration"
    declare_managed_file "eza-theme" \
      "$DOTFILES_ROOT/themes/tokyonight/eza.yml" \
      "$DOTFILES_CONFIG_HOME/eza/theme.yml" \
      "eza Tokyo Night theme"

    local k9s_data_home="$DOTFILES_DATA_HOME"
    if [[ -z "${XDG_DATA_HOME:-}" ]]; then
      k9s_data_home="$HOME/Library/Application Support"
    fi
    declare_managed_file "k9s-theme" \
      "$DOTFILES_ROOT/themes/tokyonight/k9s.yaml" \
      "$k9s_data_home/k9s/skins/tokyonight.yaml" \
      "K9s Tokyo Night skin"

    local mactop_theme_destination="$HOME/.mactop/theme.json"
    case "${XDG_CONFIG_HOME:-}" in
      /*) mactop_theme_destination="$XDG_CONFIG_HOME/mactop/theme.json" ;;
    esac
    declare_managed_file "mactop-theme" \
      "$DOTFILES_ROOT/themes/tokyonight/mactop.json" \
      "$mactop_theme_destination" \
      "mactop Tokyo Night theme"
    declare_managed_file "glow-theme" \
      "$DOTFILES_ROOT/themes/tokyonight/glow.json" \
      "$DOTFILES_CONFIG_HOME/glow/tokyonight.json" \
      "Glow Tokyo Night stylesheet"

    declare_managed_file "alacritty" \
      "$DOTFILES_ROOT/config/alacritty/alacritty.toml" \
      "$DOTFILES_CONFIG_HOME/alacritty/alacritty.toml" \
      "Alacritty configuration"
    declare_managed_file "raycast-term" \
      "$DOTFILES_ROOT/config/raycast/script-commands/new-alacritty.sh" \
      "$DOTFILES_CONFIG_HOME/raycast/script-commands/new-alacritty.sh" \
      "Raycast new-Alacritty command"
    declare_managed_file "raycast-web" \
      "$DOTFILES_ROOT/config/raycast/script-commands/new-chrome.sh" \
      "$DOTFILES_CONFIG_HOME/raycast/script-commands/new-chrome.sh" \
      "Raycast new-Chrome command"
    declare_managed_file "hushlogin" \
      "$DOTFILES_ROOT/config/shell/hushlogin" \
      "$HOME/.hushlogin" \
      "login-message suppression"
    declare_managed_file "xcode-theme" \
      "$DOTFILES_ROOT/config/xcode/Tokyo Night.xccolortheme" \
      "$HOME/Library/Developer/Xcode/UserData/FontAndColorThemes/Tokyo Night.xccolortheme" \
      "Xcode Tokyo Night theme"
    declare_managed_file "codex-theme" \
      "$DOTFILES_ROOT/themes/tokyonight/codex/tokyonight-night.tmTheme" \
      "$codex_config_home/themes/tokyonight-night.tmTheme" \
      "Codex Tokyo Night theme"
    declare_managed_file "claude-theme" \
      "$DOTFILES_ROOT/themes/tokyonight/claude/tokyonight-night.json" \
      "$HOME/.claude/themes/tokyonight-night.json" \
      "Claude Code Tokyo Night theme"
    declare_managed_file "capslock-helper" \
      "$DOTFILES_ROOT/platform/macos/capslock-control.sh" \
      "$HOME/Library/Application Support/dotfiles/capslock-control.sh" \
      "Caps Lock mapping helper"
    declare_managed_file "capslock-agent" \
      "$DOTFILES_ROOT/platform/macos/services/com.mikerudolph.dotfiles.capslock-control.plist" \
      "$HOME/Library/LaunchAgents/com.mikerudolph.dotfiles.capslock-control.plist" \
      "Caps Lock login LaunchAgent"
  fi
}

desired_omarchy_keyboard() {
  local input_file content
  [[ "${OS:-}:${FLAVOR:-}" == "linux:omarchy" ]] || return 0
  # Omarchy's bootstrap currently adds this literal user path to Lua's module
  # search path, so follow the upstream layer even when XDG_CONFIG_HOME differs.
  input_file="$HOME/.config/hypr/input.lua"

  if [[ ! -f "$HOME/.config/hypr/hyprland.lua" && \
        ! -f "/usr/share/omarchy/default/hypr/bootstrap.lua" && \
        "${DOTFILES_TEST_OMARCHY_LUA:-0}" != "1" ]]; then
    report_manual "Caps Lock remapping requires Omarchy's current Lua user input layer (~/.config/hypr/input.lua)"
    return 0
  fi

  content='local dotfiles_current_options = hl.get_config("input.kb_options") or ""
local dotfiles_kept_options = {}

for option in tostring(dotfiles_current_options):gmatch("[^,%s]+") do
  local uses_caps_key = option == "compose:caps"
    or option:match("^caps:")
    or option:match("^grp:caps")
    or option:match("^lv3:caps")
    or option:match("^ctrl:.*caps")
  if not uses_caps_key then
    table.insert(dotfiles_kept_options, option)
  end
end

table.insert(dotfiles_kept_options, "ctrl:nocaps")
hl.config({ input = { kb_options = table.concat(dotfiles_kept_options, ",") } })'
  declare_config_block "$input_file" "capslock-control" "$content" \
    "Caps Lock as Control" "--"
}

desired_macos_raycast_guidance() {
  [[ "${OS:-}" == "macos" ]] || return 0
  report_manual "In Raycast, add $DOTFILES_CONFIG_HOME/raycast/script-commands as a Script Directory"
  report_manual "Set Raycast to Command-Space; bind New Alacritty Window to Command-Control-Return and New Chrome Window to Command-Control-Shift-Return"
}

desired_macos_theme_guidance() {
  [[ "${OS:-}" == "macos" ]] || return 0
  report_manual "In Codex, run /theme and select Tokyo Night Night"
  report_manual "In Claude Code 2.1.118 or later, run /theme and select Tokyo Night Night"
}

desired_omarchy_application_guidance() {
  [[ "${OS:-}:${FLAVOR:-}" == "linux:omarchy" ]] || return 0
  report_manual "Run 'sudo systemctl enable --now tailscaled', then 'tailscale up' to authenticate this machine"
  report_manual "Launch Dropbox and complete its interactive sign-in"
}

desired_git_includes() {
  local machine_config
  if [[ -e "$HOME/.gitconfig" || -L "$HOME/.gitconfig" ]]; then
    machine_config="$HOME/.gitconfig"
  else
    machine_config="$DOTFILES_CONFIG_HOME/git/config"
  fi
  declare_git_include "$DOTFILES_ROOT/config/git/config" "$machine_config"
  if [[ "${OS:-}" == "macos" ]]; then
    declare_git_include "$DOTFILES_ROOT/config/git/macos" "$machine_config"
  fi
  # This deliberately comes last so work identity, signing, credentials, and
  # machine policy can override every shared and platform default.
  declare_git_include "$HOME/.gitconfig.local" "$machine_config"
}

desired_git_signing_guidance() {
  if ! git config --global --get user.signingKey >/dev/null 2>&1; then
    report_manual "In 1Password, open the SSH key to use for Git, choose Configure Commit Signing, and save its public key as user.signingKey"
  fi
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
  desired_directories
  desired_managed_files
  desired_static_completions
  desired_mise_tools
  desired_git_includes
  desired_git_signing_guidance
  desired_shell_blocks
  desired_omarchy_keyboard
  desired_macos_state
  desired_macos_raycast_guidance
  desired_macos_theme_guidance
  desired_omarchy_application_guidance
  run_pending_migrations
  onepassword_manual_guidance
}
