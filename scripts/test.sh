#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
rust_test_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-rust-tests.XXXXXX")"
trap 'rm -rf "$rust_test_root"' EXIT
if command -v cargo >/dev/null 2>&1; then
  cargo_test_command=(cargo)
else
  cargo_test_command=(mise exec -- cargo)
fi

while IFS= read -r script; do
  bash -n "$script"
done < <(find "$DOTFILES_ROOT" -type f -name '*.sh' -print)

"$DOTFILES_ROOT/dotfiles" help >/dev/null
"$DOTFILES_ROOT/scripts/security-audit.sh" --tracked

security_test_root="$rust_test_root/security-audit"
mkdir -p "$security_test_root/scripts/lib"
cp "$DOTFILES_ROOT/scripts/security-audit.sh" "$security_test_root/scripts/"
cp "$DOTFILES_ROOT/scripts/lib/common.sh" "$security_test_root/scripts/lib/"
git -C "$security_test_root" init -q
printf 'service_token = "%s"\n' 'github_''pat_FAKEVALUE123456' \
  >"$security_test_root/config.txt"
git -C "$security_test_root" add .
if "$security_test_root/scripts/security-audit.sh" --staged \
  >"$security_test_root/output" 2>&1; then
  die "security audit did not detect the staged fake secret"
fi
grep -Fq 'token-like content' "$security_test_root/output" \
  || die "security audit did not classify the staged fake token"

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

CARGO_HOME="$rust_test_root/cargo-home" \
  CARGO_TARGET_DIR="$rust_test_root/target" \
  "${cargo_test_command[@]}" test \
  --manifest-path "$DOTFILES_ROOT/tools/personal-scripts/Cargo.toml" \
  --locked

/usr/bin/plutil -lint \
  "$DOTFILES_ROOT/stow/macos/macos/Library/LaunchAgents/com.dotfiles.caps-to-escape.plist"

if command -v jq >/dev/null 2>&1; then
  find "$DOTFILES_ROOT/assets/keyboards" -type f -name '*.vil' -print0 \
    | xargs -0 -n1 jq empty
fi

"$DOTFILES_ROOT/scripts/test-stow.sh"
/bin/bash "$DOTFILES_ROOT/install.sh" \
  --dry-run \
  --skip-packages \
  --skip-runtimes \
  --skip-editors
"$DOTFILES_ROOT/scripts/macos/remove-native-apps.sh"

if rg -n '/Users/kajota' "$DOTFILES_ROOT" \
  --glob '!.git/**' \
  --glob '!scripts/test.sh' \
  --glob '!**/scripts/test.sh'; then
  printf 'Hard-coded home directory found\n' >&2
  exit 1
fi

if rg -n 'AstroNvim|astronvim' \
  "$DOTFILES_ROOT/stow/common/nvim/.config/nvim/lua"; then
  printf 'AstroNvim reference found in the active Neovim configuration\n' >&2
  exit 1
fi

if rg -n -F '+Lazy! sync' "$DOTFILES_ROOT/scripts/install-editors.sh"; then
  printf 'Lazy sync mutates the versioned lockfile; use Lazy restore during bootstrap\n' >&2
  exit 1
fi

if rg -n 'shader' "$DOTFILES_ROOT/stow/macos/ghostty"; then
  printf 'Ghostty shader reference found\n' >&2
  exit 1
fi

printf 'All static and sandbox tests passed\n'
