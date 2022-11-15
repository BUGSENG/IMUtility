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

curl -sS "${eclairReportUrlPrefix}/ext/update_pull_request" \
    -F "wtoken=${wtoken}" \
    -F "artifactsDir=${artifactsDir}" \
    -F "subDir=${subDir}" \
    -F "jobId=${jobId}" \
    -F "jobHeadline=${jobHeadline}" \
    -F "baseCommitId=${baseCommitId}" \
    -F "db=@${analysisOutputDir}/PROJECT.ecd" \
    >"${updateYml}"
ex=0
grep -Fq "unfixedReports: " "${updateYml}" || ex=$?
maybe_log_file_exit PUBLISH_RESULT "Publishing results" "${updateYml}" "${ex}"

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
    curl -sS --request POST \
        "${gitlabApiUrl}/projects/${CI_PROJECT_ID}/merge_requests/${pullRequestId}/notes" \
        -H "PRIVATE-TOKEN: ${gitlabBotToken}" \
        -F "body=<${summaryTxtFile}" >"${commentJson}"
    ex=0
    grep -Fq "UnfixedReports: " "${commentJson}" || ex=$?
    maybe_log_file_exit ADD_COMMENT "Adding comment" "${commentJson}" "${ex}"
    ;;
*) ;;
esac
