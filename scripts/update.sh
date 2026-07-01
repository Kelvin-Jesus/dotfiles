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
    --yes)
      ASSUME_YES=1
      ;;
    -h | --help)
      printf 'Usage: update.sh [--dry-run] [--yes]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

export DOTFILES_DRY_RUN="$DRY_RUN"
export DOTFILES_ASSUME_YES="$ASSUME_YES"
init_log "update"

platform="$(detect_platform)"
case "$platform" in
  macos)
    if [[ "$DRY_RUN" -eq 0 ]]; then
      require_command brew
    fi
    run brew update
    run brew bundle install --file="$DOTFILES_ROOT/packages/macos/Brewfile"
    run brew upgrade
    ;;
  arch)
    yay_args=(-Syu)
    if [[ "$ASSUME_YES" -eq 1 ]]; then
      yay_args+=(--noconfirm)
    fi
    run yay "${yay_args[@]}"
    ;;
esac

if command -v mise >/dev/null 2>&1 || [[ "$DRY_RUN" -eq 1 ]]; then
  mise_args=(upgrade)
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    mise_args+=(--yes)
  fi
  run mise "${mise_args[@]}"
fi

if command -v nvim >/dev/null 2>&1 || [[ "$DRY_RUN" -eq 1 ]]; then
  run env DOTFILES_FASTFETCH_SHOWN=1 nvim --headless '+Lazy! update' +qa
fi

tpm_update="$HOME/.tmux/plugins/tpm/bin/update_plugins"
if [[ -x "$tpm_update" ]]; then
  run "$tpm_update" all
elif [[ "$DRY_RUN" -eq 1 ]]; then
  log "\$ $tpm_update all"
else
  warn "TPM is not installed; tmux plugins were not updated"
fi

run_script "$DOTFILES_ROOT/scripts/doctor.sh" --soft
log "Update complete; review and commit changes to versioned lockfiles"
