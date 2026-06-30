#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

OUTPUT_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --output)
      [[ $# -ge 2 ]] || die "--output requires a directory"
      OUTPUT_DIR="$2"
      shift
      ;;
    -h | --help)
      printf 'Usage: backup-settings.sh [--dry-run] [--output DIR]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

backup_root="$DOTFILES_STATE_DIR/backups/macos"
backup_dir="${OUTPUT_DIR:-$backup_root/$(timestamp)}"
ensure_dir "$backup_dir/defaults"

domains=(
  NSGlobalDomain
  com.apple.desktopservices
  com.apple.dock
  com.apple.finder
  com.apple.screencapture
  com.apple.SoftwareUpdate
  com.apple.commerce
  com.apple.spaces
  com.apple.WindowManager
  com.apple.AppleMultitouchTrackpad
  com.apple.driver.AppleBluetoothMultitouch.trackpad
)

for domain in "${domains[@]}"; do
  run_allow_failure /usr/bin/defaults export "$domain" "$backup_dir/defaults/$domain.plist"
done

capture_to_allow_failure "$backup_dir/macos-version.txt" /usr/bin/sw_vers
capture_to_allow_failure "$backup_dir/power-settings.txt" /usr/bin/pmset -g custom
capture_to_allow_failure "$backup_dir/finder-report.txt" /usr/bin/defaults read com.apple.finder
capture_to_allow_failure "$backup_dir/dock-report.txt" /usr/bin/defaults read com.apple.dock

shared_dir="$HOME/Library/Application Support/com.apple.sharedfilelist"
if [[ -d "$shared_dir" ]]; then
  while IFS= read -r sidebar_file; do
    [[ -n "$sidebar_file" ]] || continue
    run cp -p "$sidebar_file" "$backup_dir/$(basename "$sidebar_file")"
  done < <(
    find "$shared_dir" -maxdepth 1 -type f \
      \( -name '*FavoriteItems*.sfl3' -o -name '*FavoriteItems*.sfl4' \) \
      2>/dev/null
  )
fi

if [[ "$DRY_RUN" -eq 0 ]]; then
  ln -sfn "$backup_dir" "$backup_root/latest"
fi

log "macOS backup: $backup_dir"
