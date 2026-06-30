#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=../../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

run /usr/bin/defaults write com.apple.controlcenter AutoHideMenuBarOption -int 1
run /usr/bin/defaults write com.apple.menuextra.clock DateFormat -string "HH:mm"
run /usr/bin/defaults write com.apple.menuextra.clock IsAnalog -bool false
run /usr/bin/defaults write com.apple.menuextra.clock ShowDate -int 0
run /usr/bin/defaults write com.apple.menuextra.clock ShowDayOfWeek -bool false
run /usr/bin/defaults write com.apple.menuextra.clock ShowSeconds -bool false

run_allow_failure /usr/bin/killall ControlCenter
run_allow_failure /usr/bin/killall SystemUIServer
