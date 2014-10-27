#!/bin/sh -
if [ -z $SSH_CLIENT ] && [ -z $SSH_TTY ] && [ -z $DISPLAY  ] && [ $XDG_VTNR -lt 2 ]; then
    # If this is not an SSH seesion and the TTY number is less than 2, then startx
    exec startx
fi
