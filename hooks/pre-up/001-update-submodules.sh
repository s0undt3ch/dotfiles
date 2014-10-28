# vim: ts=4 sts=4 et

if [ "${UPDATE_SUBMODULES:-0}" != "1" ]; then
    exit 1
fi

UNTRACKED_FILES=$(git status --porcelain 2>/dev/null| grep "^ M" | wc -l)

if [ $UNTRACKED_FILES -eq 1 ]; then
    echo "The are files with uncommited changes."
    echo "Please commit those first before updating the Vim bundles."
    exit 1
fi

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
DOTFILES_DIR=$(cd "${SCRIPT_DIR}" && cd ../../ && pwd)

cd "${DOTFILES_DIR}"

for submodule in $(LC_ALL=C git submodule | awk '{ print $2}'); do
    echo "Processing ${submodule}"
    cd "${submodule}"
    if [ "$(git submodule)" != "" ]; then
        git submodule update --init --recursive
    fi
    git pull -u

    if [ "$(git submodule)" != "" ]; then
        git submodule update --init --recursive
    fi

    if [ "$(git remote | grep upstream)" != "" ]; then
        branch=$(git branch | grep '*' | awk '{ print $2 }')
        git pull upstream $branch
        git push
    fi
    cd "${DOTFILES_DIR}"
    git commit -am "Updated to latest ${submodule}"
done
