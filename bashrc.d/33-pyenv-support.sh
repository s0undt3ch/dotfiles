#!/bin/sh

export PYENV_ROOT="$HOME/.Dotfiles/libs/pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"

if [ "$(which pyenv)" != "" ]; then
    # Init pyenv
    eval "$(pyenv init -)"

    # Start pyenv-virtualwrapper
    pyenv virtualenvwrapper

    # Init pyenv virtualenv
    eval "$(pyenv virtualenv-init -)"

    # Completion
    . "${PYENV_ROOT}/completions/pyenv.bash"

    # Virtualenv auto-activation
    . "${PYENV_ROOT}/plugins/pyenv-autoenv/bin/pyenv-autoenv"
fi
