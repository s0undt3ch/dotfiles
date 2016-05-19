# vim: ts=4 sts=4 et
# Disable posix mode which disallows -(dashes) in function names.
#set +o posix

function new-git-branch() {
    branch="$1"
    git branch "${branch}" && (git push --set-upstream origin "${branch}" || git push origin "${branch}") && git checkout "${branch}"
}

#__branch_completion() {
#    local cur="${COMP_WORDS[COMP_CWORD]}"
#    __gitcomp_nl "$(__git_heads)"
#}
#complete -F __branch_completion new-git-branch


function killpymatch() {
    pids=$(ps aux | grep python | grep "$1" | awk '{print $2}')
    if [ "x$pids" != "x" ]; then
        echo "Killing -TERM match of $1 with pid(s) ${pids//[[:space:]]/ }"
        for pid in $(echo $pids); do
            kill -KILL $pid
        done
    else
        echo "No process matching '$1' found"
    fi
}

function killpymatch-term() {
    pids=$(ps aux | grep python | grep "$1" | awk '{print $2}')
    if [ "x$pids" != "x" ]; then
        echo "Killing -TERM match of $1 with pid(s) ${pids//[[:space:]]/ }"
        for pid in $(echo $pids); do
            kill -TERM $pid
        done
    else
        echo "No process matching '$1' found"
    fi
}

function duf {
    du -sk "$@" | sort -n | while read size fname; do for unit in k M G T P E Z Y; do if [ $size -lt 1024 ]; then echo -e "${size}${unit}\t${fname}"; break; fi; size=$((size/1024)); done; done
}

function clean-vim-tempfiles() {
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

function clean-pyc-files() {
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

function ssh-null() {
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
print(' '.join(output))
"

function ssh-hop() {
    ssh_binary="/usr/bin/ssh"
    ssh_command=$(python -c "$HOP_PARSING_CODE" "$ssh_binary" $@)
    echo $ssh_command
    eval $ssh_command
}

function ssh-null-hop() {
    ssh_binary="/usr/bin/ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oControlPath=none"
    ssh_command=$(python -c "$HOP_PARSING_CODE" "$ssh_binary" $@)
    echo $ssh_command
    eval $ssh_command
}

function rdesktop-shortcut() {
    echo "Running: rdesktop -g 1820x1000 -k pt -z -r sound:local -x l -P $@"
    rdesktop -g 1820x1000 -k pt -z -r sound:local -x l -P $@
}

function rdesktop-wide-shortcut() {
    echo "Running: rdesktop -g 3820x1980 -k pt -z -r sound:local -x l -P $@"
    rdesktop -g 3820x1980 -k pt -z -r sound:local -x l -P $@
}
# Enable posix mode which disallows -(dashes) in function names.
#set -o posix
