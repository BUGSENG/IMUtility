#!/bin/sh

set -eu

cd "$(dirname "$0")"

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
. ./action.settings

curl "${eclairReportUrlPrefix}/ext/update_pull_request" \
-F "wtoken=${wtoken}" \
-F "artifactsDir=${artifactsDir}" \
-F "subDir=${subDir}" \
-F "jobId=${jobId}" \
-F "jobHeadline=${jobHeadline}" \
-F "baseCommitId=${baseCommitId}" \
-F "db=@${analysisOutputDir}/PROJECT.ecd" \
>"${updateYml}"

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
    curl --request POST \
        "${gitlabApiUrl}/projects/${CI_PROJECT_ID}/merge_requests/${pullRequestId}/notes" \
        -H "PRIVATE-TOKEN: ${gitlabBotToken}" \
        -F "body=<${summaryTxtFile}" \
        --silent
    ;;
*) ;;
esac

