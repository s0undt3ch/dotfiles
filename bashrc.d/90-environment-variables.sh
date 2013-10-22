#!/bin/bash - 

export LANGUAGE=en_GB:en

# Enable 256 color capabilities for appropriate terminals

# Set this variable in your local shell config (such as ~/.bashrc)
# if you want remote xterms connecting to this system, to be sent 256 colors.
# This must be set before reading global initialization such as /etc/bashrc.
export SEND_256_COLORS_TO_REMOTE=1


# ----- Set the EDITOR to vim if available ---------------------------------->
if [ "x$(which vim)" != "x" ]; then
    export EDITOR=vim
fi
# <---- Set the EDITOR to vim if available -----------------------------------
