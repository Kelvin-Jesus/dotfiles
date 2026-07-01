#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
# shellcheck source=lib/stow-packages.sh
source "$DOTFILES_ROOT/scripts/lib/stow-packages.sh"

RUN_DOCTOR=1

usage() {
  cat <<'EOF'
Usage: audit.sh [--no-doctor]

Read-only comparison of the current machine against the dotfiles repository.
No configuration is copied into the repository.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-doctor)
      RUN_DOCTOR=0
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

temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-audit.XXXXXX")"
trap 'rm -rf "$temporary_root"' EXIT
platform="$(detect_platform)"
differences=0

heading() {
  printf '\n== %s ==\n' "$1"
}

notice_difference() {
  printf '%s\n' "$*"
  differences=$((differences + 1))
}

audit_git() {
  heading "Repository"
  if [[ -n "$(git -C "$DOTFILES_ROOT" status --porcelain)" ]]; then
    notice_difference "Repository has local changes:"
    git -C "$DOTFILES_ROOT" status --short
  else
    printf 'Repository is clean\n'
  fi
  "$DOTFILES_ROOT/scripts/security-audit.sh" --tracked
}

audit_stow() {
  local stow_dir package package_root source relative target
  local managed=0 missing=0 conflicting=0
  heading "Managed configuration"

  while IFS=$'\t' read -r stow_dir package; do
    package_root="$stow_dir/$package"
    while IFS= read -r -d '' source; do
      relative="${source#"$package_root"/}"
      target="$HOME/$relative"
      if [[ -L "$target" && "$target" -ef "$source" ]]; then
        managed=$((managed + 1))
      elif [[ ! -e "$target" && ! -L "$target" ]]; then
        printf 'missing: %s\n' "$target"
        missing=$((missing + 1))
        differences=$((differences + 1))
      elif [[ -f "$target" && -f "$source" ]] && cmp -s "$source" "$target"; then
        printf 'same content but unmanaged: %s\n' "$target"
        conflicting=$((conflicting + 1))
        differences=$((differences + 1))
      else
        printf 'conflict or local difference: %s\n' "$target"
        conflicting=$((conflicting + 1))
        differences=$((differences + 1))
      fi
    done < <(
      find "$package_root" \( -type f -o -type l \) \
        ! -name '.gitignore' \
        ! -name '.stow-local-ignore' \
        -print0
    )
  done < <(stow_package_roots "$platform")

  printf 'managed=%d missing=%d differing=%d\n' "$managed" "$missing" "$conflicting"
}

normalize_bundle() {
  sed -nE 's/^(tap|brew|cask|mas)[[:space:]]+"([^"]+)".*/\1 "\2"/p' "$1" \
    | sed -E 's#^brew "(.*/)?([^/"]+)"$#brew "\2"#' \
    | sort -u
}

audit_packages() {
  local actual actual_explicit expected formula
  heading "Packages"
  actual="$temporary_root/packages.actual"
  actual_explicit="$temporary_root/packages.explicit"
  expected="$temporary_root/packages.expected"

  case "$platform" in
    macos)
      if ! command -v brew >/dev/null 2>&1; then
        notice_difference "Homebrew is not installed"
        return
      fi
      {
        brew tap | sed 's/.*/tap "&"/'
        brew list --formula | sed 's/.*/brew "&"/'
        brew list --cask 2>/dev/null | sed 's/.*/cask "&"/'
        if command -v mas >/dev/null 2>&1; then
          mas list | sed -E 's/^[0-9]+ (.*) \\([^)]+\\)$/mas "\1"/'
        fi
      } | sort -u >"$actual"
      {
        brew tap | sed 's/.*/tap "&"/'
        while IFS= read -r formula; do
          printf 'brew "%s"\n' "${formula##*/}"
        done < <(brew leaves)
        brew list --cask 2>/dev/null | sed 's/.*/cask "&"/'
        if command -v mas >/dev/null 2>&1; then
          mas list | sed -E 's/^[0-9]+ (.*) \\([^)]+\\)$/mas "\1"/'
        fi
      } | sort -u >"$actual_explicit"
      normalize_bundle "$DOTFILES_ROOT/packages/macos/Brewfile" >"$expected"
      ;;
    arch)
      pacman -Qqe | sort -u >"$actual"
      cp "$actual" "$actual_explicit"
      sed -E '/^[[:space:]]*(#|$)/d' "$DOTFILES_ROOT/packages/arch/packages.txt" \
        | sort -u >"$expected"
      ;;
  esac

  if comm -23 "$expected" "$actual" | grep -q .; then
    notice_difference "Required by dotfiles but missing:"
    comm -23 "$expected" "$actual" | sed 's/^/  /'
  else
    printf 'No required packages are missing\n'
  fi
  if comm -13 "$expected" "$actual_explicit" | grep -q .; then
    notice_difference "Installed but not declared:"
    comm -13 "$expected" "$actual_explicit" | sed 's/^/  /'
  else
    printf 'No undeclared packages found\n'
  fi
}

audit_unmanaged_config() {
  local path name
  local known='^(btop|ghostty|mise|nvim|tmux|zed|zsh)$'
  heading "Unmanaged ~/.config candidates"
  if [[ ! -d "$HOME/.config" ]]; then
    printf '%s/.config does not exist\n' "$HOME"
    return
  fi
  while IFS= read -r -d '' path; do
    name="${path##*/}"
    [[ "$name" =~ $known ]] && continue
    printf 'candidate: %s\n' "$path"
  done < <(find "$HOME/.config" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
}

audit_git
audit_stow
audit_packages
audit_unmanaged_config

if [[ "$RUN_DOCTOR" -eq 1 ]]; then
  heading "Doctor"
  "$DOTFILES_ROOT/scripts/doctor.sh" --soft
fi

printf '\nAudit finished: %d difference group(s). No files were changed.\n' "$differences"
