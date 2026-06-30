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
      printf 'Usage: finder-sidebar.sh [--dry-run]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

major_version="$(macos_major_version)"
case "$major_version" in
  13 | 15 | 26)
    ;;
  *)
    if [[ "${DOTFILES_ALLOW_UNTESTED_MACOS:-0}" != "1" ]]; then
      warn "Finder sidebar automation is not tested on macOS $major_version"
      warn "Set DOTFILES_ALLOW_UNTESTED_MACOS=1 to override"
      exit 0
    fi
    ;;
esac

if ! command -v sbedit >/dev/null 2>&1; then
  run_script "$DOTFILES_ROOT/scripts/macos/install-sbedit.sh"
fi

ensure_dir "$HOME/Developer"
ensure_dir "$HOME/Library/Saved Searches"

recents="$HOME/Library/Saved Searches/Recents.savedSearch"
system_recents="/System/Library/CoreServices/Finder.app/Contents/Resources/MyLibraries/myDocuments.cannedSearch"
if [[ ! -f "$recents" && -f "$system_recents" ]]; then
  run cp "$system_recents" "$recents"
fi

shared_dir="$HOME/Library/Application Support/com.apple.sharedfilelist"
backup_dir="$DOTFILES_STATE_DIR/backups/macos/$(timestamp)-finder-sidebar"
ensure_dir "$backup_dir"

sidebar_backup=""
if [[ -d "$shared_dir" ]]; then
  sidebar_file="$(
    find "$shared_dir" -maxdepth 1 -type f \
      \( -name '*FavoriteItems*.sfl3' -o -name '*FavoriteItems*.sfl4' \) \
      -print -quit 2>/dev/null || true
  )"
  if [[ -n "$sidebar_file" ]]; then
    sidebar_backup="$backup_dir/$(basename "$sidebar_file")"
    run cp -p "$sidebar_file" "$sidebar_backup"
  fi
fi

if [[ "$DRY_RUN" -eq 0 ]] && ! command -v sbedit >/dev/null 2>&1; then
  warn "sbedit is unavailable; configure Finder favorites manually"
  exit 0
fi

if ! run sbedit --list; then
  warn "sbedit cannot read Finder favorites; Full Disk Access may be required"
  exit 0
fi

favorites=(
  /Applications
  "$HOME"
  "$HOME/Developer"
  "$HOME/Downloads"
  "$HOME/Documents"
)
if [[ -f "$recents" || "$DRY_RUN" -eq 1 ]]; then
  favorites+=("$recents")
fi

if ! run sbedit --removeAll || ! run sbedit --add "${favorites[@]}"; then
  warn "Failed to update Finder favorites"
  if [[ -n "$sidebar_backup" ]]; then
    run cp -p "$sidebar_backup" "$shared_dir/$(basename "$sidebar_backup")"
  fi
  run_allow_failure sbedit --reload --force
  exit 0
fi

run sbedit --list
run sbedit --reload --force
log "Finder favorites configured in the requested order"
