#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

init_log "seed-zoxide"

if ! command -v zoxide >/dev/null 2>&1; then
  warn "zoxide is not installed; skipping zoxide seed"
  exit 0
fi

zoxide_dirs=(
  "$HOME/Developer"
  "$HOME/Documents"
  "$HOME/Documents/obsidian-vault"
  "$HOME/Documents/wallpapers"
)

for dir in "${zoxide_dirs[@]}"; do
  ensure_dir "$dir"
  run zoxide add --score 20 "$dir"
done

log "Seeded zoxide with primary directories"
