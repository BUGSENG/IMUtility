#!/bin/sh

set -eu

HERE=$( (
    cd "$(dirname "$0")"
    echo "${PWD}"
))

. "${HERE}/eclair_settings.sh"

sarif=${HERE}/reports.sarif.gz.b64

gzip -c "${ECLAIR_REPORTS_SARIF}" | base64 -w0 > "${sarif}"

gh api --method POST -H "Accept: application/vnd.github+json" \
    "/repos/${GITHUB_REPOSITORY}/code-scanning/sarifs" \
    -f "commit_sha=${GITHUB_SHA}" -f "ref=${GITHUB_REF}" -F "sarif=@${sarif}"
