# don't put duplicate lines in the history. See bash(1) for more options
# don't overwrite GNU Midnight Commander's setting of `ignorespace'.
#export HISTCONTROL=$HISTCONTROL${HISTCONTROL+,}ignoredups
# ... or force ignoredups and ignorespace
unset HISTSIZE
unset HISTCONTROL
unset HISTFILESIZE

export HISTCONTROL=ignoreboth
export HISTFILESIZE=100000000
export HISTSIZE=100000000


# auto correct the case on tab completion
shopt -s nocaseglob

# Correct typos in your file/directory name
shopt -s cdspell

# append to the history file, don't overwrite it, even on multiple simultaneous shells
shopt -s histappend

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize
