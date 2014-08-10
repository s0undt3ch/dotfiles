#!/bin/sh

SCRIPT_DIR=`cd $(dirname $0) && pwd`

${SCRIPT_DIR}/vim/update-bundles.sh
${SCRIPT_DIR}/libs/update-libs.sh
