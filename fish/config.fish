# Enable Starship prompt
starship init fish | source


#fish_config theme save "Catppuccin Mocha"

# Don't truncate the paths
set fish_prompt_pwd_dir_length 0

# Disable greeting
set fish_greeting

if status is-interactive
    eval "$(brew shellenv)"
end

alias vi=$(which nvim)
alias vim=$(which nvim)

# `cat` → `bat` abbreviation
# Requires `brew install bat`
if type -q bat
  abbr --add -g cat 'bat'
end

# Add ~/.local/bin to PATH
set home_local_bin $HOME/.local/bin/
if not contains -- $home_local_bin $fish_user_paths
    fish_add_path --prepend --path $home_local_bin
end
