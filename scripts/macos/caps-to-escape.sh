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
      printf 'Usage: caps-to-escape.sh [--dry-run]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

mapping='{"UserKeyMapping":[{"HIDKeyboardModifierMappingSrc":30064771129,"HIDKeyboardModifierMappingDst":30064771113}]}'
plist="$HOME/Library/LaunchAgents/com.dotfiles.caps-to-escape.plist"

run /usr/bin/hidutil property --set "$mapping"

if [[ -f "$plist" || "$DRY_RUN" -eq 1 ]]; then
  domain="gui/$UID"
  if [[ "$DRY_RUN" -eq 1 ]] \
    || /bin/launchctl print "$domain/com.dotfiles.caps-to-escape" >/dev/null 2>&1; then
    run /bin/launchctl bootout "$domain" "$plist"
  fi
  run /bin/launchctl bootstrap "$domain" "$plist"
  run /bin/launchctl enable "$domain/com.dotfiles.caps-to-escape"
else
  die "LaunchAgent not found: $plist; apply the macos Stow package first"
fi

log "Caps Lock maps to Escape now and at login"
