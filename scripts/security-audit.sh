#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

MODE="tracked"

usage() {
  cat <<'EOF'
Usage: security-audit.sh [--tracked|--staged]

Scans filenames and file contents without printing possible secret values.
The command exits non-zero when a finding is detected.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tracked)
      MODE="tracked"
      ;;
    --staged)
      MODE="staged"
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

require_command git
repo_root="$(git -C "$DOTFILES_ROOT" rev-parse --show-toplevel 2>/dev/null)" \
  || die "$DOTFILES_ROOT is not a Git repository"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-security-audit.XXXXXX")"
trap 'rm -rf "$temporary_root"' EXIT
file_list="$temporary_root/files"

case "$MODE" in
  tracked)
    git -C "$repo_root" ls-files -z >"$file_list"
    ;;
  staged)
    git -C "$repo_root" diff --cached --name-only --diff-filter=ACMR -z >"$file_list"
    ;;
esac

findings=0

report() {
  local category path
  category="$1"
  path="$2"
  printf 'FAIL  %-22s %s\n' "$category" "$path" >&2
  findings=$((findings + 1))
}

is_forbidden_filename() {
  local path basename
  path="$1"
  basename="${path##*/}"
  case "$basename" in
    .env.example)
      return 1
      ;;
    .env | .env.* | .npmrc | .netrc | credentials | known_hosts | known_hosts.* | \
      authorized_keys | id_* | *.key | *.pem | *.p12 | *.pfx | *.kbx | trustdb.gpg | \
      secring.gpg)
      return 0
      ;;
  esac
  case "$path" in
    */private-keys-v1.d/* | */openpgp-revocs.d/*)
      return 0
      ;;
  esac
  return 1
}

content_for() {
  local path
  path="$1"
  if [[ "$MODE" == "staged" ]]; then
    git -C "$repo_root" show ":$path" 2>/dev/null
  else
    /bin/cat "$repo_root/$path" 2>/dev/null
  fi
}

token_prefixes='(g''hp_|g''ho_|g''hs_|github_''pat_|s''k-|n''pm_|xox[bpe]-|AK''IA|AI''za|gl''pat-|py''pi-|s''k_live_|p''k_live_|r''k_live_|dop_''v1_)'
assignment_pattern='(api[_-]?key|secret|token|password|credential)[[:space:]]*[:=][[:space:]]*["'\'']?[[:alnum:]_./+=-]{8,}'
private_key_pattern='-----BEGIN[[:space:]][^-]*PRIVATE[[:space:]]KEY-----'

content_file="$temporary_root/content"
while IFS= read -r -d '' path; do
  [[ -n "$path" ]] || continue
  if is_forbidden_filename "$path"; then
    report "sensitive filename" "$path"
  fi
  content_for "$path" >"$content_file" || true
  if LC_ALL=C grep -IqiE "$token_prefixes" "$content_file"; then
    report "token-like content" "$path"
  fi
  if LC_ALL=C grep -IqiE "$assignment_pattern" "$content_file"; then
    report "secret assignment" "$path"
  fi
  if LC_ALL=C grep -IqE -- "$private_key_pattern" "$content_file"; then
    report "private key" "$path"
  fi
done <"$file_list"

if [[ "$findings" -gt 0 ]]; then
  printf '\nSecurity audit: %d finding(s). Values were intentionally not printed.\n' \
    "$findings" >&2
  exit 1
fi

printf 'Security audit: no findings in %s files\n' "$MODE"
