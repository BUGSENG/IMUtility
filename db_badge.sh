#!/bin/sh

set -e

cd "$(dirname "$0")"

# Set variables
#ECLAIR_REPORT_USER="github"
#ECLAIR_REPORT_HOST="eclairit.com"
ECLAIR_REPORT_HOST_SCP=""
ECLAIR_REPORT_HOST_SH="sh -c"
ARTIFACTS_ROOT="/home/github/public"
PROJECT_PATH="${GITHUB_REPOSITORY}"
JOB_ID="${GITHUB_RUN_NUMBER}"
ANALYSIS_OUTPUT_PATH="ECLAIR/out/"
PROJECT_ARTIFACTS_PATH="${ARTIFACTS_ROOT}/${PROJECT_PATH}"'.ecdf'

# create a directory for the analysis results
${ECLAIR_REPORT_HOST_SH} "mkdir -p ${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/"
# Transfer the database to eclair_report_host
scp "${ANALYSIS_OUTPUT_PATH}/PROJECT.ecd" "${ECLAIR_REPORT_HOST_SCP}${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/"

# Send the script to tag databases, create symlinks and badges
scp update.sh "${ECLAIR_REPORT_HOST_SCP}${PROJECT_ARTIFACTS_PATH}"
# Execute it on that host
${ECLAIR_REPORT_HOST_SH} "IS_PR=${IS_PR} BASE_PR_SHA=${BASE_PR_SHA} ${PROJECT_ARTIFACTS_PATH}/update.sh ${PROJECT_ARTIFACTS_PATH} ${JOB_ID} ${GITHUB_SHA}"

# Publish ECLAIR report links
echo "# ECLAIR analysis summary" >>"${GITHUB_STEP_SUMMARY}"
# Previous
echo "[![ECLAIR prev](https://eclairit.com:3787/fs${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/prev/badge.svg)]\
(https://eclairit.com:3787/fs${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/prev/PROJECT.ecd)" >>"${GITHUB_STEP_SUMMARY}"
# Current
echo "[![ECLAIR current](https://eclairit.com:3787/fs${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/badge.svg)]\
(https://eclairit.com:3787/fs${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/PROJECT.ecd)" >>"${GITHUB_STEP_SUMMARY}"
# Next (missing)
echo "[![ECLAIR next](https://eclairit.com:3787/fs${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/next/badge.svg)]\
(https://eclairit.com:3787/fs${PROJECT_ARTIFACTS_PATH}/${JOB_ID}/next/PROJECT.ecd)" >>"${GITHUB_STEP_SUMMARY}"
