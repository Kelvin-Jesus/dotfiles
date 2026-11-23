#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

WITH_OPTIONAL_APPS=0

usage() {
  printf 'Usage: install-packages.sh [--dry-run] [--yes] [--with-optional-apps]\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --yes)
      ASSUME_YES=1
      ;;
    --with-optional-apps)
      WITH_OPTIONAL_APPS=1
      ;;
    -h | --help)
      usage
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
platform="$(detect_platform)"

case "$platform" in
  macos)
    if [[ "$DRY_RUN" -eq 0 ]]; then
      require_command brew
    fi
    run brew tap go-task/tap
    run brew tap can1357/tap
    if [[ "$DRY_RUN" -eq 1 ]] || brew help trust >/dev/null 2>&1; then
      run brew trust --cask go-task/tap/go-task
      run brew trust --formula can1357/tap/omp
    fi
    run brew bundle install --verbose --file="$DOTFILES_ROOT/packages/macos/Brewfile"
    run_script "$DOTFILES_ROOT/scripts/macos/install-release-apps.sh" open-design motrixmac omlx learnharness index0
    if [[ "$WITH_OPTIONAL_APPS" -eq 1 ]]; then
      run_script "$DOTFILES_ROOT/scripts/macos/install-release-apps.sh" sidescreen spotiflac
    fi
    ;;
  arch)
    run_script "$DOTFILES_ROOT/scripts/arch/install-packages.sh"
    ;;
esac

run_script "$DOTFILES_ROOT/scripts/install-mailghost.sh"
