# Disable posix mode which disallows -(dashes) in function names.
set +o posix

new-git-branch() {
    branch="$1"
    git branch "${branch}" && (git push --set-upstream origin "${branch}" || git push origin "${branch}") && git checkout "${branch}"
}

develop() {
	echo "1"
    . ~/projects/.virtualenvs/Py27/bin/activate
	echo "2"
}

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

ssh-hop() {
    ssh_binary="ssh"
    ssh_command="ssh -A -t $1"
    shift
    for item in ${@:1}; do
        ssh_command="${ssh_command} ssh -A -t ${item}"
    done
    echo $ssh_command
    $($ssh_command)
}

ssh-null-hop() {
    ssh_binary="ssh -oStrictHostKeyChecking=no -oUserKnownHostsFile=/dev/null -oControlPath=none"
    ssh_command="${ssh_binary} -A -t $1"
    shift
    for item in ${@:1}; do
        ssh_command="${ssh_command} ${ssh_binary} -A -t ${item}"
    done
    echo $ssh_command
    $($ssh_command)
}

# Enable posix mode which disallows -(dashes) in function names.
set -o posix
