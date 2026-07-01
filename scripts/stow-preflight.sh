#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
# shellcheck source=lib/stow-packages.sh
source "$DOTFILES_ROOT/scripts/lib/stow-packages.sh"

BACKUP_CONFLICTS=0

usage() {
  cat <<'EOF'
Usage: stow-preflight.sh [--dry-run] [--backup-conflicts]

Checks every Stow target before applying links. By default this is read-only
and exits non-zero when conflicts exist. --backup-conflicts moves conflicting
targets into the dotfiles state backup before Stow runs.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
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

TARGET_HOME="${STOW_TARGET:-$HOME}"
platform="$(detect_platform)"
backup_dir="$DOTFILES_STATE_DIR/backups/stow/$(timestamp)"
conflicts=0
backed_up=0

is_replaceable_dotfiles_link() {
  local target link
  target="$1"
  [[ -L "$target" ]] || return 1
  link="$(readlink "$target")"
  case "$link" in
    *dotfiles/*)
      return 0
      ;;
  esac
  return 1
}

handle_conflict() {
  local target relative destination
  target="$1"
  relative="${target#"$TARGET_HOME"/}"
  conflicts=$((conflicts + 1))

  if [[ "$BACKUP_CONFLICTS" -eq 0 ]]; then
    printf 'conflict: %s\n' "$target" >&2
    return
  fi

  destination="$backup_dir/$relative"
  log "Backup conflict: $target -> $destination"
  if [[ "$DRY_RUN" -eq 0 ]]; then
    mkdir -p "$(dirname "$destination")"
    mv "$target" "$destination"
  fi
  backed_up=$((backed_up + 1))
}

while IFS=$'\t' read -r stow_dir package; do
  package_root="$stow_dir/$package"
  [[ -d "$package_root" ]] || die "Stow package not found: $package_root"
  while IFS= read -r -d '' source; do
    relative="${source#"$package_root"/}"
    target="$TARGET_HOME/$relative"
    if [[ -L "$target" && "$target" -ef "$source" ]]; then
      continue
    fi
    if [[ ! -e "$target" && ! -L "$target" ]]; then
      continue
    fi
    if is_replaceable_dotfiles_link "$target"; then
      continue
    fi
    handle_conflict "$target"
  done < <(
    find "$package_root" \( -type f -o -type l \) \
      ! -name '.gitignore' \
      ! -name '.stow-local-ignore' \
      -print0
  )
done < <(stow_package_roots "$platform")

if [[ "$conflicts" -eq 0 ]]; then
  printf 'Stow preflight: no conflicts\n'
  exit 0
fi

if [[ "$BACKUP_CONFLICTS" -eq 0 ]]; then
  printf 'Stow preflight: %d conflict(s); no files changed\n' "$conflicts" >&2
  exit 1
fi

if [[ "$DRY_RUN" -eq 1 ]]; then
  printf 'Stow preflight: would back up %d conflict(s) into %s\n' \
    "$backed_up" "$backup_dir"
else
  ln -sfn "$backup_dir" "$DOTFILES_STATE_DIR/backups/stow/latest"
  printf 'Stow preflight: backed up %d conflict(s) into %s\n' \
    "$backed_up" "$backup_dir"
fi
