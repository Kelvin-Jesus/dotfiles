#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=../../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

run /usr/bin/defaults write NSGlobalDomain AppleInterfaceStyle -string Dark
run /usr/bin/defaults write NSGlobalDomain AppleIconAppearanceTheme -string RegularDark
run /usr/bin/defaults write NSGlobalDomain _HIHideMenuBar -bool true
run /usr/bin/defaults write NSGlobalDomain AppleShowAllExtensions -bool true
run /usr/bin/defaults write NSGlobalDomain AppleShowAllFiles -bool true
run /usr/bin/defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
run /usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 15
run /usr/bin/defaults write NSGlobalDomain KeyRepeat -int 2
run /usr/bin/defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool true
run /usr/bin/defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool true
run /usr/bin/defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
run /usr/bin/defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true
run /usr/bin/defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
run /usr/bin/defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true
run /usr/bin/defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
run /usr/bin/defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
