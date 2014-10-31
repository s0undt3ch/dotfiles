export EDITOR=vim
export BROWSER=firefox

if [ -f $ZDOTDIR/dircolors ]; then
    eval $(dircolors -b $ZDOTDIR/dircolors)
fi
