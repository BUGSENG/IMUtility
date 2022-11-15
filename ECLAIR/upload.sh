#!/bin/sh

set -eu

HERE=$( (
    cd "$(dirname "$0")"
    echo "${PWD}"
))

usage() {
    echo "Usage: $0 SARIF_FILE" >&2
    exit 2
}

[ $# -eq 1 ] || usage

. "${HERE}/action.helpers"

sarif=$1
sarifPack=${HERE}/sarif.gz.b64
uploadLog=${HERE}/upload.log

gzip -c "${sarif}" | base64 -w0 > "${sarifPack}"

ex=0
gh api --method POST -H "Accept: application/vnd.github+json" \
    "/repos/${GITHUB_REPOSITORY}/code-scanning/sarifs" \
    -f "commit_sha=${GITHUB_SHA}" -f "ref=${GITHUB_REF}" \
    -F "sarif=@${sarifPack}" \
    --silent >"${uploadLog}" 2>&1 || ex=$?
maybe_log_file_exit ADD_COMMENT "Adding comment" "${uploadLog}" "${ex}"

