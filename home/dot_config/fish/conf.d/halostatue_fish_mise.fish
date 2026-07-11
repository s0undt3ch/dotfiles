# @halostatue/fish-mise/conf.d/halostatue_fish_mise.fish:v1.0.1

function _halostatue_fish_mise_setup
    if command --query mise
        set --function mise (command --search mise)
    else
        set --local candidates HOME/.local/bin $HOME/bin $HOME/.bin

        command --query port
        and set --append candidates /opt/local/bin

        if command --query brew
            set --append candidates (brew --prefix)/bin
        else
            set --append candidates /opt/homebrew/bin
        end

        set --append candidates /usr/local/bin /usr/bin

        if path is --type file --perm exec $candidates/mise
            set --function mise (path filter --type file --perm exec $candidates/mise)[1]
        else
            return 1
        end
    end

    # Disable the mise auto activation script included with Homebrew mise.
    set -g MISE_FISH_AUTO_ACTIVATE 0

    set --local mode

    switch $mise_activate_mode[1]
        case shims status
            set mode --$mise_activate_mode[1]
    end

    $mise activate fish $mode | source

    if test "$mise_completions" != 0
        if path is --type file $fish_complete_path/mise.fish
            if ! command --query usage && ! $mise which usage >/dev/null 2>/dev/null
                $mise use -g usage
            end
        else
            if command --query usage || $mise which usage >/dev/null 2>/dev/null
                $mise completion fish | source
            end
        end
    end
end

_halostatue_fish_mise_setup
functions -e _halostatue_fish_mise_setup

function _halostatue_fish_mise_uninstall --on-event halostatue_fish_mise_uninstall
end
