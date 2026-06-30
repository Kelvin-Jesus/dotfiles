#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

temp_home="$(mktemp -d)"
trap 'rm -rf "$temp_home"' EXIT

run_test() {
  local apply_script
  apply_script="$DOTFILES_ROOT/scripts/apply-stow.sh"
  HOME="$temp_home" \
    STOW_TARGET="$temp_home" \
    DOTFILES_ROOT="$DOTFILES_ROOT" \
    DOTFILES_STATE_DIR="$temp_home/.local/state/dotfiles" \
    DOTFILES_DRY_RUN=0 \
    "$apply_script"
}

run_test
run_test

expected=(
  "$temp_home/.zshrc"
  "$temp_home/.gitconfig"
  "$temp_home/.config/nvim/init.lua"
  "$temp_home/.config/starship.toml"
  "$temp_home/.config/tmux/tmux.conf"
  "$temp_home/.config/zed/settings.json"
)

for path in "${expected[@]}"; do
  [[ -L "$path" ]] || die "expected Stow symlink was not created: $path"
done

log "Stow is idempotent in a temporary HOME"
