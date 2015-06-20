# vim: ts=4 sts=4 et
#
HOME=${HOME:-$(cd ~ && pwd)}

if [ -z "$POWERLINE_COMMAND" ]; then
    export POWERLINE_COMMAND="$HOME/.dotfiles/.ext/powerline/scripts/powerline"
fi

if [ -n "$(whence powerline-daemon)" ]; then
    if [ -z "$(ps aux | grep 'bin/powerline-daemon' | grep -v grep)" ]; then
        powerline-daemon
    fi
fi
