#!/usr/bin/env bash

if [[ -n "${DOTFILES_STOW_PACKAGES_SOURCED:-}" ]]; then
  return 0
fi
DOTFILES_STOW_PACKAGES_SOURCED=1

common_stow_packages=(
  btop
  git
  mise
  nvim
  starship
  tmux
  zed
  zsh
)

macos_stow_packages=(
  ghostty
  macos
)

stow_package_roots() {
  local platform package
  platform="$1"
  for package in "${common_stow_packages[@]}"; do
    printf '%s\t%s\n' "$DOTFILES_ROOT/stow/common" "$package"
  done
  if [[ "$platform" == "macos" ]]; then
    for package in "${macos_stow_packages[@]}"; do
      printf '%s\t%s\n' "$DOTFILES_ROOT/stow/macos" "$package"
    done
  fi
}
