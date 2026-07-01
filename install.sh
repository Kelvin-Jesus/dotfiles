#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
export PATH="$HOME/.local/bin:$PATH"

SKIP_PACKAGES=0
SKIP_STOW=0
SKIP_RUNTIMES=0
SKIP_EDITORS=0
SKIP_SETTINGS=0
WITH_OPTIONAL_APPS=0
BACKUP_CONFLICTS=0
PREFLIGHT_ONLY=0

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Options:
  --dry-run                 Print every action without changing the machine
  --yes                     Reduce package-manager confirmation prompts
  --skip-packages           Do not install packages or applications
  --skip-stow               Do not apply dotfile symlinks
  --skip-runtimes           Do not run mise install
  --skip-editors            Do not restore LazyVim plugins
  --skip-system-settings    Do not apply macOS/Arch system settings
  --with-optional-apps      Install pinned SideScreen and SpotiFLAC releases
  --preflight               Check Stow conflicts and exit without changes
  --backup-conflicts        Back up conflicting Stow targets before install
  -h, --help                Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    --yes)
      ASSUME_YES=1
      ;;
    --skip-packages)
      SKIP_PACKAGES=1
      ;;
    --skip-stow)
      SKIP_STOW=1
      ;;
    --skip-runtimes)
      SKIP_RUNTIMES=1
      ;;
    --skip-editors)
      SKIP_EDITORS=1
      ;;
    --skip-system-settings)
      SKIP_SETTINGS=1
      ;;
    --with-optional-apps)
      WITH_OPTIONAL_APPS=1
      ;;
    --preflight)
      PREFLIGHT_ONLY=1
      ;;
    --backup-conflicts)
      BACKUP_CONFLICTS=1
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

export DOTFILES_ROOT
export DOTFILES_DRY_RUN="$DRY_RUN"
export DOTFILES_ASSUME_YES="$ASSUME_YES"

platform="$(detect_platform)"
init_log "install"
log "Installing dotfiles for $platform from $DOTFILES_ROOT"

if [[ "$PREFLIGHT_ONLY" -eq 1 ]]; then
  run_script "$DOTFILES_ROOT/scripts/stow-preflight.sh"
  exit 0
fi

ensure_dir "$HOME/Documents/obsidian-vault"
ensure_dir "$HOME/Documents/wallpapers"

if [[ "$SKIP_PACKAGES" -eq 0 ]]; then
  package_args=()
  if [[ "$WITH_OPTIONAL_APPS" -eq 1 ]]; then
    package_args+=(--with-optional-apps)
  fi
  if ((${#package_args[@]})); then
    run_script "$DOTFILES_ROOT/scripts/install-packages.sh" "${package_args[@]}"
  else
    run_script "$DOTFILES_ROOT/scripts/install-packages.sh"
  fi
fi

if [[ "$SKIP_STOW" -eq 0 ]]; then
  stow_args=()
  if [[ "$BACKUP_CONFLICTS" -eq 1 ]]; then
    stow_args+=(--backup-conflicts)
  fi
  if ((${#stow_args[@]})); then
    run_script "$DOTFILES_ROOT/scripts/apply-stow.sh" "${stow_args[@]}"
  else
    run_script "$DOTFILES_ROOT/scripts/apply-stow.sh"
  fi
fi

run_script "$DOTFILES_ROOT/scripts/install-shell.sh"

if [[ "$SKIP_RUNTIMES" -eq 0 ]]; then
  run_script "$DOTFILES_ROOT/scripts/install-runtimes.sh"
fi

run_script "$DOTFILES_ROOT/scripts/install-personal-tools.sh"

if [[ "$SKIP_EDITORS" -eq 0 ]]; then
  run_script "$DOTFILES_ROOT/scripts/install-editors.sh"
fi

run_script "$DOTFILES_ROOT/scripts/install-obsidian-fonts.sh"

if [[ "$SKIP_SETTINGS" -eq 0 ]]; then
  run_script "$DOTFILES_ROOT/scripts/apply-settings.sh"
fi

run_script "$DOTFILES_ROOT/scripts/doctor.sh" --soft
log "Installation finished. Open a new terminal and review the doctor output."
