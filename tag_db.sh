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

PROJECT_PATH="${GITHUB_REPOSITORY}"
JOB_ID="${GITHUB_RUN_NUMBER}"

ARTIFACTS_ROOT="/home/github/public"
PROJECT_ARTIFACTS_PATH="${ARTIFACTS_ROOT}/${PROJECT_PATH}"'.ecdf'

ECD_DESTINATION="${ECLAIR_REPORT_HOST_SCP}${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/"
if [ "${IS_PR}" = 'true' ]; then
    # create a (pr) directory for the analysis results
    ${ECLAIR_REPORT_HOST_SH} "mkdir -p ${PROJECT_ARTIFACTS_PATH}/pr/${JOB_ID}/"
    ECD_DESTINATION="${ECLAIR_REPORT_HOST_SCP}${PROJECT_ARTIFACTS_PATH}/pr/${JOB_ID}/"
else
    # create a directory for the analysis results
    ${ECLAIR_REPORT_HOST_SH} "mkdir -p ${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/"
fi
# Transfer the database to eclair_report_host
scp "${ANALYSIS_OUTPUT_PATH}/PROJECT.ecd" "${ECD_DESTINATION}"

# Send the script to tag databases, create symlinks and badges
scp update.sh update_pr_github.sh "${ECLAIR_REPORT_HOST_SCP}${PROJECT_ARTIFACTS_PATH}"
# Execute it on that host
if [ "${IS_PR}" = 'true' ]; then
    # Extract PR number from "refs/pull/<prnum>/merge"
    PR_NUMBER=$(echo "${GITHUB_REF_NAME}" | cut -d / -f 3)
    ${ECLAIR_REPORT_HOST_SH} "ECLAIR_REPORT_HOST=${ECLAIR_REPORT_HOST} \
${PROJECT_ARTIFACTS_PATH}/update_pr_github.sh \
${PROJECT_ARTIFACTS_PATH} ${PR_NUMBER} ${JOB_ID} ${GITHUB_REPOSITORY} ${PR_BASE_SHA}" \
        >>"${GITHUB_STEP_SUMMARY}"
else
    ${ECLAIR_REPORT_HOST_SH} "ECLAIR_REPORT_HOST=${ECLAIR_REPORT_HOST} \
${PROJECT_ARTIFACTS_PATH}/update.sh \
${PROJECT_ARTIFACTS_PATH} ${GITHUB_REF_NAME} ${JOB_ID} ${GITHUB_REPOSITORY} ${GITHUB_SHA}" \
        >>"${GITHUB_STEP_SUMMARY}"
fi
