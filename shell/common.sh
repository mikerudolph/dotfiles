# Shared interactive shell behavior. Keep this file free of subprocess-heavy
# detection, package management, network access, and repository updates.
case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH
export EDITOR="nvim"
export SUDO_EDITOR="$EDITOR"

[[ -r "$DOTFILES_ROOT/shell/functions.sh" ]] && . "$DOTFILES_ROOT/shell/functions.sh"

_dotfiles_shell_name="${ZSH_VERSION:+zsh}"
_dotfiles_shell_name="${_dotfiles_shell_name:-bash}"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate "$_dotfiles_shell_name")"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init "$_dotfiles_shell_name")"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init "$_dotfiles_shell_name")"
fi

unset _dotfiles_shell_name
[[ -r "$DOTFILES_ROOT/shell/aliases.sh" ]] && . "$DOTFILES_ROOT/shell/aliases.sh"
