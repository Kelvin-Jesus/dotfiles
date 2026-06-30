#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

wallpaper=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h | --help)
      printf 'Usage: set-wallpaper.sh [--dry-run] [IMAGE]\n'
      exit 0
      ;;
    *)
      [[ -z "$wallpaper" ]] || die "only one wallpaper path is accepted"
      wallpaper="$1"
      ;;
  esac
  shift
done

if [[ -z "$wallpaper" && -n "${WALLPAPER_DIR:-}" && -d "$WALLPAPER_DIR" ]]; then
  wallpaper="$(
    find "$WALLPAPER_DIR" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.heic' \) \
      -print -quit
  )"
fi

wallpaper="${wallpaper:-$DOTFILES_ROOT/assets/wallpaper-fallback.svg}"
[[ -f "$wallpaper" ]] || die "wallpaper not found: $wallpaper"

case "$(detect_platform)" in
  macos)
    script="tell application \"System Events\" to tell every desktop to set picture to POSIX file \"$wallpaper\""
    run /usr/bin/osascript -e "$script"
    ;;
  arch)
    if command -v swww >/dev/null 2>&1; then
      run swww img "$wallpaper"
    elif command -v feh >/dev/null 2>&1; then
      run feh --bg-fill "$wallpaper"
    else
      warn "No desktop environment assumed; install swww/feh or set the wallpaper manually"
    fi
    ;;
esac
