GEM_HOME=$HOME/.gems
PATH=$HOME/bin:$GEM_HOME/bin:$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting
if test -f ~/.rvm/scripts/rvm; then
    [ "$(type -t rvm)" = "function" ] || source ~/.rvm/scripts/rvm
fi
