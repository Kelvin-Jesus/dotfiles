#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

if [[ $# -eq 0 ]]; then
  printf 'Usage: install-release-apps.sh [--dry-run] open-design|sidescreen|spotiflac [...]\n'
  exit 1
fi

apps=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h | --help)
      printf 'Usage: install-release-apps.sh [--dry-run] open-design|sidescreen|spotiflac [...]\n'
      exit 0
      ;;
    *)
      apps+=("$1")
      ;;
  esac
  shift
done

install_dmg() {
  local id version url sha256 expected_app destination
  id="$1"
  version="$2"
  url="$3"
  sha256="$4"
  expected_app="$5"
  destination="/Applications/$expected_app"

  if [[ -d "$destination" ]]; then
    installed_version="$(
      /usr/bin/defaults read "$destination/Contents/Info" CFBundleShortVersionString 2>/dev/null || true
    )"
    if [[ "$installed_version" == "$version" ]]; then
      log "$expected_app $version is already installed"
      return
    fi
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "\$ curl -fL $url -o <temporary-dmg>"
    log "\$ verify $id $version SHA-256 $sha256"
    log "\$ mount read-only and copy $expected_app to /Applications"
    return
  fi

  local temp_dir dmg mount_point actual_sha
  temp_dir="$(mktemp -d)"
  dmg="$temp_dir/$id.dmg"
  mount_point="$temp_dir/mount"
  mkdir -p "$mount_point"

  run /usr/bin/curl -fL "$url" -o "$dmg"
  actual_sha="$(/usr/bin/shasum -a 256 "$dmg" | awk '{print $1}')"
  [[ "$actual_sha" == "$sha256" ]] || die "$id SHA-256 mismatch"

  (
    /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$mount_point" "$dmg" >/dev/null
    trap '/usr/bin/hdiutil detach "$mount_point" >/dev/null 2>&1 || true' EXIT
    app_path="$(find "$mount_point" -maxdepth 3 -type d -name "$expected_app" -print -quit)"
    [[ -n "$app_path" ]] || die "$expected_app was not found in the disk image"
    if [[ -e "$destination" ]]; then
      run_sudo rm -rf "$destination"
    fi
    run_sudo /usr/bin/ditto "$app_path" "$destination"
  )

  rm -rf "$temp_dir"
  log "$expected_app $version installed; Gatekeeper settings were not modified"
}

for app in "${apps[@]}"; do
  case "$app" in
    open-design)
      case "$(uname -m)" in
        arm64)
          install_dmg \
            open-design \
            0.12.0 \
            https://github.com/nexu-io/open-design/releases/download/open-design-v0.12.0/open-design-0.12.0-mac-arm64.dmg \
            d793e24ddefd7414fce116fc7fdec194fcd0f9e4b3b6629aaac327c132331ca6 \
            "Open Design.app"
          ;;
        x86_64)
          install_dmg \
            open-design \
            0.12.0 \
            https://github.com/nexu-io/open-design/releases/download/open-design-v0.12.0/open-design-0.12.0-mac-x64.dmg \
            602262c379e3ed733b42255bdb6030c4b02e8ea49e6d5a56dc7fcbf0e5ea81da \
            "Open Design.app"
          ;;
        *)
          die "unsupported architecture for Open Design: $(uname -m)"
          ;;
      esac
      ;;
    sidescreen)
      install_dmg \
        sidescreen \
        0.11.0 \
        https://github.com/tranvuongquocdat/SideScreen/releases/download/0.11.0/SideScreen-0.11.0-mac-universal.dmg \
        92ffcecc71b3c51f0c5801e5bbc470b3d9a310bcccf4ff12a7cbe108bfb3108b \
        "SideScreen.app"
      ;;
    spotiflac)
      install_dmg \
        spotiflac \
        7.1.9 \
        https://github.com/spotbye/SpotiFLAC/releases/download/v7.1.9/SpotiFLAC.dmg \
        5584f69964b3c8bf4a505aa02d1f6af1ce8b53ce864bdf2a341017e85ecf3e43 \
        "SpotiFLAC.app"
      ;;
    *)
      die "unknown release app: $app"
      ;;
  esac
done
