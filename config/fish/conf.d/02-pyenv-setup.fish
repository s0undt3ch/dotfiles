if test -d ~/.dotfiles/.ext/pyenv
    # If the pyenv checkout exists, update environment
    set --export PYENV_ROOT ~/.dotfiles/.ext/pyenv
    set fish_user_paths $PYENV_ROOT/bin $fish_user_paths

    #if test -d $PYENV_ROOT/plugins/pyenv-virtualenv
    #  if not set -q __pyenv_virtualenv_bin_path_set
    #      set --universal fish_user_paths $PYENV_ROOT/plugins/pyenv-virtualenv/bin $fish_user_paths
    #      set -g __pyenv_virtualenv_bin_path_set 1
    #  end
    #end

    set --export VIRTUAL_ENV_DISABLE_PROMPT 1
    status --is-interactive; and . (pyenv init -|psub)
    status --is-interactive; and . (pyenv virtualenv-init -|psub)
end
