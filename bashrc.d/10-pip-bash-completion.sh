# pip bash completion start

#export PIP_DOWNLOAD_CACHE=$HOME/.pip/cache
#export PIP_SOURCE_DIR=$HOME/.pip/source
#export PIP_BUILD_DIR=$HOME/.pip/build
export PIP_RESPECT_VIRTUALENV=true
export PIP_REQUIRE_VIRTUALENV=true
export VIRTUALENV_USE_DISTRIBUTE=1

_pip_completion()
{
    COMPREPLY=( $( COMP_WORDS="${COMP_WORDS[*]}" \
                   COMP_CWORD=$COMP_CWORD \
                   PIP_AUTO_COMPLETE=1 $1 ) )
}
complete -o default -F _pip_completion pip
# pip bash completion end
