# Shared interactive shell behavior. Keep this file free of subprocess-heavy
# detection, package management, network access, and repository updates.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH

[[ -r "$DOTFILES_ROOT/shell/aliases.sh" ]] && . "$DOTFILES_ROOT/shell/aliases.sh"

if command -v starship >/dev/null 2>&1; then
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    eval "$(starship init zsh)"
  elif [[ -n "${BASH_VERSION:-}" ]]; then
    eval "$(starship init bash)"
  fi
fi

if command -v zoxide >/dev/null 2>&1; then
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    eval "$(zoxide init zsh)"
  elif [[ -n "${BASH_VERSION:-}" ]]; then
    eval "$(zoxide init bash)"
  fi
fi
