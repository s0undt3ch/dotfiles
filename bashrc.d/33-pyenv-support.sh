#!/bin/sh

export PYENV_ROOT="$HOME/.Dotfiles/libs/pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"

# Init pyenv
eval "$(pyenv init -)"

# Init pyenv virtualenv
eval "$(pyenv virtualenv-init -)"

# Completion
. "${PYENV_ROOT}/completions/pyenv.bash"
