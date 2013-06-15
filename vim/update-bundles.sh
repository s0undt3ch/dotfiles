#!/bin/sh

SCRIPT_DIR=`cd $(dirname $0) && pwd`
BUNDLE_DIR="${SCRIPT_DIR}/bundle"
cd ${BUNDLE_DIR}

BUNDLES=$(ls $BUNDLE_DIR)
for bundle in $BUNDLES; do
    [ ! -d $bundle ] && continue
    echo "Processing $bundle"
    cd $bundle
    git pull -u
    cd ../../
    git commit -am "Updated to latest vim/bundle/$bundle"
    cd $BUNDLE_DIR
done
exit
