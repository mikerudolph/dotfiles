[[ -r "$DOTFILES_ROOT/shell/common.sh" ]] && . "$DOTFILES_ROOT/shell/common.sh"
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if [[ -n "${DOTFILES_BREW_PREFIX:-}" && -r "$DOTFILES_BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
  . "$DOTFILES_BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
[[ -r "$HOME/.zshrc.local" ]] && . "$HOME/.zshrc.local"
if [[ -n "${DOTFILES_BREW_PREFIX:-}" && -r "$DOTFILES_BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
  . "$DOTFILES_BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi
