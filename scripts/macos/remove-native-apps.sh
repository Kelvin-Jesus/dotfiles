#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

APPLY=0
requested=()

usage() {
  cat <<'EOF'
Usage: remove-native-apps.sh [--apply] [--yes] [app ...]

Dry-run is the default. Allowed names:
  GarageBand iMovie Pages Numbers Keynote
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --apply)
      APPLY=1
      ;;
    --dry-run)
      APPLY=0
      ;;
    --yes)
      ASSUME_YES=1
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      requested+=("$1")
      ;;
  esac
  shift
done

if [[ "${DOTFILES_DRY_RUN:-0}" == "1" ]]; then
  APPLY=0
fi
if [[ "$APPLY" -eq 0 ]]; then
  DRY_RUN=1
fi

allowed=(
  GarageBand
  iMovie
  Pages
  Numbers
  Keynote
)

if [[ "${#requested[@]}" -eq 0 ]]; then
  requested=("${allowed[@]}")
fi

is_allowed() {
  local candidate item
  candidate="$1"
  for item in "${allowed[@]}"; do
    [[ "$candidate" == "$item" ]] && return 0
  done
  return 1
}

paths=()
for name in "${requested[@]}"; do
  is_allowed "$name" || die "app is not in the allowlist: $name"
  path="/Applications/$name.app"
  [[ "$path" == /Applications/*.app ]] || die "unsafe app path: $path"
  [[ "$path" != /System/Applications/* ]] || die "system applications are protected"
  paths+=("$path")
done

if [[ "$APPLY" -eq 1 ]] \
  && ! confirm "Remove the selected applications from /Applications?"; then
  log "Cancelled"
  exit 0
fi

init_log "native-app-removal"
for path in "${paths[@]}"; do
  if [[ -e "$path" || "$DRY_RUN" -eq 1 ]]; then
    run_sudo rm -rf "$path"
  else
    log "Already absent: $path"
  fi
done

if [[ "$APPLY" -eq 0 ]]; then
  log "Dry-run only. Pass --apply to remove allowlisted applications."
fi
