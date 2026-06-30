#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

if [[ "$DRY_RUN" -eq 0 ]]; then
  require_command zsh
  require_command git
fi

zsh_bin="$(command -v zsh 2>/dev/null || true)"
if [[ -z "$zsh_bin" ]]; then
  if [[ "$DRY_RUN" -eq 1 ]]; then
    zsh_bin="/path/to/zsh"
  else
    die "zsh is not installed"
  fi
fi

append_line_sudo "$zsh_bin" /etc/shells

if [[ "${SHELL:-}" != "$zsh_bin" ]]; then
  run chsh -s "$zsh_bin"
fi

tpm_dir="$HOME/.tmux/plugins/tpm"
if [[ ! -d "$tpm_dir/.git" ]]; then
  run git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
fi

if [[ -x "$tpm_dir/bin/install_plugins" ]]; then
  run tmux start-server \; set-environment -g \
    TMUX_PLUGIN_MANAGER_PATH "$HOME/.tmux/plugins/"
  run "$tpm_dir/bin/install_plugins"
elif [[ "$DRY_RUN" -eq 1 ]]; then
  log "\$ $tpm_dir/bin/install_plugins"
fi

log "Zsh and tmux integration configured"
