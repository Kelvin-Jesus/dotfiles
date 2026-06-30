#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

developer_dir="$HOME/Developer"
system_icon="/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/DeveloperFolderIcon.icns"
finder_icon="$developer_dir/Icon"$'\r'

ensure_dir "$developer_dir"
[[ -f "$system_icon" ]] || die "native Developer folder icon not found: $system_icon"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "\$ apply native DeveloperFolderIcon.icns to $developer_dir"
  exit 0
fi

derez="$(xcrun -f DeRez)"
rez="$(xcrun -f Rez)"
set_file="$(xcrun -f SetFile)"
temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

icon_copy="$temp_dir/DeveloperFolderIcon.icns"
resource_file="$temp_dir/DeveloperFolderIcon.rsrc"

cp "$system_icon" "$icon_copy"
/usr/bin/sips -i "$icon_copy" >/dev/null
"$derez" -only icns "$icon_copy" >"$resource_file"
"$rez" -append "$resource_file" -o "$finder_icon"
"$set_file" -a C "$developer_dir"
"$set_file" -a V "$finder_icon"

log "Applied the native macOS Developer folder icon"
