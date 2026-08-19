# Keep the user's current keymap; dotfiles deliberately does not force Emacs or
# Vi mode. These bindings apply to whichever main keymap is active.
setopt COMBINING_CHARS

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=* l:|=*'
setopt MENU_COMPLETE
setopt AUTO_MENU
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char
setopt CHASE_LINKS
zstyle ':completion:*' match-hidden-files off
zstyle ':completion:*' list-prompt ''
zstyle ':completion:*' select-prompt ''
zstyle ':completion:*' file-list all
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
if [[ -n "${LS_COLORS:-}" ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi

HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY
setopt APPEND_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY

setopt EXTENDED_GLOB
unsetopt BEEP
setopt INTERACTIVE_COMMENTS
setopt AUTO_CD
