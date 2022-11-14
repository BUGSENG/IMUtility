#!/bin/sh

set -eu

usage() {
    echo "Usage: $0 WTOKEN ANALYSIS_OUTPUT_DIR COMMIT_ID BASE_COMMIT_ID" >&2
    exit 2
}

[ $# -eq 4 ] || usage

wtoken=$1
analysisOutputDir=$2
#commitId=$3
baseCommitId=$4

# Source variables
. "$(dirname "$0")/action.settings"

if ! curl -sS --fail-with-body "${eclairReportUrlPrefix}/ext/update_pull_request" \
    -F "wtoken=${wtoken}" \
    -F "artifactsDir=${artifactsDir}" \
    -F "subDir=${subDir}" \
    -F "jobId=${jobId}" \
    -F "jobHeadline=${jobHeadline}" \
    -F "baseCommitId=${baseCommitId}" \
    -F "db=@${analysisOutputDir}/PROJECT.ecd" \
    >"${updateYml}"; then
    cat "${updateYml}"
    exit 1
fi

summary

case ${ci} in
github)
    gh api \
        --method POST \
        "/repos/${repository}/issues/${pullRequestId}/comments" \
        -F "body=@${summaryTxtFile}" \
        --silent
    ;;
gitlab)
    curl -sS --fail-with-body --request POST \
        "${gitlabApiUrl}/projects/${CI_PROJECT_ID}/merge_requests/${pullRequestId}/notes" \
        -H "PRIVATE-TOKEN: ${gitlabBotToken}" \
        -F "body=<${summaryTxtFile}"
    ;;
*) ;;
esac
