_dotfiles_fastfetch_once() {
  emulate -L zsh

  [[ -o interactive && -t 1 && ${TERM:-dumb} != dumb ]] || return
  (( $+commands[fastfetch] )) || return
  [[ -z ${DOTFILES_FASTFETCH_SHOWN:-} ]] || return

  # A tmux server can outlive the terminal that created it. Its global option
  # prevents Fastfetch from running again in every new pane or window.
  if [[ -n ${TMUX:-} ]]; then
    [[ -z "$(tmux show-option -gqv @dotfiles_fastfetch_shown 2>/dev/null)" ]] ||
      return
    tmux set-option -gq @dotfiles_fastfetch_shown 1 2>/dev/null
  fi

  export DOTFILES_FASTFETCH_SHOWN=1
  fastfetch
}

_dotfiles_fastfetch_once
unfunction _dotfiles_fastfetch_once
