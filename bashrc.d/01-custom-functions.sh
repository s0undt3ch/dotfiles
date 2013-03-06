new-git-branch() {
    branch="$1"
    git branch "${branch}" && git push origin "${branch}" && git checkout "${branch}"
}

develop() {
    . /home/vampas/projects/.vp_installs/PY-2.7/bin/activate
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
