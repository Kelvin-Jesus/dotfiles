typeset -U path PATH

path=("$HOME/.local/bin" $path)

for optional_bin in \
  "$HOME/.lmstudio/bin" \
  "$HOME/.antigravity/antigravity/bin" \
  "$HOME/.mimocode/bin"
do
  [[ -d "$optional_bin" ]] && path=("$optional_bin" $path)
done
unset optional_bin

export PATH
export EDITOR="${EDITOR:-nvim}"
export VISUAL="${VISUAL:-$EDITOR}"
export PAGER="${PAGER:-less}"
export LESS="${LESS:--R}"
export skills="${skills:-$HOME/Dev/ai-skills}"

if command -v fd >/dev/null 2>&1; then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
fi
