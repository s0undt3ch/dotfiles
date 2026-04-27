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
alias git-push-source-branch='git push --set-upstream origin (git branch --show-current)'
alias gs=git-spice

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

# PATH ordering lives in conf.d/00_paths.fish so it runs before mise
# activation, letting mise prepend its tool install dirs last (highest
# priority).

# Set COMPOSE_PROJECT_NAME so that the dashtastic containers share the same name,
# and not rely on the current directory for that.
set -Ux COMPOSE_PROJECT_NAME dashtastic
