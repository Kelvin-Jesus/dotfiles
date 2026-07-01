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
    die "mailghost does not publish a release for architecture: $(uname -m)"
    ;;
esac

asset="mailghost-v$version-$release_os-$release_arch.tar.gz"
case "$release_os-$release_arch" in
  macos-aarch64)
    expected="799e435162bca22206250be9792372dae52239b35c8617503b80061c9a704cc1"
    ;;
  macos-x86_64)
    expected="a5ef95def0124c4cb7cce26a36c3794e4ab3c26ad05bad31d574e259b6a44796"
    ;;
  linux-aarch64)
    expected="17483298aadeac85392e75b6e839fd2abae1dd17d76731d3db9ff2fdbc8cba9a"
    ;;
  linux-x86_64)
    expected="f0287d8e372b80f4f86a87de19bc015098131241f8b81bb2e9c579d53d867253"
    ;;
esac

install_dir="$HOME/.local/bin"
ensure_dir "$install_dir"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "\$ download and verify $asset"
  log "\$ install mailghost to $install_dir/mailghost"
  log "\$ remove legacy $install_dir/mailsy binary"
  exit 0
fi

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
archive="$temp_dir/$asset"
url="https://github.com/Kelvin-Jesus/mailghost/releases/download/v$version/$asset"

run curl -fsSL "$url" -o "$archive"
if command -v sha256sum >/dev/null 2>&1; then
  actual="$(sha256sum "$archive" | awk '{ print $1 }')"
else
  actual="$(/usr/bin/shasum -a 256 "$archive" | awk '{ print $1 }')"
fi
[[ "$actual" == "$expected" ]] || die "checksum mismatch for $asset"

run tar -xzf "$archive" -C "$temp_dir" mailghost
run install -m 0755 "$temp_dir/mailghost" "$install_dir/mailghost"
run rm -f "$install_dir/mailsy"
log "Installed mailghost v$version"
