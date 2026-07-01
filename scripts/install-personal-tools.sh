#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

project="$DOTFILES_ROOT/tools/personal-scripts"
destination="$HOME/.local/bin"
binaries=(
  check_true_flac
  compress-video
  is-avif
  pformat
)

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "Would compile Rust personal tools with an ephemeral Cargo cache"
  for binary in "${binaries[@]}"; do
    log "Would install $binary in $destination"
  done
  exit 0
fi

if command -v cargo >/dev/null 2>&1; then
  cargo_command=(cargo)
elif command -v mise >/dev/null 2>&1; then
  cargo_command=(mise exec -- cargo)
else
  die "cargo is unavailable; run scripts/install-runtimes.sh first"
fi
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-rust-tools.XXXXXX")"
trap 'rm -rf "$temporary_root"' EXIT

export CARGO_HOME="$temporary_root/cargo-home"
export CARGO_TARGET_DIR="$temporary_root/target"

run "${cargo_command[@]}" build \
  --manifest-path "$project/Cargo.toml" \
  --release \
  --locked \
  --bins
run mkdir -p "$destination"
for binary in "${binaries[@]}"; do
  run install -m 0755 "$CARGO_TARGET_DIR/release/$binary" "$destination/$binary"
done

log "Installed personal Rust tools; temporary Cargo dependencies were removed"
