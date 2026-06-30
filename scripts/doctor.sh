#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

SOFT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --soft)
      SOFT=1
      ;;
    -h | --help)
      printf 'Usage: doctor.sh [--soft]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

failures=0
warnings=0

ok() {
  printf 'ok    %s\n' "$*"
}

missing() {
  printf 'FAIL  %s\n' "$*" >&2
  failures=$((failures + 1))
}

notice() {
  printf 'warn  %s\n' "$*"
  warnings=$((warnings + 1))
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "command: $1"
  else
    missing "command not found: $1"
  fi
}

commands=(
  zsh
  starship
  fzf
  zoxide
  eza
  bat
  rg
  fd
  gping
  hyperfine
  btop
  tmux
  task
  jq
  fastfetch
  docker
  git
  mise
  nvim
  stow
  lazygit
  tree-sitter
)

for command_name in "${commands[@]}"; do
  check_command "$command_name"
done

for config_path in \
  "$HOME/.zshrc" \
  "$HOME/.config/starship.toml" \
  "$HOME/.config/nvim/init.lua" \
  "$HOME/.config/tmux/tmux.conf" \
  "$HOME/.config/zed/settings.json"; do
  if [[ -e "$config_path" || -L "$config_path" ]]; then
    ok "config: $config_path"
  else
    missing "config missing: $config_path"
  fi
done

platform="$(detect_platform)"
if [[ "$platform" == "macos" ]]; then
  apps=(
    "Anki.app"
    "FeedFlow.app"
    "KeePassXC.app"
    "LocalSend.app"
    "Obsidian.app"
    "Open Design.app"
    "OrbStack.app"
    "PureMac.app"
    "RustDesk.app"
    "Stremio.app"
    "Syncthing.app"
    "Upscayl.app"
    "VLC.app"
    "Zed.app"
    "Zen.app"
  )

  for app in "${apps[@]}"; do
    if [[ -d "/Applications/$app" ]]; then
      ok "application: $app"
    else
      notice "application missing: $app"
    fi
  done

  fonts=(
    "FiraCodeNerdFontMono-Retina.ttf"
    "JetBrainsMono*Nerd*Font*"
    "Iosevka*Nerd*Font*"
    "Inter*"
    "Literata*"
  )
  for font_pattern in "${fonts[@]}"; do
    if find "$HOME/Library/Fonts" /Library/Fonts -maxdepth 1 -iname "$font_pattern" \
      -print -quit 2>/dev/null | grep -q .; then
      ok "font: $font_pattern"
    else
      notice "font not found: $font_pattern"
    fi
  done

  if command -v brew >/dev/null 2>&1 \
    && brew bundle check --file="$DOTFILES_ROOT/packages/macos/Brewfile" >/dev/null 2>&1; then
    ok "Homebrew bundle is satisfied"
  else
    notice "Homebrew bundle has missing or changed entries"
  fi
else
  if systemctl is-enabled keyd.service >/dev/null 2>&1; then
    ok "keyd service enabled"
  else
    notice "keyd service is not enabled"
  fi
  if systemctl is-enabled docker.service >/dev/null 2>&1; then
    ok "Docker service enabled"
  else
    notice "Docker service is not enabled"
  fi
fi

printf '\nDoctor: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
if [[ "$failures" -gt 0 && "$SOFT" -eq 0 ]]; then
  exit 1
fi
