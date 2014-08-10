#!/bin/sh

export PYENV_ROOT="$HOME/.Dotfiles/libs/pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"

# Completion
source ${PYENV_ROOT}/completions/pyenv.bash

eval "$(pyenv init -)"
