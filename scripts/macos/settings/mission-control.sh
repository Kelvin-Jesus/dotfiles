#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=../../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

run /usr/bin/defaults write com.apple.dock expose-group-apps -bool true
run /usr/bin/defaults write com.apple.dock mru-spaces -bool false
run /usr/bin/defaults write com.apple.spaces spans-displays -bool true
run /usr/bin/defaults write com.apple.WindowManager GloballyEnabled -bool false
run /usr/bin/defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false
run /usr/bin/defaults write com.apple.WindowManager EnableTiledWindowMargins -bool false
