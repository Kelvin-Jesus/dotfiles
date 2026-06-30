#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

while IFS= read -r script; do
  bash -n "$script"
done < <(find "$DOTFILES_ROOT" -type f -name '*.sh' -print)

if command -v shellcheck >/dev/null 2>&1; then
  find "$DOTFILES_ROOT" -type f -name '*.sh' -print0 \
    | xargs -0 shellcheck -x -P SCRIPTDIR
fi

if command -v shfmt >/dev/null 2>&1; then
  find "$DOTFILES_ROOT" -type f -name '*.sh' -print0 \
    | xargs -0 shfmt -d -i 2 -ci -bn
fi

zsh -n \
  "$DOTFILES_ROOT/stow/common/zsh/.zshrc" \
  "$DOTFILES_ROOT/stow/common/zsh/.zprofile" \
  "$DOTFILES_ROOT/stow/common/zsh/.config/zsh/"*.zsh

/usr/bin/plutil -lint \
  "$DOTFILES_ROOT/stow/macos/macos/Library/LaunchAgents/com.dotfiles.caps-to-escape.plist"

"$DOTFILES_ROOT/scripts/test-stow.sh"
"$DOTFILES_ROOT/install.sh" \
  --dry-run \
  --skip-packages \
  --skip-runtimes \
  --skip-editors
"$DOTFILES_ROOT/scripts/macos/remove-native-apps.sh"

if rg -n '/Users/kajota' "$DOTFILES_ROOT" \
  --glob '!.git/**' \
  --glob '!scripts/test.sh'; then
  printf 'Hard-coded home directory found\n' >&2
  exit 1
fi

if rg -n 'AstroNvim|astronvim' \
  "$DOTFILES_ROOT/stow/common/nvim/.config/nvim/lua"; then
  printf 'AstroNvim reference found in the active Neovim configuration\n' >&2
  exit 1
fi

if rg -n 'shader' "$DOTFILES_ROOT/stow/macos/ghostty"; then
  printf 'Ghostty shader reference found\n' >&2
  exit 1
fi

printf 'All static and sandbox tests passed\n'
