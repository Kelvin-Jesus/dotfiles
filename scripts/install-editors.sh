#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

if [[ "$DRY_RUN" -eq 0 ]]; then
  require_command nvim
fi

run_nvim_checked() {
  local output_file
  if [[ "$DRY_RUN" -eq 1 ]]; then
    run env DOTFILES_FASTFETCH_SHOWN=1 nvim --headless "$@"
    return
  fi

  output_file="$(mktemp)"
  log "\$ env DOTFILES_FASTFETCH_SHOWN=1 nvim --headless $(quote_command "$@")"
  if ! env DOTFILES_FASTFETCH_SHOWN=1 nvim --headless "$@" 2>&1 | tee "$output_file"; then
    rm -f "$output_file"
    die "Neovim setup command failed"
  fi
  if grep -Eq 'Error detected|Installation was aborted|Failed to (clone|install|update)' "$output_file"; then
    rm -f "$output_file"
    die "Neovim reported an installation error"
  fi
  rm -f "$output_file"
}

run rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/nvim/luac"
run_nvim_checked '+Lazy! restore' +qa
run_nvim_checked '+MasonToolsInstallSync' +qa
run_nvim_checked \
  '+lua assert(vim.g.colors_name == "catppuccin-mocha", "Catppuccin is not active")' \
  '+lua assert(vim.o.number and vim.o.relativenumber and not vim.o.wrap, "editor options were not applied")' \
  '+lua assert(require("lazy").stats().count > 0, "LazyVim did not load plugins")' \
  +qa

log "LazyVim plugins restored from the lockfile and Mason tools installed"
