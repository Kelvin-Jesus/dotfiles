#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=../../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

run /usr/bin/defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
run /usr/bin/defaults write com.apple.SoftwareUpdate AutomaticDownload -bool true
run /usr/bin/defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
run /usr/bin/defaults write com.apple.SoftwareUpdate ConfigDataInstall -bool true
run /usr/bin/defaults write com.apple.commerce AutoUpdate -bool true
