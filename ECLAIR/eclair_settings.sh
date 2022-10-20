#!/bin/sh

set -e

export CC_ALIASES="gcc"
#export AS_ALIASES="as"
#export AR_ALIASES="ar"
#export LD_ALIASES="ld"

# To be adapted to local setup
PATH=/opt/local/bin:${PATH}
ECLAIR_PATH=${ECLAIR_PATH:-/opt/bugseng/eclair/bin/}

case "${ECLAIR_PATH}" in
*/ | "") ;;
*)
    ECLAIR_PATH=${ECLAIR_PATH}/
    ;;
esac

export ECLAIR_PATH
