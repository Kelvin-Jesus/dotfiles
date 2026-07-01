#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

RESTORE_SETTINGS=0
BACKUP_DIR=""

usage() {
  cat <<'EOF'
Usage: uninstall.sh [options]

  --dry-run             Print changes without applying them
  --restore-settings    Restore the latest macOS preference backup
  --backup DIR          Restore a specific macOS backup directory
  -h, --help            Show this help

This removes managed Stow links and keyboard integration. It does not uninstall
packages, delete application data, remove the repository, or change the shell.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --restore-settings)
      RESTORE_SETTINGS=1
      ;;
    --backup)
      [[ $# -ge 2 ]] || die "--backup requires a directory"
      RESTORE_SETTINGS=1
      BACKUP_DIR="$2"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

export DOTFILES_DRY_RUN="$DRY_RUN"
init_log "uninstall"

platform="$(detect_platform)"
target_home="${STOW_TARGET:-$HOME}"
common_packages=(btop git mise nvim starship tmux zed zsh)
platform_packages=()

case "$platform" in
  macos)
    platform_packages=(ghostty macos)
    if [[ "$RESTORE_SETTINGS" -eq 1 ]]; then
      backup_dir="${BACKUP_DIR:-$DOTFILES_STATE_DIR/backups/macos/latest}"
      restore_args=()
      if [[ "$DRY_RUN" -eq 1 ]]; then
        restore_args+=(--dry-run)
      fi
      restore_args+=("$backup_dir")
      run_script "$DOTFILES_ROOT/scripts/macos/restore-settings.sh" \
        "${restore_args[@]}"
    fi

    if [[ "${DOTFILES_UNINSTALL_LINKS_ONLY:-0}" -eq 0 ]]; then
      plist="$HOME/Library/LaunchAgents/com.dotfiles.caps-to-escape.plist"
      run_allow_failure /bin/launchctl bootout "gui/$UID" "$plist"
      run_allow_failure /usr/bin/hidutil property --set '{"UserKeyMapping":[]}'
    fi
    ;;
  arch)
    if [[ "${DOTFILES_UNINSTALL_LINKS_ONLY:-0}" -eq 0 ]] \
      && cmp -s "$DOTFILES_ROOT/config/arch/keyd/default.conf" /etc/keyd/default.conf; then
      run_sudo systemctl disable --now keyd.service
      run_sudo rm /etc/keyd/default.conf
    fi
    ;;
esac

unstow_packages() {
  local stow_dir package
  stow_dir="$1"
  shift
  for package in "$@"; do
    run stow \
      --dir="$stow_dir" \
      --target="$target_home" \
      --delete \
      --no-folding \
      "$package"
  done
}

unstow_packages "$DOTFILES_ROOT/stow/common" "${common_packages[@]}"
if ((${#platform_packages[@]})); then
  unstow_packages "$DOTFILES_ROOT/stow/$platform" "${platform_packages[@]}"
fi

log "Dotfile links removed; packages, data, repository and login shell preserved"
