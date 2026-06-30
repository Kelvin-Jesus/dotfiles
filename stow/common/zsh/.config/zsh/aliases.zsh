alias ls='eza --icons=auto --group-directories-first'
alias ll='eza --long --all --header --git --icons=auto --group-directories-first'
alias la='eza --all --icons=auto --group-directories-first'
alias l='eza --long --all --header --git --icons=auto --group-directories-first'
alias lsa='eza --long --all --header --git --icons=auto --group-directories-first'
alias tree='eza --tree --icons=auto --group-directories-first'

alias ping-native='command ping'
alias ping='gping'

alias -- -='cd -'
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias -g ......='../../../../..'
alias 1='cd -1'
alias 2='cd -2'
alias 3='cd -3'
alias 4='cd -4'
alias 5='cd -5'
alias 6='cd -6'
alias 7='cd -7'
alias 8='cd -8'
alias 9='cd -9'
alias _='sudo '
alias egrep='grep -E'
alias fgrep='grep -F'
alias grep='grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox,.venv,venv}'
alias md='mkdir -p'
alias rd='rmdir'

history-list() {
  local clear list stamp REPLY
  zparseopts -E -D c=clear l=list f=stamp E=stamp i=stamp t:=stamp

  if [[ -n "$clear" ]]; then
    print -nu2 "This action will irreversibly delete your command history. Are you sure? [y/N] "
    builtin read -E
    [[ "$REPLY" = [yY] ]] || return 0
    print -nu2 >| "$HISTFILE"
    fc -p "$HISTFILE"
    print -u2 "History file deleted."
  elif [[ $# -eq 0 ]]; then
    builtin fc "${stamp[@]}" -l 1
  else
    builtin fc "${stamp[@]}" -l "$@"
  fi
}
alias history='history-list'

alias reload-zsh='exec zsh'
alias zshconfig='$EDITOR ~/.zshrc'
alias starshipconfig='$EDITOR ~/.config/starship.toml'
