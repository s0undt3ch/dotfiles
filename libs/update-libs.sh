#!/bin/sh

UNTRACKED_FILES=$(git status --porcelain 2>/dev/null| grep "^ M" | wc -l)

if [ $UNTRACKED_FILES -eq 1 ]; then
    echo "The are files with uncommited changes. Please commit those first before updating the libs submodules."
    #exit 1
fi

SCRIPT_DIR=`cd $(dirname $0) && pwd`
cd ${SCRIPT_DIR}

LIBS=$(ls $SCRIPT_DIR)
for lib in $LIBS; do
    [ ! -d $lib ] && continue
    echo "Processing $lib"
    cd $lib
    git pull -u
    cd ../../
    git commit -am "Updated to latest libs/$bundle"
    cd $SCRIPT_DIR
done

if [ ! -L ${SCRIPT_DIR}/pyenv/plugins/pyenv-virtualenv ]; then
    cd ${SCRIPT_DIR}/pyenv/plugins
    ln -sf ../../pyenv-virtualenv/ .
fi

if [ ! -L ${SCRIPT_DIR}/pyenv/plugins/pyenv-virtualenvwrapper ]; then
    cd ${SCRIPT_DIR}/pyenv/plugins
    ln -sf ../../pyenv-virtualenvwrapper/ .
fi

exit
