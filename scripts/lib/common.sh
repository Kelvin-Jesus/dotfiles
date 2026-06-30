#!/usr/bin/env bash

if [[ -n "${DOTFILES_COMMON_SOURCED:-}" ]]; then
  return 0
fi
DOTFILES_COMMON_SOURCED=1

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
DRY_RUN="${DOTFILES_DRY_RUN:-0}"
ASSUME_YES="${DOTFILES_ASSUME_YES:-0}"
STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"
DOTFILES_STATE_DIR="${DOTFILES_STATE_DIR:-$STATE_HOME/dotfiles}"
DOTFILES_LOG_FILE="${DOTFILES_LOG_FILE:-}"

timestamp() {
  date '+%Y%m%d-%H%M%S'
}

log() {
  local message
  message="$*"
  printf '[dotfiles] %s\n' "$message"
  if [[ -n "$DOTFILES_LOG_FILE" ]]; then
    printf '[%s] %s\n' "$(date '+%Y-%m-%dT%H:%M:%S%z')" "$message" >>"$DOTFILES_LOG_FILE"
  fi
}

warn() {
  log "warning: $*"
}

die() {
  printf '[dotfiles] error: %s\n' "$*" >&2
  exit 1
}

init_log() {
  local name
  name="${1:-run}"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    mkdir -p "$DOTFILES_STATE_DIR/logs"
    DOTFILES_LOG_FILE="${DOTFILES_LOG_FILE:-$DOTFILES_STATE_DIR/logs/${name}-$(timestamp).log}"
    export DOTFILES_LOG_FILE
  fi
}

quote_command() {
  local arg output quoted
  output=""
  for arg in "$@"; do
    printf -v quoted '%q' "$arg"
    output="${output}${output:+ }${quoted}"
  done
  printf '%s' "$output"
}

run() {
  log "\$ $(quote_command "$@")"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$@"
  fi
}

run_allow_failure() {
  log "\$ $(quote_command "$@")"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$@" || true
  fi
}

run_sudo() {
  run sudo "$@"
}

run_script() {
  local script
  script="$1"
  shift
  [[ -x "$script" ]] || die "script is not executable: $script"
  log "Running ${script#"$DOTFILES_ROOT"/}"
  "$script" "$@"
}

capture_to() {
  local destination
  destination="$1"
  shift
  log "\$ $(quote_command "$@") > $(printf '%q' "$destination")"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$@" >"$destination"
  fi
}

capture_to_allow_failure() {
  local destination
  destination="$1"
  shift
  log "\$ $(quote_command "$@") > $(printf '%q' "$destination")"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    "$@" >"$destination" 2>&1 || true
  fi
}

ensure_dir() {
  run mkdir -p "$1"
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

append_line_sudo() {
  local line file
  line="$1"
  file="$2"
  if [[ -r "$file" ]] && grep -Fqx "$line" "$file"; then
    return
  fi
  log "\$ printf '%s\\n' $(printf '%q' "$line") | sudo tee -a $(printf '%q' "$file")"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    printf '%s\n' "$line" | sudo tee -a "$file" >/dev/null
  fi
}

confirm() {
  local prompt reply
  prompt="$1"
  if [[ "$ASSUME_YES" -eq 1 ]]; then
    return 0
  fi
  printf '%s [y/N] ' "$prompt" >&2
  read -r reply
  [[ "$reply" == [yY] || "$reply" == [yY][eE][sS] ]]
}

detect_platform() {
  case "$(uname -s)" in
    Darwin)
      printf 'macos\n'
      ;;
    Linux)
      [[ -r /etc/os-release ]] || die "cannot identify this Linux distribution"
      # shellcheck disable=SC1091
      . /etc/os-release
      [[ "${ID:-}" == "arch" ]] || die "only Arch Linux is supported"
      printf 'arch\n'
      ;;
    *)
      die "unsupported operating system: $(uname -s)"
      ;;
  esac
}

require_macos() {
  [[ "$(uname -s)" == "Darwin" ]] || die "this script only supports macOS"
}

require_arch() {
  [[ "$(detect_platform)" == "arch" ]] || die "this script only supports Arch Linux"
}

macos_major_version() {
  /usr/bin/sw_vers -productVersion | cut -d. -f1
}
