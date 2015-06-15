# vim: ts=4 sts=4 et
#
HOME=${HOME:-$(cd ~ && pwd)}

if [ -n "$(whence powerline-daemon)" ]; then
    if [ -z "$(ps aux | grep 'bin/powerline-daemon' | grep -v grep)" ]; then
        export POWERLINE_COMMAND="$HOME/.dotfiles/.ext/powerline/scripts/powerline"
        powerline-daemon
    fi
fi
