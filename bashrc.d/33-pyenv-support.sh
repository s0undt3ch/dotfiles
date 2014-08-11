#!/bin/sh

export PYENV_ROOT="$HOME/.Dotfiles/libs/pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
export PYENV_VIRTUALENVWRAPPER_PREFER_PYVENV="true"

# Completion
source ${PYENV_ROOT}/completions/pyenv.bash

eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
