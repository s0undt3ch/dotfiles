if test -d ~/.dotfiles/.ext/pyenv
    # If the pyenv checkout exists, update environment
    if not set -g __pyenv_root_path_set
        set --universal --export PYENV_ROOT ~/.dotfiles/.ext/pyenv
        set -g __pyenv_root_path_set 1
    end

    if not set -q __pyenv_bin_path_set
      set -U fish_user_paths $PYENV_ROOT/bin $fish_user_paths
      set -g __pyenv_bin_path_set 1
    end

    if test -d $PYENV_ROOT/plugins/pyenv-virtualenv
      if not set -q __pyenv_virtualenv_bin_path_set
          set --universal fish_user_paths $PYENV_ROOT/plugins/pyenv-virtualenv/bin $fish_user_paths
          set -g __pyenv_virtualenv_bin_path_set 1
      end
    end
end

# If the pyenv binary is found in path, initialize it
status --is-interactive; and . (pyenv init -|psub)

if test -h $PYENV_ROOT/plugins/pyenv-virtualenv
    set --universal --export VIRTUAL_ENV_DISABLE_PROMPT 1
    status --is-interactive; and . (pyenv virtualenv-init -|psub)
end
