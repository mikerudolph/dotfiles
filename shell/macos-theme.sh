# Tokyo Night is intentionally macOS-only. Omarchy owns its active theme and
# propagates it through its supported selector and generated user layer.
_dotfiles_config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
export STARSHIP_CONFIG="$_dotfiles_config_home/starship.toml"
export EZA_CONFIG_DIR="$_dotfiles_config_home/eza"
export BAT_THEME="ansi"
export K9S_SKIN="tokyonight"
export GLOW_STYLE="$_dotfiles_config_home/glow/tokyonight.json"
export GLAMOUR_STYLE="$GLOW_STYLE"

_dotfiles_lazygit_theme="$DOTFILES_ROOT/themes/tokyonight/lazygit.yml"
if [[ ",${LG_CONFIG_FILE:-}," != *",$_dotfiles_lazygit_theme,"* ]]; then
  if [[ -n "${LG_CONFIG_FILE:-}" ]]; then
    LG_CONFIG_FILE="$LG_CONFIG_FILE,$_dotfiles_lazygit_theme"
  else
    if [[ -n "${XDG_CONFIG_HOME:-}" ]]; then
      _dotfiles_lazygit_local="$XDG_CONFIG_HOME/lazygit/config.yml"
    else
      _dotfiles_lazygit_local="$HOME/Library/Application Support/lazygit/config.yml"
    fi
    if [[ -f "$_dotfiles_lazygit_local" ]]; then
      LG_CONFIG_FILE="$_dotfiles_lazygit_local,$_dotfiles_lazygit_theme"
    else
      LG_CONFIG_FILE="$_dotfiles_lazygit_theme"
    fi
  fi
fi
export LG_CONFIG_FILE

[[ -r "$DOTFILES_ROOT/themes/tokyonight/fzf.sh" ]] && . "$DOTFILES_ROOT/themes/tokyonight/fzf.sh"
unset _dotfiles_config_home _dotfiles_lazygit_local _dotfiles_lazygit_theme
