ZSH_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}/zsh"

for config_file in env options completion aliases plugins fastfetch; do
  config_path="$ZSH_CONFIG_HOME/$config_file.zsh"
  [[ -r "$config_path" ]] && source "$config_path"
done
unset config_file config_path

# Machine-specific configuration and secrets stay outside the dotfiles repo.
[[ -r "$HOME/.zshrc.local" ]] && source "$HOME/.zshrc.local"
