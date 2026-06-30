# The Git helpers are vendored under the upstream MIT license. This preserves
# the familiar aliases without loading the Oh My Zsh framework.
omz_git_vendor="$ZSH_CONFIG_HOME/vendor/oh-my-zsh"
if [[ -r "$omz_git_vendor/lib/git.zsh" && -r "$omz_git_vendor/plugins/git/git.plugin.zsh" ]]; then
  source "$omz_git_vendor/lib/git.zsh"
  source "$omz_git_vendor/plugins/git/git.plugin.zsh"
fi
unset omz_git_vendor

source_first_available() {
  local candidate
  for candidate in "$@"; do
    if [[ -r "$candidate" ]]; then
      source "$candidate"
      return 0
    fi
  done
  return 1
}

source_first_available \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  "/usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  || true

if [[ -o zle && -t 0 && -t 1 ]] && command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh)"
fi

if [[ -o interactive && -t 1 && ${TERM:-dumb} != dumb ]] &&
  command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# zsh-syntax-highlighting must be sourced after all other plugins.
source_first_available \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  "/usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  || true

unfunction source_first_available
