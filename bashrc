if [ -f /etc/bash.bashrc ]; then
    # Debian based distributions
    . /etc/bash.bashrc
elif [ -f /etc/bashrc ]; then
    # RedHat Based distributions
    . /etc/bashrc
fi

# Source any files found under ~/.bashrc.d
if [ -d ~/.bashrc.d ]; then
    for f in $(ls ~/.bashrc.d/*.sh); do
        . ${f}
    done
fi
