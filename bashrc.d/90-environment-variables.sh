#!/bin/bash - 

export LANGUAGE=en_GB:en

# Enable 256 color capabilities for appropriate terminals

# Set this variable in your local shell config (such as ~/.bashrc)
# if you want remote xterms connecting to this system, to be sent 256 colors.
# This must be set before reading global initialization such as /etc/bashrc.
export SEND_256_COLORS_TO_REMOTE=1

# Tell that we run a 256 colors terminal
export TERM=xterm-256color

# ----- Define the powerline command required by tmux's powerline ----------->
if [ -f ~/.Dotfiles/libs/powerline/scripts/powerline ]; then
    export POWERLINE_COMMAND=~/.Dotfiles/libs/powerline/scripts/powerline
fi
# <---- Define the powerline command required by tmux's powerline ------------

# ----- Set the EDITOR to vim if available ---------------------------------->
if [ "x$(which vim)" != "x" ]; then
    export EDITOR=vim
fi
# <---- Set the EDITOR to vim if available -----------------------------------
