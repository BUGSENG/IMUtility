#!/bin/sh

set -eu

HERE=$( (
    cd "$(dirname "$0")"
    echo "${PWD}"
))

. "${HERE}/eclair_settings.sh"

sarif=${HERE}/reports.sarif.gz.b64
uploadLog=${HERE}/upload.log

gzip -c "${ECLAIR_REPORTS_SARIF}" | base64 -w0 > "${sarif}"

ex=0
gh api --method POST -H "Accept: application/vnd.github+json" \
    "/repos/${GITHUB_REPOSITORY}/code-scanning/sarifs" \
    -f "commit_sha=${GITHUB_SHA}" -f "ref=${GITHUB_REF}" \
    -F "sarif=@${sarif}" \
    --silent >"${uploadLog}" 2>&1 || ex=$?
maybe_log_file_exit ADD_COMMENT "Adding comment" "${commentLog}" "${ex}"

