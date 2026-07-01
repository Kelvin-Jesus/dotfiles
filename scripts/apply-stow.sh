#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
# shellcheck source=lib/stow-packages.sh
source "$DOTFILES_ROOT/scripts/lib/stow-packages.sh"

TARGET_HOME="${STOW_TARGET:-$HOME}"
platform="$(detect_platform)"
BACKUP_CONFLICTS=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --backup-conflicts)
      BACKUP_CONFLICTS=1
      ;;
    -h | --help)
      printf 'Usage: apply-stow.sh [--backup-conflicts]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

legacy_paths=(
  "$TARGET_HOME/.config/btop"
  "$TARGET_HOME/.config/ghostty"
  "$TARGET_HOME/.config/mise"
  "$TARGET_HOME/.config/nvim"
  "$TARGET_HOME/.config/starship.toml"
  "$TARGET_HOME/.config/tmux"
  "$TARGET_HOME/.config/zed"
  "$TARGET_HOME/.config/zellij"
  "$TARGET_HOME/.gitconfig"
  "$TARGET_HOME/.zprofile"
  "$TARGET_HOME/.zshrc"
)

cleanup_legacy_link() {
  local path target
  path="$1"
  [[ -L "$path" ]] || return 0
  target="$(readlink "$path")"
  case "$target" in
    *dotfiles/btop/* | *dotfiles/ghostty/* | *dotfiles/git/* | \
      *dotfiles/mise/* | *dotfiles/nvim/* | *dotfiles/starship/* | *dotfiles/tmux/* | \
      *dotfiles/zed/* | *dotfiles/zellij/* | *dotfiles/zsh/*)
      run rm "$path"
      ;;
  esac
  return 0
}

preserve_legacy_mutable_data() {
  local legacy_zed
  legacy_zed="$DOTFILES_ROOT/zed/.config/zed"
  if [[ -L "$TARGET_HOME/.config/zed" && -d "$legacy_zed" ]]; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "Preserve mutable Zed data outside the legacy package"
    else
      rm "$TARGET_HOME/.config/zed"
      mkdir -p "$TARGET_HOME/.config/zed"
      for path in conversations embeddings prompts; do
        if [[ -d "$legacy_zed/$path" ]]; then
          cp -R "$legacy_zed/$path" "$TARGET_HOME/.config/zed/$path"
        fi
      done
    fi
  fi
}

cleanup_legacy_layout() {
  local path
  preserve_legacy_mutable_data
  for path in "${legacy_paths[@]}"; do
    cleanup_legacy_link "$path"
  done

  if [[ -d "$TARGET_HOME/.config/zsh" ]]; then
    for path in "$TARGET_HOME/.config/zsh/"*.zsh; do
      [[ -e "$path" || -L "$path" ]] || continue
      cleanup_legacy_link "$path"
    done
  fi
}

cleanup_broken_managed_links() {
  local path target
  [[ -d "$TARGET_HOME/.config" ]] || return 0

  while IFS= read -r -d '' path; do
    [[ -e "$path" ]] && continue
    target="$(readlink "$path")"
    case "$target" in
      *dotfiles/stow/*)
        run rm "$path"
        ;;
    esac
  done < <(find "$TARGET_HOME/.config" -type l -print0)
}

stow_packages() {
  local stow_dir package
  stow_dir="$1"
  shift
  for package in "$@"; do
    [[ -d "$stow_dir/$package" ]] || die "Stow package not found: $stow_dir/$package"
    run stow \
      --dir="$stow_dir" \
      --target="$TARGET_HOME" \
      --restow \
      --no-folding \
      "$package"
  done
}

ensure_dir "$TARGET_HOME"
cleanup_legacy_layout
cleanup_broken_managed_links
preflight_args=()
if [[ "$BACKUP_CONFLICTS" -eq 1 ]]; then
  preflight_args+=(--backup-conflicts)
fi
if ((${#preflight_args[@]})); then
  run_script "$DOTFILES_ROOT/scripts/stow-preflight.sh" "${preflight_args[@]}"
else
  run_script "$DOTFILES_ROOT/scripts/stow-preflight.sh"
fi

stow_packages "$DOTFILES_ROOT/stow/common" "${common_stow_packages[@]}"

if [[ "$platform" == "macos" ]]; then
  stow_packages "$DOTFILES_ROOT/stow/macos" "${macos_stow_packages[@]}"
fi

log "Stow packages applied to $TARGET_HOME"
