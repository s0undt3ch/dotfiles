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
alias k9s-prod='begin; set -lx AWS_PROFILE pw-production; pdl login aws $AWS_PROFILE; aws eks update-kubeconfig --name production --region us-east-1; end; k9s'
alias k9s-staging='begin; set -lx AWS_PROFILE pw-staging; pdl login aws $AWS_PROFILE; aws eks update-kubeconfig --name $AWS_PROFILE --region us-east-1;  end; k9s'

function git --wraps git
    if test "$argv[1]" = "cliff" && test -f ~/.config/git-cliff/github-token
        command git cliff --github-token (cat ~/.config/git-cliff/github-token) $argv[2..-1]
    else
        command git $argv
    end
end

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

# The PATH order is now:
# ~/.local/bin > Homebrew > MySQL Client bin > system PATH


# Set COMPOSE_PROJECT_NAME so that the dashtastic containers share the same name,
# and not rely on the current directory for that.
set -Ux COMPOSE_PROJECT_NAME dashtastic
