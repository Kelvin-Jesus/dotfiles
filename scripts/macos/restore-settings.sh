#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

backup_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h | --help)
      printf 'Usage: restore-settings.sh [--dry-run] BACKUP_DIR\n'
      exit 0
      ;;
    *)
      [[ -z "$backup_dir" ]] || die "only one backup directory is accepted"
      backup_dir="$1"
      ;;
  esac
  shift
done

[[ -n "$backup_dir" ]] || die "a backup directory is required"
[[ -d "$backup_dir/defaults" ]] || die "invalid backup directory: $backup_dir"

for plist in "$backup_dir/defaults/"*.plist; do
  [[ -f "$plist" ]] || continue
  domain="$(basename "$plist" .plist)"
  run /usr/bin/defaults import "$domain" "$plist"
done

shared_dir="$HOME/Library/Application Support/com.apple.sharedfilelist"
for sidebar_file in "$backup_dir/"*FavoriteItems*.sfl[34]; do
  [[ -f "$sidebar_file" ]] || continue
  ensure_dir "$shared_dir"
  run cp -p "$sidebar_file" "$shared_dir/$(basename "$sidebar_file")"
done

run_allow_failure /usr/bin/killall cfprefsd
run_allow_failure /usr/bin/killall sharedfilelistd
run_allow_failure /usr/bin/killall Finder
run_allow_failure /usr/bin/killall Dock
log "Preferences restored from $backup_dir"
