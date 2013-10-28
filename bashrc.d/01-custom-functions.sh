# vim: ts=4 sts=4 et
# Disable posix mode which disallows -(dashes) in function names.
set +o posix

new-git-branch() {
    branch="$1"
    git branch "${branch}" && (git push --set-upstream origin "${branch}" || git push origin "${branch}") && git checkout "${branch}"
}

develop() {
    venv_name=${1:-Py27}
    venv_activate_bin=~/projects/.virtualenvs/${venv_name}/bin/activate
    if [ ! -f $venv_activate_bin ]; then
        echo "No virtualenv by the name \"${venv_name}\" was found!"
        return 1
    fi
    . ${venv_activate_bin}
}

__existing_virtualenvs() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    VENVS_DIR=~/projects/.virtualenvs
    VENVS=$(ls $VENVS_DIR)
    COMPREPLY=( $(compgen -W "${VENVS}" -- $cur) )
}
complete -F __existing_virtualenvs develop

killpymatch() {
    pid=$(ps aux | grep python | grep "$1" | awk '{print $2}')
    if [ "x$pid" != "x" ]; then
        echo "Killing match of $1 with pid $pid"
        kill -KILL $pid
    else
        echo "No process matching '$1' found"
    fi
}

killpymatch-term() {
    pid=$(ps aux | grep python | grep "$1" | awk '{print $2}')
    if [ "x$pid" != "x" ]; then
        echo "Killing -TERM match of $1 with pid $pid"
        kill -TERM $pid
    else
        echo "No process matching '$1' found"
    fi
}

function duf {
    du -sk "$@" | sort -n | while read size fname; do for unit in k M G T P E Z Y; do if [ $size -lt 1024 ]; then echo -e "${size}${unit}\t${fname}"; break; fi; size=$((size/1024)); done; done
}

clean-vim-tempfiles() {
    local SEARCH_PATH="$1"
    if [ "x${SEARCH_PATH}" = "x" ]; then
        echo "The path to search for vim swap files was not passed"
        return 1
    fi
    for fname in $(find $1 -type f -name "*.*.sw*" 2>/dev/null); do
        if [ "x$(file $fname | grep -i 'Vim swap file')" != "x" ]; then
            rm -f $fname
        fi
    done
}

clean-pyc-files() {
    local SEARCH_PATH="$1"
    if [ "x${SEARCH_PATH}" = "x" ]; then
        echo "The path to search for vim swap files was not passed"
        return 1
    fi
    for fname in $(find $1 -type f -name "*.pyc" 2>/dev/null); do
        if [ "x$(file $fname | grep -i 'byte-compiled')" != "x" ]; then
            rm -f $fname
        fi
    done
}

ssh-null() {
    ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oControlPath=none $@
}

HOP_PARSING_CODE="import sys
import socket

output = []
ssh_command = sys.argv[1]

for hop in sys.argv[2:-1]:
    port = '22'
    if ':' in hop:
        hop, port = hop.split(':')

    user = None
    if '@' in hop:
        user, hop = hop.split('@')
    try:
        hop = socket.gethostbyname(hop.strip())
    except socket.gaierror as exc:
        pass
    output.extend([
        ssh_command, '-A', '-t', '-p', port,
        user and '{0}@{1}'.format(user, hop) or hop
    ])

port = '22'
last_hop = sys.argv[-1]
if ':' in last_hop:
    last_hop, port = last_hop.split(':')
user = None
if '@' in last_hop:
    user, last_hop = last_hop.split('@')
try:
    last_hop = socket.gethostbyname(last_hop.strip())
except socket.gaierror:
    pass
output.extend([
    ssh_command, '-A', '-p', port,
    user and '{0}@{1}'.format(user, last_hop) or last_hop
])
print ' '.join(output)
"

ssh-hop() {
    ssh_binary="/usr/bin/ssh"
    ssh_command=$(python -c "$HOP_PARSING_CODE" "$ssh_binary" $@)
    echo $ssh_command
    eval $ssh_command
}

ssh-null-hop() {
    ssh_binary="/usr/bin/ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oControlPath=none"
    ssh_command=$(python -c "$HOP_PARSING_CODE" "$ssh_binary" $@)
    echo $ssh_command
    eval $ssh_command
}

# Enable posix mode which disallows -(dashes) in function names.
set -o posix
