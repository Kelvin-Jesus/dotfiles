#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=../../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

dns_servers=(1.1.1.1 1.0.0.1)

if [[ "${1:-}" == "--automatic" ]]; then
  dns_servers=(Empty)
elif [[ $# -gt 0 ]]; then
  die "Usage: network.sh [--automatic]"
fi

network_services="$(/usr/sbin/networksetup -listallnetworkservices | tail -n +2)"
while IFS= read -r service; do
  [[ -n "$service" ]] || continue
  [[ "$service" == \** ]] && continue
  run_sudo /usr/sbin/networksetup -setdnsservers "$service" "${dns_servers[@]}"
done <<<"$network_services"
