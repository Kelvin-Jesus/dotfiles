#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
# shellcheck source=../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

backup_dir=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      ;;
    -h | --help)
      printf 'Usage: restore-settings.sh [--dry-run] BACKUP_DIR\n'
      exit 0
      ;;
    *)
      [[ -z "$backup_dir" ]] || die "only one backup directory is accepted"
      backup_dir="$1"
      ;;
  esac
  shift
done

[[ -n "$backup_dir" ]] || die "a backup directory is required"
[[ -d "$backup_dir/defaults" ]] || die "invalid backup directory: $backup_dir"

for plist in "$backup_dir/defaults/"*.plist; do
  [[ -f "$plist" ]] || continue
  domain="$(basename "$plist" .plist)"
  run /usr/bin/defaults import "$domain" "$plist"
done

shared_dir="$HOME/Library/Application Support/com.apple.sharedfilelist"
for sidebar_file in "$backup_dir/"*FavoriteItems*.sfl[34]; do
  [[ -f "$sidebar_file" ]] || continue
  ensure_dir "$shared_dir"
  run cp -p "$sidebar_file" "$shared_dir/$(basename "$sidebar_file")"
done

power_backup="$backup_dir/power-settings.txt"
if [[ -s "$power_backup" ]]; then
  battery_args=()
  charger_args=()
  ups_args=()
  while IFS=$'\t' read -r mode setting value; do
    case "$mode" in
      -b)
        battery_args+=("$setting" "$value")
        ;;
      -c)
        charger_args+=("$setting" "$value")
        ;;
      -u)
        ups_args+=("$setting" "$value")
        ;;
    esac
  done < <(
    awk '
      /^Battery Power:$/ { mode = "-b"; next }
      /^AC Power:$/      { mode = "-c"; next }
      /^UPS Power:$/     { mode = "-u"; next }
      mode && NF == 2    { print mode "\t" $1 "\t" $2 }
    ' "$power_backup"
  )

  if ((${#battery_args[@]})); then
    run_sudo /usr/bin/pmset -b "${battery_args[@]}"
  fi
  if ((${#charger_args[@]})); then
    run_sudo /usr/bin/pmset -c "${charger_args[@]}"
  fi
  if ((${#ups_args[@]})); then
    run_sudo /usr/bin/pmset -u "${ups_args[@]}"
  fi
fi

network_backup="$backup_dir/network-dns.tsv"
if [[ -s "$network_backup" ]]; then
  while IFS=$'\t' read -r service dns_values; do
    [[ -n "$service" && -n "$dns_values" ]] || continue
    read -r -a dns_servers <<<"$dns_values"
    run_sudo /usr/sbin/networksetup -setdnsservers "$service" "${dns_servers[@]}"
  done <"$network_backup"
fi

run_allow_failure /usr/bin/killall cfprefsd
run_allow_failure /usr/bin/killall sharedfilelistd
run_allow_failure /usr/bin/killall Finder
run_allow_failure /usr/bin/killall Dock
log "Preferences restored from $backup_dir"
