#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h | --help)
      printf 'Usage: dock.sh [--dry-run]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

if [[ "$DRY_RUN" -eq 0 ]]; then
  require_command dockutil
fi

run /usr/bin/defaults write com.apple.dock autohide -bool true
run /usr/bin/defaults write com.apple.dock autohide-delay -float 0
run /usr/bin/defaults write com.apple.dock autohide-time-modifier -float 0.5
run /usr/bin/defaults write com.apple.dock tilesize -int 66
run /usr/bin/defaults write com.apple.dock magnification -bool true
run /usr/bin/defaults write com.apple.dock largesize -int 95
run /usr/bin/defaults write com.apple.dock show-recents -bool false
run /usr/bin/defaults write com.apple.dock minimize-to-application -bool true
run /usr/bin/defaults write com.apple.dock orientation -string bottom

ensure_dir "$HOME/Developer"
run dockutil --remove all --no-restart

if [[ -d /System/Applications/Apps.app || "$DRY_RUN" -eq 1 ]]; then
  run dockutil --add /System/Applications/Apps.app --no-restart
fi
if [[ -d /Applications/Zen.app || "$DRY_RUN" -eq 1 ]]; then
  run dockutil --add /Applications/Zen.app --no-restart
fi

run dockutil \
  --add "$HOME/Developer" \
  --view grid \
  --display folder \
  --sort name \
  --section others \
  --no-restart

run_allow_failure /usr/bin/killall Dock
