#!/bin/sh

set -e

cd "$(dirname "$0")"

usage() {
    echo "Usage: $0 ANALYSIS_OUTPUT_DIR COMMIT_ID" >&2
    exit 2
}

[ $# -eq 2 ] || usage

# Source variables
. ./action.settings

analysis_output_dir=$1
commit_id=$2

current_job_dir=${eclair_report_host_scp}${artifacts_dir}/${branch}/${job_id}

# create a directory for the analysis artifacts
${eclair_report_host_sh} "mkdir -p '${current_job_dir}'"

# Transfer the database to eclair_report_host
scp "${analysis_output_dir}/PROJECT.ecd" "${current_job_dir}"

# Send the scripts to eclair report host
scp update_push.sh \
    "${eclair_report_host_scp}${current_job_dir}"

# Execute it on that host
${eclair_report_host_sh} "${current_job_dir}/update_push.sh \
'${ci}' '${eclair_report_url_prefix}' '${artifacts_dir}' '${job_id}' '${job_headline}' \
'${commit_id}' '${branch}' '${badge_label}'" \
    >"${job_summary_file}"
