#!/bin/sh

set -e

cd "$(dirname "$0")"

usage() {
    echo "Usage: $0 ANALYSIS_OUTPUT_PATH COMMIT_ID" >&2
    exit 2
}

[ $# -eq 2 ] || usage

# Source variables
. ./eclair_action.settings

# Set this script's variables (using those defined in the .settings file)
analysis_output_path="$1"
commit_id="$2"

project_actifacts_path=${ARTIFACTS_ROOT}/${REPOSITORY}'.ecdf'
# These two variables are passed as env variables from the .yml file
# Thus, they are either defined or the empty string
pr_base_commit_id=${PR_BASE_COMMIT_ID}
pr_headline=${PR_HEADLINE}

ecd_destination=${ECLAIR_REPORT_HOST_SCP}${project_actifacts_path}/${BRANCH}/${JOB_ID}/
if [ "${IS_PR}" = 'true' ]; then
    # create a (pr) directory for the analysis results
    ${ECLAIR_REPORT_HOST_SH} "mkdir -p ${project_actifacts_path}/pr/${JOB_ID}/"
    ecd_destination=${ECLAIR_REPORT_HOST_SCP}${project_actifacts_path}/pr/${JOB_ID}/
else
    # create a directory for the analysis results
    ${ECLAIR_REPORT_HOST_SH} "mkdir -p ${project_actifacts_path}/${BRANCH}/${JOB_ID}/"
fi
# Transfer the database to eclair_report_host
scp "${analysis_output_path}/PROJECT.ecd" "${ecd_destination}"

# Send the scripts to eclair report host
scp "${UPDATE_SCRIPTS_PATH}/update_push.sh" \
    "${UPDATE_SCRIPTS_PATH}/update_pull_request.sh" \
    "${ECLAIR_REPORT_HOST_SCP}${project_actifacts_path}"
# Execute it on that host
{
    if [ "${IS_PR}" = 'true' ]; then
        ${ECLAIR_REPORT_HOST_SH} "ANALYSIS_HOST=${ECLAIR_REPORT_HOST_PREFIX} \
${project_actifacts_path}/update_pr_github.sh \
'${CI}' '${project_actifacts_path}' '${JOB_ID}' '${REPOSITORY}' \
'${PR_ID}' '${pr_base_commit_id}' '${pr_headline}' "
    else
        ${ECLAIR_REPORT_HOST_SH} "ANALYSIS_HOST=${ECLAIR_REPORT_HOST_PREFIX} \
${project_actifacts_path}/update.sh \
'${CI}' '${project_actifacts_path}' '${BRANCH}' '${BADGE_LABEL}' \
'${JOB_ID}' '${REPOSITORY}' '${commit_id}'"
    fi

} >>"${GITHUB_STEP_SUMMARY}"
