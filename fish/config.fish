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
alias sqlitebrowser='/Applications/DB\ Browser\ for\ SQLite.app/Contents/MacOS/DB\ Browser\ for\ SQLite'

# `cat` → `bat` abbreviation
# Requires `brew install bat`
if type -q bat
  abbr --add -g cat 'bat'
end

# PATH ordering
set mysql_bin /opt/homebrew/opt/mysql-client@8.4/bin
fish_add_path --prepend --path --move $mysql_bin

set brew_bin (brew --prefix)/bin
fish_add_path --prepend --path --move $brew_bin

# Add ~/.local/bin to PATH
set home_local_bin $HOME/.local/bin/
fish_add_path --prepend --path --move $home_local_bin

# Add pyenv shims to PATH
set pyenv_shims $HOME/.pyenv/shims
fish_add_path --prepend --path --move $pyenv_shims

# The PATH order is now:
# Pyenv shims > ~/.local/bin > Homebrew > MySQL Client bin > system PATH
