#!/bin/sh

set -eu

cd "$(dirname "$0")"

gzip -c out/reports.sarif | base64 -w0 >reports.sarif.gz.b64

gh api --method POST -H "Accept: application/vnd.github+json" \
    /repos/"${GITHUB_REPOSITORY}"/code-scanning/sarifs \
    -f commit_sha="${GITHUB_SHA}" -f ref="${GITHUB_REF}" -F sarif=@reports.sarif.gz.b64
