#!/bin/bash - 
[[ -z $DISPLAY  && $XDG_VTNR -lt 2 ]] && exec startx
