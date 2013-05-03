if [ `id -u` == '0' ]; then
    USERCOLOR='01;34m'
else
    USERCOLOR='01;32m'
fi

#GIT_PS1_SHOWDIRTYSTATE=1
#GIT_PS1_SHOWUPSTREAM="verbose"
GIT_PS1_SHOWSTASHSTATE=1
#GIT_PS1_SHOWUNTRACKEDFILES=1

if [ "$(command -v __git_ps1)x" = "x" ]; then
    __git_ps1() {
        echo ""
    }
fi

__hg_ps1() {
    hg prompt " (HG:{branch})" 2> /dev/null
}
# set a fancy prompt (non-color, overwrite the one in /etc/profile)
PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '

# Commented out, don't overwrite xterm -T "title" -n "icontitle" by default.
# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*|screen*)
    PS1='${debian_chroot:+($debian_chroot)}\[\033[${USERCOLOR}\u@\h\[\033[00m\]: \[\033[01;34m\]\w\[\e[1;33m\]$(__git_ps1 " (%s)")$(__hg_ps1)\[\e[1;34m\]\[\033[00m\]
\$ '
    PROMPT_COMMAND='echo -ne "\033]0;${USER}@${HOSTNAME}: ${PWD}\007"'
    ;;
*)
    ;;
esac
