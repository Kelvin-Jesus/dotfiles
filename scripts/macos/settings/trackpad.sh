#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=../../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

run /usr/bin/defaults write NSGlobalDomain com.apple.trackpad.scaling -float 2.5
run /usr/bin/defaults write NSGlobalDomain com.apple.mouse.tracking -float 2.5
run /usr/bin/defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true
run /usr/bin/defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
run /usr/bin/defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
run /usr/bin/defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
run /usr/bin/defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true
run /usr/bin/defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
run /usr/bin/defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
