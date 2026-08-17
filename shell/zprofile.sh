case ":$PATH:" in
  *":$HOME/.local/bin:"*) ;;
  *) PATH="$HOME/.local/bin:$PATH" ;;
esac
export PATH
export HOMEBREW_NO_ENV_HINTS=1
[[ -r "$HOME/.zprofile.local" ]] && . "$HOME/.zprofile.local"
