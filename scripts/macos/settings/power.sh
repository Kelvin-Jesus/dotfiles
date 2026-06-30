#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)}"
# shellcheck source=../../lib/common.sh
source "$DOTFILES_ROOT/scripts/lib/common.sh"
require_macos

battery_display_sleep="${DOTFILES_PMSET_BATTERY_DISPLAY_SLEEP:-10}"
battery_sleep="${DOTFILES_PMSET_BATTERY_SLEEP:-15}"
ac_display_sleep="${DOTFILES_PMSET_AC_DISPLAY_SLEEP:-30}"
ac_sleep="${DOTFILES_PMSET_AC_SLEEP:-0}"

run_sudo /usr/bin/pmset -b \
  displaysleep "$battery_display_sleep" \
  sleep "$battery_sleep" \
  disksleep 10 \
  lowpowermode 1 \
  powernap 0

run_sudo /usr/bin/pmset -c \
  displaysleep "$ac_display_sleep" \
  sleep "$ac_sleep" \
  disksleep 10 \
  lowpowermode 0 \
  powernap 1 \
  womp 1
