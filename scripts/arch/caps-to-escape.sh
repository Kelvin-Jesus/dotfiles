#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_arch

source_file="$DOTFILES_ROOT/config/arch/keyd/default.conf"
run_sudo install -Dm0644 "$source_file" /etc/keyd/default.conf
run_sudo systemctl enable --now keyd.service
run_sudo systemctl restart keyd.service

log "Caps Lock maps to Escape through keyd"
