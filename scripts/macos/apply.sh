#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

SKIP_BACKUP=0
SKIP_DOCK=0
SKIP_SIDEBAR=0
SKIP_CAPS=0

usage() {
  cat <<'EOF'
Usage: scripts/macos/apply.sh [options]

  --dry-run             Print changes without applying them
  --skip-backup         Do not capture the current preferences first
  --skip-dock           Do not replace Dock contents
  --skip-sidebar        Do not replace Finder favorites
  --skip-caps           Do not map Caps Lock to Escape
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --skip-backup)
      SKIP_BACKUP=1
      ;;
    --skip-dock)
      SKIP_DOCK=1
      ;;
    --skip-sidebar)
      SKIP_SIDEBAR=1
      ;;
    --skip-caps)
      SKIP_CAPS=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

require_macos
export DOTFILES_DRY_RUN="$DRY_RUN"
init_log "macos-apply"

major_version="$(macos_major_version)"
log "Applying explicit macOS preferences on macOS $major_version"

if [[ "$SKIP_BACKUP" -eq 0 ]]; then
  run_script "$DOTFILES_ROOT/scripts/macos/backup-settings.sh"
fi

for settings_script in \
  global \
  menu-bar \
  finder \
  screenshots \
  mission-control \
  trackpad \
  updates \
  power \
  network \
  apps; do
  run_script "$DOTFILES_ROOT/scripts/macos/settings/$settings_script.sh"
done

if [[ "$SKIP_CAPS" -eq 0 ]]; then
  run_script "$DOTFILES_ROOT/scripts/macos/caps-to-escape.sh"
fi

run_allow_failure /usr/bin/killall cfprefsd
run_allow_failure /usr/bin/killall SystemUIServer
run_allow_failure /usr/bin/killall Finder

if [[ "$SKIP_DOCK" -eq 0 ]]; then
  run_script "$DOTFILES_ROOT/scripts/macos/dock.sh"
fi

if [[ "$SKIP_SIDEBAR" -eq 0 ]]; then
  run_script "$DOTFILES_ROOT/scripts/macos/finder-sidebar.sh"
fi

warn "Some preferences take effect only after logout or restart"
