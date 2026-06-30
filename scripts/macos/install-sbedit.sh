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
      printf 'Usage: install-sbedit.sh [--dry-run]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

if command -v sbedit >/dev/null 2>&1; then
  exit 0
fi

version="1.0"
url="https://github.com/fabienconus/sidebar-editor/releases/download/1.0/sbedit-1.0.pkg"
sha256="d5bd5c0de1be212f932313e79d2356b953fe6a364221b8bbdee0cbb1b5303e34"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log "\$ curl -fL $url -o <temporary-file>"
  log "\$ verify SHA-256 $sha256"
  log "\$ sudo installer -pkg sbedit-$version.pkg -target /"
  exit 0
fi

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT
package="$temp_dir/sbedit-$version.pkg"

run /usr/bin/curl -fL "$url" -o "$package"
actual_sha="$(/usr/bin/shasum -a 256 "$package" | awk '{print $1}')"
[[ "$actual_sha" == "$sha256" ]] || die "sbedit SHA-256 mismatch"
run_allow_failure /usr/sbin/pkgutil --check-signature "$package"
run_sudo /usr/sbin/installer -pkg "$package" -target /

command -v sbedit >/dev/null 2>&1 || die "sbedit was installed but is not on PATH"
