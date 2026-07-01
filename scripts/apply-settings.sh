#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h | --help)
      printf 'Usage: apply-settings.sh [--dry-run]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

export DOTFILES_DRY_RUN="$DRY_RUN"
platform="$(detect_platform)"
case "$platform" in
  macos)
    run_script "$DOTFILES_ROOT/scripts/macos/apply.sh"
    ;;
  arch)
    run_script "$DOTFILES_ROOT/scripts/arch/caps-to-escape.sh"
    run_script "$DOTFILES_ROOT/scripts/arch/services.sh"
    ;;
esac
run_script "$DOTFILES_ROOT/scripts/set-wallpaper.sh"
