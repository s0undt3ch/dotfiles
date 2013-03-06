# Source any files found under ~/.bashrc.d
if [ -d ~/.bashrc.d ]; then
    for f in $(ls ~/.bashrc.d); do
        . ~/.bashrc.d/${f}
    done
fi
