#!/bin/sh

UNTRACKED_FILES=$(git status --porcelain 2>/dev/null| grep "^ M" | wc -l)

if [ $UNTRACKED_FILES -eq 1 ]; then
    echo "The are files with uncommited changes. Please commit those first before updating the Vim bundles."
    exit 1
fi

SCRIPT_DIR=`cd $(dirname $0) && pwd`
BUNDLE_DIR="${SCRIPT_DIR}/bundle"
cd ${BUNDLE_DIR}

BUNDLES=$(ls $BUNDLE_DIR)
for bundle in $BUNDLES; do
    [ ! -d $bundle ] && continue
    echo "Processing $bundle"
    cd $bundle
    git pull -u
    if [ "$(git remote | grep upstream)" != "" ]; then
        branch=$(git branch | grep '*' | awk '{ print $2 }')
        git pull upstream $branch
        git push
    fi
    cd ../../
    git commit -am "Updated to latest vim/bundle/$bundle"
    cd $BUNDLE_DIR
done
exit
