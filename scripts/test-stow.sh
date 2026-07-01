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
    "$apply_script" "$@"
}

run_test

stale_link="$temp_home/.config/nvim/lua/plugins/removed.lua"
ln -s \
  "$DOTFILES_ROOT/stow/common/nvim/.config/nvim/lua/plugins/removed.lua" \
  "$stale_link"

run_test

[[ ! -L "$stale_link" ]] || die "stale managed symlink was not removed"

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

conflict="$temp_home/.config/starship.toml"
rm "$conflict"
printf 'local conflict\n' >"$conflict"
preflight_script="$DOTFILES_ROOT/scripts/stow-preflight.sh"

if HOME="$temp_home" \
  STOW_TARGET="$temp_home" \
  DOTFILES_ROOT="$DOTFILES_ROOT" \
  DOTFILES_STATE_DIR="$temp_home/.local/state/dotfiles" \
  "$preflight_script"; then
  die "Stow preflight accepted a conflicting regular file"
fi

run_test --backup-conflicts
[[ -L "$conflict" ]] || die "conflicting file was not replaced by a Stow link"
backup_link="$temp_home/.local/state/dotfiles/backups/stow/latest"
[[ -L "$backup_link" ]] || die "Stow conflict backup pointer was not created"
grep -Fqx 'local conflict' "$backup_link/.config/starship.toml" \
  || die "Stow conflict content was not preserved"

log "Stow is idempotent in a temporary HOME"
