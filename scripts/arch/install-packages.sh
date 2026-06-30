#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_arch

if ! command -v yay >/dev/null 2>&1; then
  run_script "$DOTFILES_ROOT/scripts/arch/install-yay.sh"
fi

packages=()
while IFS= read -r line || [[ -n "$line" ]]; do
  line="${line%%#*}"
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"
  [[ -n "$line" ]] && packages+=("$line")
done <"$DOTFILES_ROOT/packages/arch/packages.txt"

yay_args=(-Syu --needed)
if [[ "$ASSUME_YES" -eq 1 ]]; then
  yay_args+=(--noconfirm)
fi

run yay "${yay_args[@]}" "${packages[@]}"
run_script "$DOTFILES_ROOT/scripts/arch/install-newsreader-font.sh"
