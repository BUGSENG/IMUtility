#!/bin/sh

set -e

cd "$(dirname "$0")"

usage() {
    echo "Usage: $0 ANALYSIS_OUTPUT_PATH" >&2
    exit 2
}

[ $# -eq 1 ] || usage

ANALYSIS_OUTPUT_PATH=$1

# Set variables
#ECLAIR_REPORT_USER="github"
ECLAIR_REPORT_HOST="eclairit.com:3787"
ECLAIR_REPORT_HOST_SCP=""
ECLAIR_REPORT_HOST_SH="sh -c"
ARTIFACTS_ROOT="/home/github/public"
PROJECT_PATH="${GITHUB_REPOSITORY}"
JOB_ID="${GITHUB_RUN_NUMBER}"

PROJECT_ARTIFACTS_PATH="${ARTIFACTS_ROOT}/${PROJECT_PATH}"'.ecdf'

# create a directory for the analysis results
${ECLAIR_REPORT_HOST_SH} "mkdir -p ${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/"
# Transfer the database to eclair_report_host
scp "${ANALYSIS_OUTPUT_PATH}/PROJECT.ecd" "${ECLAIR_REPORT_HOST_SCP}${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/"

# Send the script to tag databases, create symlinks and badges
scp update.sh "${ECLAIR_REPORT_HOST_SCP}${PROJECT_ARTIFACTS_PATH}"
# Execute it on that host
if [ "${IS_PR}" = 'true' ]; then
    ${ECLAIR_REPORT_HOST_SH} "ECLAIR_REPORT_HOST=${ECLAIR_REPORT_HOST} \
${PROJECT_ARTIFACTS_PATH}/update_pr_github.sh \
${PROJECT_ARTIFACTS_PATH} ${JOB_ID} ${GITHUB_REPOSITORY} ${GITHUB_SHA} ${PR_BASE_SHA}" \
        >>"${GITHUB_STEP_SUMMARY}"
else
    ${ECLAIR_REPORT_HOST_SH} "ECLAIR_REPORT_HOST=${ECLAIR_REPORT_HOST} \
${PROJECT_ARTIFACTS_PATH}/update.sh \
${PROJECT_ARTIFACTS_PATH} ${JOB_ID} ${GITHUB_REPOSITORY} ${GITHUB_SHA}" \
        >>"${GITHUB_STEP_SUMMARY}"
fi
