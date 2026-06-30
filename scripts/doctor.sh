#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
# shellcheck source=lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"

SOFT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --soft)
      SOFT=1
      ;;
    -h | --help)
      printf 'Usage: doctor.sh [--soft]\n'
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
  shift
done

failures=0
warnings=0

ok() {
  printf 'ok    %s\n' "$*"
}

missing() {
  printf 'FAIL  %s\n' "$*" >&2
  failures=$((failures + 1))
}

notice() {
  printf 'warn  %s\n' "$*"
  warnings=$((warnings + 1))
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    ok "command: $1"
  else
    missing "command not found: $1"
  fi
}

check_managed_config() {
  local config_path
  config_path="$1"
  if [[ -L "$config_path" && -e "$config_path" ]]; then
    ok "managed config: $config_path"
  elif [[ -L "$config_path" ]]; then
    missing "broken config link: $config_path"
  elif [[ -e "$config_path" ]]; then
    notice "config is not managed by Stow: $config_path"
  else
    missing "config missing: $config_path"
  fi
}

check_default() {
  local domain key expected actual
  domain="$1"
  key="$2"
  expected="$3"
  actual="$(/usr/bin/defaults read "$domain" "$key" 2>/dev/null || true)"
  if [[ "$actual" == "$expected" ]]; then
    ok "preference: $domain $key=$expected"
  else
    notice "preference differs: $domain $key=${actual:-unset} (expected $expected)"
  fi
}

commands=(
  zsh
  starship
  fzf
  zoxide
  eza
  bat
  rg
  fd
  gping
  hyperfine
  btop
  tmux
  task
  jq
  fastfetch
  docker
  git
  mise
  nvim
  stow
  lazygit
  tree-sitter
)

for command_name in "${commands[@]}"; do
  check_command "$command_name"
done

for config_path in \
  "$HOME/.zshrc" \
  "$HOME/.config/starship.toml" \
  "$HOME/.config/nvim/init.lua" \
  "$HOME/.config/tmux/tmux.conf" \
  "$HOME/.config/zed/settings.json"; do
  check_managed_config "$config_path"
done

platform="$(detect_platform)"
if [[ -d "$HOME/Documents/wallpapers" ]]; then
  ok "wallpaper directory: $HOME/Documents/wallpapers"
else
  notice "wallpaper directory missing: $HOME/Documents/wallpapers"
fi

if [[ "$platform" == "macos" ]]; then
  apps=(
    "Anki.app"
    "FeedFlow.app"
    "KeePassXC.app"
    "LocalSend.app"
    "Obsidian.app"
    "Open Design.app"
    "OrbStack.app"
    "PureMac.app"
    "RustDesk.app"
    "Stremio.app"
    "Syncthing.app"
    "Upscayl.app"
    "VLC.app"
    "Zed.app"
    "Zen.app"
  )

  for app in "${apps[@]}"; do
    if [[ -d "/Applications/$app" ]]; then
      ok "application: $app"
    else
      notice "application missing: $app"
    fi
  done

  fonts=(
    "FiraCodeNerdFontMono-Retina.ttf"
    "JetBrainsMono*Nerd*Font*"
    "Iosevka*Nerd*Font*"
    "Inter*"
    "Literata*"
  )
  for font_pattern in "${fonts[@]}"; do
    if find "$HOME/Library/Fonts" /Library/Fonts -maxdepth 1 -iname "$font_pattern" \
      -print -quit 2>/dev/null | grep -q .; then
      ok "font: $font_pattern"
    else
      notice "font not found: $font_pattern"
    fi
  done

  check_default NSGlobalDomain AppleInterfaceStyle Dark
  check_default NSGlobalDomain AppleIconAppearanceTheme RegularDark
  check_default com.apple.universalaccess reduceTransparency 1
  check_default com.apple.finder ShowSidebar 1
  check_default com.apple.finder ShowPathbar 1
  check_default com.apple.finder FXPreferredViewStyle Nlsv

  developer_icon="$HOME/Developer/Icon"$'\r'
  if [[ -e "$developer_icon" ]] \
    && /usr/bin/xattr -p com.apple.ResourceFork "$developer_icon" >/dev/null 2>&1; then
    ok "Developer folder icon is configured"
  else
    notice "Developer folder icon is not configured"
  fi

  if /bin/launchctl print "gui/$UID/com.dotfiles.caps-to-escape" >/dev/null 2>&1; then
    ok "Caps Lock to Escape LaunchAgent is loaded"
  else
    notice "Caps Lock to Escape LaunchAgent is not loaded"
  fi

  if command -v defaultbrowser >/dev/null 2>&1; then
    default_browser="$(defaultbrowser 2>/dev/null || true)"
    default_browser_lower="$(printf '%s' "$default_browser" | tr '[:upper:]' '[:lower:]')"
    if [[ "$default_browser_lower" == *zen* ]]; then
      ok "default browser: Zen"
    else
      notice "default browser is not Zen: ${default_browser:-unknown}"
    fi
  else
    notice "defaultbrowser is unavailable; cannot verify Zen"
  fi

  expected_dns="1.1.1.1 1.0.0.1"
  network_services="$(/usr/sbin/networksetup -listallnetworkservices | tail -n +2)"
  while IFS= read -r service; do
    [[ -n "$service" ]] || continue
    [[ "$service" == \** ]] && continue
    dns_output="$(/usr/sbin/networksetup -getdnsservers "$service")"
    actual_dns="${dns_output//$'\n'/ }"
    if [[ "$actual_dns" == "$expected_dns" ]]; then
      ok "DNS: $service uses Cloudflare"
    else
      notice "DNS differs for $service: $actual_dns"
    fi
  done <<<"$network_services"

  if docker info >/dev/null 2>&1; then
    ok "Docker daemon is available"
  else
    notice "Docker daemon is unavailable; start OrbStack when needed"
  fi

  if command -v brew >/dev/null 2>&1 \
    && brew bundle check --file="$DOTFILES_ROOT/packages/macos/Brewfile" >/dev/null 2>&1; then
    ok "Homebrew bundle is satisfied"
  else
    notice "Homebrew bundle has missing or changed entries"
  fi
else
  check_command syncthing
  if systemctl is-enabled keyd.service >/dev/null 2>&1; then
    ok "keyd service enabled"
  else
    notice "keyd service is not enabled"
  fi
  if systemctl is-enabled docker.service >/dev/null 2>&1; then
    ok "Docker service enabled"
  else
    notice "Docker service is not enabled"
  fi
fi

while IFS= read -r -d '' managed_link; do
  if [[ ! -e "$managed_link" ]]; then
    missing "broken symlink: $managed_link -> $(readlink "$managed_link")"
  fi
done < <(find "$HOME/.config" -type l -print0 2>/dev/null)

printf '\nDoctor: %d failure(s), %d warning(s)\n' "$failures" "$warnings"
if [[ "$failures" -gt 0 && "$SOFT" -eq 0 ]]; then
  exit 1
fi
