#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

if [[ $# -eq 0 ]]; then
  printf 'Usage: install-release-apps.sh [--dry-run] open-design|sidescreen|spotiflac|motrixmac|omlx|learnharness|index0 [...]\n'
  exit 1
fi

apps=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h | --help)
      printf 'Usage: install-release-apps.sh [--dry-run] open-design|sidescreen|spotiflac|motrixmac|omlx|learnharness|index0 [...]\n'
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
    motrixmac)
      case "$(uname -m)" in
        arm64)
          install_dmg \
            motrixmac \
            1.2.8 \
            https://github.com/ShawnRn/MotrixMac/releases/download/v1.2.8/MotrixMac_1.2.8_arm64.dmg \
            65ed7f9f88fa9eab7a77f8f68b3328be0612016c3f2d690cfbf37cccfae8f0ba \
            "MotrixMac.app"
          ;;
        x86_64)
          install_dmg \
            motrixmac \
            1.2.8 \
            https://github.com/ShawnRn/MotrixMac/releases/download/v1.2.8/MotrixMac_1.2.8_x86_64.dmg \
            53deba2948a823e906bebe9c9aff9d2937cf3aa698e4a90dc41996801ba8c802 \
            "MotrixMac.app"
          ;;
        *)
          die "unsupported architecture for MotrixMac: $(uname -m)"
          ;;
      esac
      ;;
    omlx)
      [[ "$(uname -m)" == "arm64" ]] || die "oMLX requires Apple Silicon"
      if [[ "$(/usr/bin/sw_vers -productVersion | cut -d. -f1)" -ge 26 ]]; then
        install_dmg \
          omlx \
          0.8.3 \
          https://github.com/jundot/omlx/releases/download/v0.8.3/oMLX-0.8.3-macos26-27.dmg \
          a3985ac20f53a5a9a1656ec19353e00ff0a628aae1285bfa5164fd600217af07 \
          "oMLX.app"
      else
        install_dmg \
          omlx \
          0.8.3 \
          https://github.com/jundot/omlx/releases/download/v0.8.3/oMLX-0.8.3-macos15-sequoia.dmg \
          f2122da492650d33ea89ad558e0572846738557b02e0e1fd7778520880069c0b \
          "oMLX.app"
      fi
      ;;
    learnharness)
      [[ "$(uname -m)" == "arm64" ]] || die "LearnHarness requires Apple Silicon"
      install_dmg \
        learnharness \
        0.7.0 \
        https://github.com/amosblomqvist/learnharness/releases/download/v0.7.0/LearnHarness-0.7.0-arm64.dmg \
        64ffab3cec0a49310fa7551335025d7078b7b57f2e283a26a17a4cdc4533e314 \
        "LearnHarness.app"
      ;;
    index0)
      case "$(uname -m)" in
        arm64)
          install_dmg \
            index0 \
            1.9.2 \
            https://github.com/MadhumithaKolkar/index0-releases/releases/download/v1.9.2/INDEX0-arm64.dmg \
            fceb7e7e164a0d1add7dbf5dca53d8a195bf95ecbd0c83d56e8d5ee612c54fc9 \
            "INDEX 0.app"
          ;;
        x86_64)
          install_dmg \
            index0 \
            1.9.2 \
            https://github.com/MadhumithaKolkar/index0-releases/releases/download/v1.9.2/INDEX0-x64.dmg \
            4b8efd24cc7357e2104c128a28ef680edaa47420098bab48db5086ca50b2514c \
            "INDEX 0.app"
          ;;
        *)
          die "unsupported architecture for INDEX 0: $(uname -m)"
          ;;
      esac
      ;;
    *)
      die "unknown release app: $app"
      ;;
  esac
done
