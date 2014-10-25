#!/bin/sh

# Find symlinked fonts
find $HOME/.fonts -type l >/dev/null 2>&1
if [ $? -eq 0 ]; then
    # We have symlinked fonts, update fonts cache
    fc-cache -f
fi
