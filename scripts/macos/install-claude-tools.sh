#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h | --help)
      printf 'Usage: install-claude-tools.sh [--dry-run]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

# ai-memory backs the Claude Code hooks and MCP server in ~/.claude/settings.json.
ai_memory_version="3.2.2"
ai_memory_dir="$HOME/Applications/ai-memory"
case "$(uname -m)" in
  arm64)
    ai_memory_asset="ai-memory-macos-aarch64.tar.gz"
    ai_memory_sha256="6507cd1f1efff81beaa1e0568ce38dac10b190fd91ae203cecb2bd14dc94b691"
    ;;
  x86_64)
    ai_memory_asset="ai-memory-macos-x86_64.tar.gz"
    ai_memory_sha256="bc1f4ab9d12d0fee90f26e2e1bc4bb4177edd32cfc2b301c5af0372d31b765af"
    ;;
  *)
    die "ai-memory does not publish a release for architecture: $(uname -m)"
    ;;
esac

installed_version="$("$ai_memory_dir/ai-memory" --version 2>/dev/null | awk '{ print $2 }' || true)"
if [[ "$installed_version" == "$ai_memory_version" ]]; then
  log "ai-memory $ai_memory_version is already installed"
elif [[ "$DRY_RUN" -eq 1 ]]; then
  log "\$ download and verify $ai_memory_asset $ai_memory_version"
  log "\$ extract ai-memory into $ai_memory_dir"
else
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' EXIT
  archive="$temp_dir/$ai_memory_asset"
  url="https://github.com/akitaonrails/ai-memory/releases/download/v$ai_memory_version/$ai_memory_asset"

  run curl -fsSL "$url" -o "$archive"
  actual="$(/usr/bin/shasum -a 256 "$archive" | awk '{ print $1 }')"
  [[ "$actual" == "$ai_memory_sha256" ]] || die "checksum mismatch for $ai_memory_asset"

  ensure_dir "$ai_memory_dir"
  run tar -xzf "$archive" -C "$ai_memory_dir"
  log "Installed ai-memory $ai_memory_version"
fi

# The kj-mods plugin marketplace in settings.json points at this checkout.
claude_mods_dir="$HOME/Developer/personal-projects/claude-mods"
if [[ -d "$claude_mods_dir/.git" ]]; then
  log "claude-mods is already cloned at $claude_mods_dir"
else
  ensure_dir "$(dirname "$claude_mods_dir")"
  run git clone https://github.com/Kelvin-Jesus/cadence.git "$claude_mods_dir"
fi

# User-scope MCP servers live in ~/.claude.json, which also holds machine state.
if ! command -v claude >/dev/null 2>&1; then
  log "Claude Code is not installed; skipping MCP registration"
elif claude mcp get ai-memory >/dev/null 2>&1; then
  log "ai-memory MCP server is already registered"
else
  run claude mcp add --scope user --transport http ai-memory http://127.0.0.1:49374/mcp
fi
