[[ $- == *i* ]] || return 0

__dotfiles_sanitize_prompt() {
  printf '\r\033[K'
}
case ";${PROMPT_COMMAND:-};" in
  *';__dotfiles_sanitize_prompt;'*) ;;
  *) PROMPT_COMMAND="__dotfiles_sanitize_prompt${PROMPT_COMMAND:+;$PROMPT_COMMAND}" ;;
esac

[[ -r "$DOTFILES_ROOT/shell/common.sh" ]] && . "$DOTFILES_ROOT/shell/common.sh"

bind 'set completion-ignore-case on'
bind 'set completion-prefix-display-length 2'
bind 'set show-all-if-ambiguous on'
bind 'set show-all-if-unmodified on'
bind '"\e[A": history-search-backward'
bind '"\e[B": history-search-forward'
bind '"\e[C": forward-char'
bind '"\e[D": backward-char'
bind 'set mark-symlinked-directories on'
bind 'set match-hidden-files off'
bind 'set page-completions off'
bind 'set completion-query-items 200'
bind 'set visible-stats on'
bind 'set skip-completed-text on'
bind 'set colored-stats on'
bind 'TAB: menu-complete'
bind '"\e[Z": menu-complete-backward'
bind 'set menu-complete-display-prefix on'

[[ -r "$HOME/.bashrc.local" ]] && . "$HOME/.bashrc.local"
