HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000

setopt append_history
setopt always_to_end
setopt auto_cd
setopt auto_pushd
setopt combining_chars
setopt complete_in_word
setopt extended_history
setopt hist_expire_dups_first
setopt hist_find_no_dups
setopt hist_ignore_all_dups
setopt hist_ignore_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_save_no_dups
setopt hist_verify
setopt interactive_comments
setopt long_list_jobs
setopt no_flow_control
setopt prompt_subst
setopt pushd_ignore_dups
setopt pushd_minus
setopt share_history

# Keep word navigation consistent across macOS and Linux terminals.
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
