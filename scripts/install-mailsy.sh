#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

version="1.0.0"
platform="$(detect_platform)"
case "$platform" in
  macos)
    release_os="macos"
    ;;
  arch)
    release_os="linux"
    ;;
esac

case "$(uname -m)" in
  arm64 | aarch64)
    release_arch="aarch64"
    ;;
  x86_64)
    release_arch="x86_64"
    ;;
  *)
    die "mailsy does not publish a release for architecture: $(uname -m)"
    ;;
esac

asset="mailsy-v$version-$release_os-$release_arch.tar.gz"
case "$release_os-$release_arch" in
  macos-aarch64)
    expected="739aee4be16ed639217785d31dd269584c51466ce69cf5b4e15845fffea11b58"
    ;;
  macos-x86_64)
    expected="94612968704c5f9d39645294d43f34300f74e2d22d840b195d07ae731769f955"
    ;;
  linux-aarch64)
    expected="455a3684fff74367f96d3676e9456d9da7ef01240a174df56e9f8edc24a139c9"
    ;;
  linux-x86_64)
    expected="71e21ea6b8f95b80dd9fabf899b8e4558896386b38bb0e34953c0d6dfbb560d0"
    ;;
esac

install_dir="$HOME/.local/bin"
ensure_dir "$install_dir"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "\$ download and verify $asset"
  log "\$ install mailsy to $install_dir/mailsy"
  exit 0
fi

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
archive="$temp_dir/$asset"
url="https://github.com/Kelvin-Jesus/mailsy-rs/releases/download/v$version/$asset"

run curl -fsSL "$url" -o "$archive"
if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "$archive" | awk '{ print $1 }')"
else
  actual="$(/usr/bin/shasum -a 256 "$archive" | awk '{ print $1 }')"
fi
[[ "$actual" == "$expected" ]] || die "checksum mismatch for $asset"

run tar -xzf "$archive" -C "$temp_dir" mailsy
run install -m 0755 "$temp_dir/mailsy" "$install_dir/mailsy"
log "Installed mailsy v$version"
