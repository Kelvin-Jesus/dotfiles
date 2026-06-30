#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_arch

run_sudo systemctl enable --now docker.service

if ! id -nG "$USER" | tr ' ' '\n' | grep -Fqx docker; then
  run_sudo usermod -aG docker "$USER"
  warn "Log out and back in before using Docker without sudo"
fi
