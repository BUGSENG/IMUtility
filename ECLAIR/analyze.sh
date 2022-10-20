#!/bin/sh

set -e

HERE=$( (
    cd "$(dirname "$0")"
    echo "${PWD}"
))

# shellcheck source=./eclair_settings.sh
. "${HERE}/eclair_settings.sh"

TOP=${HERE%/*}
export ECLAIR_PROJECT_NAME="${TOP##*/}"
export ECLAIR_PROJECT_ROOT="${TOP}"

export ECLAIR_OUTPUT_DIR="${HERE}/out"
export ECLAIR_DATA_DIR="${HERE}/.data"
export ECLAIR_WORKSPACE="${ECLAIR_DATA_DIR}/eclair_workspace"

rm -rf "${ECLAIR_OUTPUT_DIR}" "${ECLAIR_DATA_DIR}"
mkdir -p "${ECLAIR_OUTPUT_DIR}" "${ECLAIR_DATA_DIR}"

../clean.sh
"${ECLAIR_PATH}eclair_env" "-eval_file='${HERE}/analysis.ecl'" -- ../build.sh

"${ECLAIR_PATH}eclair_report" "-eval_file='${HERE}/report.ecl'"
