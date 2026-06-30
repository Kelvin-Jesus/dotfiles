#!/usr/bin/env bash

set -Eeuo pipefail

DOTFILES_ROOT="${DOTFILES_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

cat <<'EOF'
Running the safe validation suite:
- shell syntax checks;
- LaunchAgent plist validation;
- Stow twice in a temporary HOME;
- complete installer dry-run;
- native-app removal dry-run.

macOS preferences cannot be redirected reliably to another HOME. To test their
real visual effect, use a temporary macOS user account after this suite passes.
EOF

exec "$DOTFILES_ROOT/scripts/test.sh"
