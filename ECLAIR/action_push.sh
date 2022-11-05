#!/bin/sh

set -eu

cd "$(dirname "$0")"

usage() {
    echo "Usage: $0 WTOKEN ANALYSIS_OUTPUT_DIR COMMIT_ID" >&2
    exit 2
}

[ $# -eq 3 ] || usage

wtoken=$1
analysisOutputDir=$2
commitId=$3

# Source variables
. ./action.settings

curl -sS "${eclairReportUrlPrefix}/ext/update_push" \
-F "wtoken=${wtoken}" \
-F "artifactsDir=${artifactsDir}" \
-F "subDir=${subDir}" \
-F "jobId=${jobId}" \
-F "jobHeadline=${jobHeadline}" \
-F "commitId=${commitId}" \
-F "badgeLabel=${badgeLabel}" \
-F "db=@${analysisOutputDir}/PROJECT.ecd" \
>"${updateYml}"

summary

case ${ci} in
github)
    gh api \
        --method POST \
        "/repos/${repository}/commits/${commitId}/comments" \
        -F "body=@${summaryTxtFile}" \
        --silent
    ;;
gitlab)
    curl -sS --request POST \
        "${gitlabApiUrl}/projects/${CI_PROJECT_ID}/repository/commits/${CI_COMMIT_SHA}/comments" \
        -H "PRIVATE-TOKEN: ${gitlabBotToken}" \
        -F "note=<${summaryTxtFile}"
    ;;
*) ;;
esac
