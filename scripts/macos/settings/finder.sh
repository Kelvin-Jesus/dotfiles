#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=../../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

run /usr/bin/defaults write com.apple.finder ShowSidebar -bool true
run /usr/bin/defaults write com.apple.finder ShowToolbar -bool true
run /usr/bin/defaults write com.apple.finder ShowPathbar -bool true
run /usr/bin/defaults write com.apple.finder ShowStatusBar -bool true
run /usr/bin/defaults write com.apple.finder ShowPreviewPane -bool true
run /usr/bin/defaults write com.apple.finder FXPreferredViewStyle -string Nlsv
run /usr/bin/defaults write com.apple.finder FXDefaultSearchScope -string SCev
run /usr/bin/defaults write com.apple.finder NewWindowTarget -string PfLo
run /usr/bin/defaults write com.apple.finder NewWindowTargetPath -string "file://$HOME/Downloads/"
run /usr/bin/defaults write com.apple.finder _FXSortFoldersFirst -bool true
run /usr/bin/defaults write com.apple.finder _FXSortFoldersFirstOnDesktop -bool false
run /usr/bin/defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
run /usr/bin/defaults write com.apple.finder FXRemoveOldTrashItems -bool true
run /usr/bin/defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
run /usr/bin/defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
run /usr/bin/defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
run /usr/bin/defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false
run /usr/bin/defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
run /usr/bin/defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
run chflags nohidden "$HOME/Library"
