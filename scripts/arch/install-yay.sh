#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_arch

if command -v yay >/dev/null 2>&1; then
  exit 0
fi

[[ "$EUID" -ne 0 ]] || die "yay must be built as a regular user"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log '$ git clone https://aur.archlinux.org/yay.git <temporary-directory>/yay'
  log '$ makepkg -si --needed'
  exit 0
fi

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"
(
  cd "$temp_dir/yay"
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    makepkg -si --needed --noconfirm
  else
    makepkg -si --needed
  fi
)
