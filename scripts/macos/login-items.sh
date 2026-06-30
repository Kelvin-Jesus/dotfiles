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
      printf 'Usage: login-items.sh [--dry-run]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

add_login_item() {
  local name path script
  name="$1"
  path="$2"
  [[ -d "$path" || "$DRY_RUN" -eq 1 ]] || return
  script="tell application \"System Events\" to if not (exists login item \"$name\") then make login item at end with properties {name:\"$name\", path:\"$path\", hidden:true}"
  run /usr/bin/osascript -e "$script"
}

add_login_item "LocalSend" "/Applications/LocalSend.app"
add_login_item "Syncthing" "/Applications/Syncthing.app"

warn "macOS may request Automation permission for System Events"
