# vim: ts=4 sts=4 et

HOME=${HOME:-$(cd ~ && pwd)}

if [ -d "$HOME/.dotfiles/.ext/pyenv" ]; then
    # If the pyenv checkout exists, update environment
    export PYENV_ROOT="$HOME/.dotfiles/.ext/pyenv"

    path+="$PYENV_ROOT/bin"

    if [ -d "$HOME/.dotfiles/.ext/pyenv-virtualenv" ]; then
        path+="$PYENV_ROOT/plugins/pyenv-virtualenv/bin"
    fi
fi

if [ "$(whence pyenv)" != "" ]; then
    # If the pyenv binary is found in path, initialize it
    eval "$(pyenv init -)"

    if [ -h "$PYENV_ROOT/plugins/pyenv-virtualenv" ]; then
        eval "$(pyenv virtualenv-init -)"
    fi
fi
