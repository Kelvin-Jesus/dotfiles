#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/Kelvin-Jesus/dotfiles.git}"
DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DRY_RUN=0
ASSUME_YES=0
FORWARD_ARGS=()

log() {
  printf '[bootstrap] %s\n' "$*"
}

die() {
  printf '[bootstrap] error: %s\n' "$*" >&2
  exit 1
}

quote_command() {
  local arg output
  output=""
  for arg in "$@"; do
    printf -v arg '%q' "$arg"
    output="${output}${output:+ }${arg}"
  done
  printf '%s' "$output"
}

run() {
  log "\$ $(quote_command "$@")"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$@"
  fi
}

usage() {
  cat <<'EOF'
Usage: bootstrap.sh [options passed to install.sh]

Bootstrap options:
  --dry-run       Print actions without changing the machine
  --yes           Use non-interactive package-manager flags where possible
  --repo URL      Override the Git repository
  --dir PATH      Override the clone destination
  -h, --help      Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      FORWARD_ARGS+=("$1")
      ;;
    --yes)
      ASSUME_YES=1
      FORWARD_ARGS+=("$1")
      ;;
    --repo)
      [[ $# -ge 2 ]] || die "--repo requires a value"
      DOTFILES_REPO="$2"
      shift
      ;;
    --dir)
      [[ $# -ge 2 ]] || die "--dir requires a value"
      DOTFILES_DIR="$2"
      shift
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      FORWARD_ARGS+=("$1")
      ;;
  esac
  shift
done

install_homebrew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi

  log "Homebrew is not installed."
  if [[ "$DRY_RUN" -eq 1 ]]; then
    # shellcheck disable=SC2016
    log '$ /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    return
  fi

  if [[ "$ASSUME_YES" -eq 1 ]]; then
    NONINTERACTIVE=1 /bin/bash -c \
      "$(/usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    /bin/bash -c \
      "$(/usr/bin/curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
}

load_homebrew() {
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/usr/local/bin/brew shellenv)"
  elif [[ "$DRY_RUN" -eq 0 ]]; then
    die "Homebrew was not found after installation"
  fi
}

bootstrap_macos() {
  if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log '$ xcode-select --install'
      return
    fi

    /usr/bin/xcode-select --install 2>/dev/null || true
    cat <<'EOF'
The Apple Command Line Tools installer was opened.
Complete the graphical installation and run bootstrap.sh again.
EOF
    exit 0
  fi

  install_homebrew
  load_homebrew
  run brew install git stow
}

install_yay() {
  if command -v yay >/dev/null 2>&1; then
    return
  fi

  if [[ "$EUID" -eq 0 ]]; then
    die "yay must be built as a regular user, not root"
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log '$ git clone https://aur.archlinux.org/yay.git <temporary-directory>/yay'
    log '$ makepkg -si --needed'
    return
  fi

  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN
  git clone https://aur.archlinux.org/yay.git "$temp_dir/yay"
  (
    cd "$temp_dir/yay"
    if [[ "$ASSUME_YES" -eq 1 ]]; then
      makepkg -si --needed --noconfirm
    else
      makepkg -si --needed
    fi
  )
  rm -rf "$temp_dir"
  trap - RETURN
}

bootstrap_arch() {
  local pacman_args
  pacman_args=(-Syu --needed base-devel git curl stow)
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    pacman_args+=(--noconfirm)
  fi

  run sudo pacman "${pacman_args[@]}"
  install_yay
}

clone_or_update() {
  if [[ -d "$DOTFILES_DIR/.git" ]]; then
    if [[ "$DRY_RUN" -eq 0 ]] \
      && [[ -n "$(git -C "$DOTFILES_DIR" status --porcelain)" ]]; then
      die "$DOTFILES_DIR has local changes; update it manually before bootstrap"
    fi
    run git -C "$DOTFILES_DIR" pull --ff-only
    return
  fi

  if [[ -e "$DOTFILES_DIR" ]]; then
    die "$DOTFILES_DIR exists but is not a Git repository"
  fi
  run git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
}

case "$(uname -s)" in
  Darwin)
    bootstrap_macos
    ;;
  Linux)
    [[ -r /etc/os-release ]] || die "cannot identify this Linux distribution"
    # shellcheck disable=SC1091
    . /etc/os-release
    [[ "${ID:-}" == "arch" ]] || die "only Arch Linux is supported"
    bootstrap_arch
    ;;
  *)
    die "unsupported operating system: $(uname -s)"
    ;;
esac

clone_or_update

if [[ "$DRY_RUN" -eq 1 ]] && [[ ! -x "$DOTFILES_DIR/install.sh" ]]; then
  log "\$ $DOTFILES_DIR/install.sh $(quote_command "${FORWARD_ARGS[@]}")"
  exit 0
fi

exec "$DOTFILES_DIR/install.sh" "${FORWARD_ARGS[@]}"
