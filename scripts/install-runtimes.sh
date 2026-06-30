#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

if [[ "$DRY_RUN" -eq 0 ]]; then
  require_command mise
fi

mise_config="$HOME/.config/mise/config.toml"
run mise trust "$mise_config"
run mise install
run mise reshim
