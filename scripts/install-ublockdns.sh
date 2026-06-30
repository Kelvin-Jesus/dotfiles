#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

if [[ "$DRY_RUN" -eq 1 ]]; then
  log '$ download and verify the uBlockDNS installer'
  log '$ install uBlockDNS using UBLOCKDNS_PROFILE_ID=<redacted>'
  exit 0
fi

profile_id="${UBLOCKDNS_PROFILE_ID:-}"
[[ -n "$profile_id" ]] \
  || die "UBLOCKDNS_PROFILE_ID is required with --with-ublockdns"

temp_dir="$(mktemp -d)"
trap 'rm -rf "$temp_dir"' EXIT

installer="$temp_dir/install.sh"
checksums="$temp_dir/SCRIPT_SHA256SUMS"

run /usr/bin/curl -fsSL https://ublockdns.com/install.sh -o "$installer"
run /usr/bin/curl -fsSL \
  https://github.com/ugzv/ublockdnsclient/releases/latest/download/SCRIPT_SHA256SUMS \
  -o "$checksums"

expected="$(awk '$2 == "install.sh" { print $1; exit }' "$checksums")"
actual="$(/usr/bin/shasum -a 256 "$installer" | awk '{ print $1 }')"
[[ -n "$expected" && "$actual" == "$expected" ]] \
  || die "uBlockDNS installer checksum verification failed"

log "Installing uBlockDNS with a redacted profile ID"
/bin/sh "$installer" "$profile_id"
unset profile_id
