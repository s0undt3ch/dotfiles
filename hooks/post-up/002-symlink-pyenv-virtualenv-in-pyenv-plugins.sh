#!/bin/sh

PYENV_ROOT="$HOME/.dotfiles/.ext/pyenv"

if [ -d "$HOME/.dotfiles/.ext/pyenv-virtualenv" ]; then
    # If the pyenv-virtualenv checkout exists, update environment
    if [ ! -h "$PYENV_ROOT/plugins/pyenv-virtualenv" ]; then
        cd "$PYENV_ROOT/plugins"
        ln -sf ../../pyenv-virtualenv/ .
    fi
fi
