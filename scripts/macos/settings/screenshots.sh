#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=../../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

screenshot_dir="${DOTFILES_SCREENSHOT_DIR:-$HOME/Documents/Screenshots}"
ensure_dir "$screenshot_dir"
run /usr/bin/defaults write com.apple.screencapture location -string "$screenshot_dir"
run /usr/bin/defaults write com.apple.screencapture type -string png
run /usr/bin/defaults write com.apple.screencapture include-date -bool true
run /usr/bin/defaults write com.apple.screencapture show-thumbnail -bool true
run /usr/bin/defaults write com.apple.screencapture disable-shadow -bool false
