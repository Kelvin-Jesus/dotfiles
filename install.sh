#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=scripts/lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

SKIP_PACKAGES=0
SKIP_STOW=0
SKIP_RUNTIMES=0
SKIP_EDITORS=0
SKIP_SETTINGS=0
WITH_OPTIONAL_APPS=0

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

if [[ "$SKIP_PACKAGES" -eq 0 ]]; then
  case "$platform" in
    macos)
      if [[ "$DRY_RUN" -eq 0 ]]; then
        require_command brew
      fi
      run brew tap go-task/tap
      if [[ "$DRY_RUN" -eq 1 ]] || brew help trust >/dev/null 2>&1; then
        run brew trust --formula go-task/tap/go-task
      fi
      run brew bundle install --file="$DOTFILES_ROOT/packages/macos/Brewfile"
      run_script "$DOTFILES_ROOT/scripts/macos/install-release-apps.sh" open-design
      if [[ "$WITH_OPTIONAL_APPS" -eq 1 ]]; then
        run_script "$DOTFILES_ROOT/scripts/macos/install-release-apps.sh" sidescreen spotiflac
      fi
      ;;
    arch)
      run_script "$DOTFILES_ROOT/scripts/arch/install-packages.sh"
      ;;
  esac
fi

if [[ "$SKIP_STOW" -eq 0 ]]; then
  run_script "$DOTFILES_ROOT/scripts/apply-stow.sh"
fi

run_script "$DOTFILES_ROOT/scripts/install-shell.sh"

if [[ "$SKIP_RUNTIMES" -eq 0 ]]; then
  run_script "$DOTFILES_ROOT/scripts/install-runtimes.sh"
fi

if [[ "$SKIP_EDITORS" -eq 0 ]]; then
  run_script "$DOTFILES_ROOT/scripts/install-editors.sh"
fi

if [[ "$SKIP_SETTINGS" -eq 0 ]]; then
  case "$platform" in
    macos)
      run_script "$DOTFILES_ROOT/scripts/macos/apply.sh"
      ;;
    arch)
      run_script "$DOTFILES_ROOT/scripts/arch/caps-to-escape.sh"
      run_script "$DOTFILES_ROOT/scripts/arch/services.sh"
      ;;
  esac
  run_script "$DOTFILES_ROOT/scripts/set-wallpaper.sh"
fi

run_script "$DOTFILES_ROOT/scripts/doctor.sh" --soft
log "Installation finished. Open a new terminal and review the doctor output."
