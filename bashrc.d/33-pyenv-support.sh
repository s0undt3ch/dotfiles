#!/bin/sh

PYENV_ROOT="$HOME/.Dotfiles/libs/pyenv"
PATH="$PYENV_ROOT/bin:$PATH"

eval "$(pyenv init -)"
