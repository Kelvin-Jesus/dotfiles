#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_arch

google_fonts_commit="639018367a1368374e833e10a1c0bba66ac20df1"
font_dir="$HOME/.local/share/fonts/Newsreader"

download_font() {
  local filename expected url destination actual
  filename="$1"
  expected="$2"
  url="https://raw.githubusercontent.com/google/fonts/$google_fonts_commit/ofl/newsreader/$filename"
  destination="$font_dir/$filename"

  run curl -gfsSL "$url" -o "$destination"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "\$ verify SHA-256 $expected for $filename"
    return
  fi

  actual="$(sha256sum "$destination" | awk '{ print $1 }')"
  [[ "$actual" == "$expected" ]] || die "checksum mismatch for $filename"
}

ensure_dir "$font_dir"
download_font \
  'Newsreader[opsz,wght].ttf' \
  8a08d13f8a6c0d51be379a60af84f945f65369a67e509ee3c3bdcc421254d7c1
download_font \
  'Newsreader-Italic[opsz,wght].ttf' \
  796668611f80b64d5adf182fde3b6f29ed83b4e7cbec7b96937e84ac01364792

run fc-cache -f "$font_dir"
