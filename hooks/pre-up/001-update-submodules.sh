#!/bin/sh
# vim: ts=4 sts=4 et

if [ "${UPDATE_SUBMODULES:-0}" != "1" ]; then
    exit 1
fi

UNTRACKED_FILES=$(git status --porcelain 2>/dev/null| grep -c "^ M")

if [ "$UNTRACKED_FILES" -eq 1 ]; then
    echo "The are files with uncommited changes."
    echo "Please commit those first before updating the Vim bundles."
    exit 1
fi

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
DOTFILES_DIR=$(cd "${SCRIPT_DIR}" && cd ../../ && pwd)

cd "${DOTFILES_DIR}"

for submodule in $(LC_ALL=C git submodule | awk '{ print $2 }'); do

    if [ "${submodule}" = "" ]; then
        # This shouldn't happend, but...
        continue
    fi

    echo ">>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "Processing ${submodule}"
    echo "--------------------------------------------------------"
    cd "${submodule}"

    git pull

    if [ -f ./.gitmodules ]; then
        echo "Git submodules detected, updating..."
        git submodule update --init --recursive
    fi

    if [ "$(git remote | grep upstream)" != "" ]; then
        branch=$(git branch | grep '*' | awk '{ print $2 }')
        git pull upstream "$branch"
        git push rw-origin || git push
    fi
    cd "${DOTFILES_DIR}"
    git commit -am "Updated to latest ${submodule}"
    echo "<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
done
