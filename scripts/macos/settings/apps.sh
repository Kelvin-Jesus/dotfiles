#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=../../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

if command -v defaultbrowser >/dev/null 2>&1; then
  run_allow_failure defaultbrowser zen
elif [[ "$DRY_RUN" -eq 1 ]]; then
  log '$ defaultbrowser zen'
else
  warn "defaultbrowser is unavailable; choose Zen manually"
fi

if [[ -n "${DOTFILES_COMPUTER_NAME:-}" ]]; then
  run_sudo /usr/sbin/scutil --set ComputerName "$DOTFILES_COMPUTER_NAME"
  run_sudo /usr/sbin/scutil --set LocalHostName "$DOTFILES_COMPUTER_NAME"
  run_sudo /usr/sbin/scutil --set HostName "$DOTFILES_COMPUTER_NAME"
else
  log "Hostname unchanged; set DOTFILES_COMPUTER_NAME to configure it"
fi
