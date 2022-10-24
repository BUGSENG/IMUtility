#!/bin/sh

set -e

# To be adjusted to local setup
ECLAIR_PATH=${ECLAIR_PATH:-/opt/bugseng/eclair/bin/}
eclair_report="${ECLAIR_PATH}eclair_report"

usage() {
    echo "Usage: $0 RESULTS_ROOT JOB_ID COMMIT_ID" >&2
    exit 2
}

[ $# -eq 3 ] || usage

results_root=$1
current_job_id=$2
commit_id=$3

current_dir="${results_root}/${current_job_id}"
current_db="${current_dir}/PROJECT.ecd"

# The group where eclair_report runs must be in this file's group
chmod g+w "${current_db}"

last_dir="${results_root}/last"
last_job_id=
[ ! -d "${last_dir}" ] || last_job_id=$(basename "$(realpath "${last_dir}")")

if [ -n "${last_job_id}" ]; then
    last_db="${last_dir}/PROJECT.ecd"
    last_new_reports=$(cat "${last_dir}/new_reports.txt")
    previous_dir="${last_dir}/prev"
    previous_job_id=
    [ ! -d "${previous_dir}" ] || previous_job_id=$(basename "$(realpath "${previous_dir}")")

    # Tag previous and current databases
    ${eclair_report} -setq=diff_tag_domain1,next -setq=diff_tag_domain2,prev \
        -tag_diff="'${last_db}','${current_db}'"

    # Count reports
    fixed_reports=$(${eclair_report} -db="${last_db}" -sel_tag_glob=diff_next,next,missing '-print="",reports_count()')
    echo "${fixed_reports}" >"${current_dir}/fixed_reports.txt"
    new_reports=$(${eclair_report} -db="${current_db}" -sel_tag_glob=diff_prev,prev,missing '-print="",reports_count()')
    echo "${new_reports}" >"${current_dir}/new_reports.txt"

    # Generate badge for the current run
    anybadge -o --label="eclair #${current_job_id}" --value="not in #${last_job_id}: ${new_reports}" --file="${current_dir}/badge.svg"
    # Modify the badge of the previous run
    if [ -n "${previous_job_id}" ]; then
        msg="not in #${previous_job_id}: ${last_new_reports}"
    else
        msg="reports: ${last_new_reports}"
    fi
    anybadge -o --label="eclair #${last_job_id}" \
        --value="${msg}, not in #${current_job_id}: ${fixed_reports}" --file="${last_dir}/badge.svg"

    # Add link to previous run of current run
    ln -s "../${last_job_id}" "${current_dir}/prev"

    # Add link to next run of last run
    ln -s "../${current_job_id}" "${last_dir}/next"

else
    new_reports=$(${eclair_report} -db="${current_db}" '-print="",reports_count()')
    anybadge -o --label="eclair ${current_job_id}" --value="reports: ${new_reports}" --file="${current_dir}/badge.svg"
    # Write report count to file
    echo "${new_reports}" >"${results_root}/${current_job_id}/new_reports.txt"
fi

# Update last symlink
ln -sfn "${current_job_id}" "${results_root}/last"

# Add a link relating commit id to last build done for it
ln -sfn "${current_job_id}" "${results_root}/${commit_id}"
