#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

vault="${1:-${OBSIDIAN_VAULT:-$HOME/Documents/obsidian-vault}}"
if [[ ! -d "$vault/.obsidian" ]]; then
  warn "Obsidian vault not found at $vault; portable fonts were skipped"
  exit 0
fi

font_dir="$vault/.obsidian/fonts"
snippet_dir="$vault/.obsidian/snippets"
appearance="$vault/.obsidian/appearance.json"
google_fonts_commit="639018367a1368374e833e10a1c0bba66ac20df1"
nerd_fonts_commit="fa7b859994228a9c8759f99c55a8d31ee92a1b5e"

download_font() {
  local source_url destination expected actual
  source_url="$1"
  destination="$2"
  expected="$3"

  run curl -gfsSL "$source_url" -o "$destination"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "\$ verify SHA-256 $expected for $(basename "$destination")"
    return
  fi

  if command -v sha256sum >/dev/null 2>&1; then
    actual="$(sha256sum "$destination" | awk '{ print $1 }')"
  else
    actual="$(/usr/bin/shasum -a 256 "$destination" | awk '{ print $1 }')"
  fi
  [[ "$actual" == "$expected" ]] || die "checksum mismatch for $destination"
}

ensure_dir "$font_dir"
ensure_dir "$snippet_dir"

download_font \
  "https://raw.githubusercontent.com/google/fonts/$google_fonts_commit/ofl/newsreader/Newsreader[opsz,wght].ttf" \
  "$font_dir/Newsreader-Variable.ttf" \
  8a08d13f8a6c0d51be379a60af84f945f65369a67e509ee3c3bdcc421254d7c1
download_font \
  "https://raw.githubusercontent.com/google/fonts/$google_fonts_commit/ofl/newsreader/Newsreader-Italic[opsz,wght].ttf" \
  "$font_dir/Newsreader-Italic-Variable.ttf" \
  796668611f80b64d5adf182fde3b6f29ed83b4e7cbec7b96937e84ac01364792
download_font \
  "https://raw.githubusercontent.com/google/fonts/$google_fonts_commit/ofl/inter/Inter[opsz,wght].ttf" \
  "$font_dir/Inter-Variable.ttf" \
  29160a80ff49ddcab2c97711247e08b1fab27a484a329ce8b813d820dc559031
download_font \
  "https://raw.githubusercontent.com/google/fonts/$google_fonts_commit/ofl/inter/Inter-Italic[opsz,wght].ttf" \
  "$font_dir/Inter-Italic-Variable.ttf" \
  acd98e64795781b2058f07b18475e0ecee2a0fe2b42a49e2f9e37d0d6bf66ce6
download_font \
  "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/$nerd_fonts_commit/patched-fonts/FiraCode/Retina/FiraCodeNerdFontMono-Retina.ttf" \
  "$font_dir/FiraCodeNerdFontMono-Retina.ttf" \
  ecc64595bb532ab1d256bc92b765c12b602c1f2892eebd777ff063a32a2d7c07
download_font \
  "https://raw.githubusercontent.com/google/fonts/$google_fonts_commit/ofl/newsreader/OFL.txt" \
  "$font_dir/Newsreader-OFL.txt" \
  fdfad38143ec470553cae82a1e45320bdd1b9ec70415d37bd0171051d8a4ded8
download_font \
  "https://raw.githubusercontent.com/google/fonts/$google_fonts_commit/ofl/inter/OFL.txt" \
  "$font_dir/Inter-OFL.txt" \
  5b9321a4298cfeb6b34354164a1c3afc3db114569984c502b9b35d988fd58c57
download_font \
  "https://raw.githubusercontent.com/ryanoasis/nerd-fonts/$nerd_fonts_commit/patched-fonts/FiraCode/Retina/LICENSE" \
  "$font_dir/FiraCode-LICENSE.txt" \
  1d41e10031ab125302780a05ec4c91d218e47db0c7e37cf315cce5e608cdc25c

run cp "$DOTFILES_ROOT/assets/obsidian/portable-fonts.css" \
  "$snippet_dir/portable-fonts.css"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "\$ enable portable-fonts and select vault fonts in $(printf '%q' "$appearance")"
elif [[ -f "$appearance" ]]; then
  require_command jq
  appearance_temp="$(mktemp "$appearance.XXXXXX")"
  jq '
    .enabledCssSnippets = (
      (.enabledCssSnippets // [])
      | if index("portable-fonts") then . else . + ["portable-fonts"] end
    )
    | .interfaceFontFamily = "Inter Vault"
    | .textFontFamily = "Newsreader Vault"
    | .monospaceFontFamily = "FiraCode Nerd Font Mono Vault"
  ' "$appearance" >"$appearance_temp"
  mv "$appearance_temp" "$appearance"
else
  warn "appearance.json not found; enable portable-fonts manually in Obsidian"
fi

log "Portable Obsidian fonts installed in $font_dir"
