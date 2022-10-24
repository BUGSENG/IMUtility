#!/bin/bash

set -e

# To be adjusted to local setup
ECLAIR_PATH=${ECLAIR_PATH:-/opt/bugseng/eclair/bin/}
eclair_report="${ECLAIR_PATH}eclair_report"

usage() {
    echo "Usage: $0 RESULTS_ROOT JOB_ID JOB_HEADLINE COMMIT_ID" >&2
    exit 2
}

[[ $# -eq 4 ]] || usage

results_root=$1
current_job_id=$2
job_headline=$3
commit_id=$4

current_dir=${results_root}/${current_job_id}
current_db=${current_dir}/PROJECT.ecd
commits_dir=${results_root}/commits

mkdir -p "${commits_dir}"

# The group where eclair_report runs must be in this file's group
chmod g+w "${current_db}"

last_dir=${results_root}/last
last_job_id=
[[ ! -d "${last_dir}" ]] || last_job_id=$(basename "$(realpath "${last_dir}")")

if [[ -n "${last_job_id}" ]]; then
    last_db=${last_dir}/PROJECT.ecd

    # Tag previous and current databases
    ${eclair_report} -setq=diff_tag_domain1,next -setq=diff_tag_domain2,prev \
        -tag_diff="'${last_db}','${current_db}'"

    # Count reports
    fixed_reports=$(${eclair_report} -db="${last_db}" -sel_tag_glob=diff_next,next,missing '-print="",reports_count()')
    echo "${fixed_reports}" >"${current_dir}/fixed_reports.txt"
    new_reports=$(${eclair_report} -db="${current_db}" -sel_tag_glob=diff_prev,prev,missing '-print="",reports_count()')
    echo "${new_reports}" >"${current_dir}/new_reports.txt"

    # Generate badge for the current run
    anybadge -o --label="ECLAIR" --value="fixed ${fixed_reports} | new ${new_reports}" --file="${current_dir}/badge.svg"

    # Add link to previous run of current run
    ln -s "../${last_job_id}" "${current_dir}/prev"

    # Add link to next run of last run
    ln -s "../${current_job_id}" "${last_dir}/next"

else
    new_reports=$(${eclair_report} -db="${current_db}" '-print="",reports_count()')
    anybadge -o --label="ECLAIR ${current_job_id}" --value="reports: ${new_reports}" --file="${current_dir}/badge.svg"
    # Write report count to file
    echo "${new_reports}" >"${results_root}/${current_job_id}/new_reports.txt"
fi

# Update last symlink
ln -sfn "${current_job_id}" "${results_root}/last"

# Add a link relating commit id to last build done for it
ln -sfn "${current_job_id}" "${commits_dir}/${commit_id}"

# Generate summary and print it
ECLAIR_REPORT_HOST="eclairit.com" # TODO: pass this as a variable
{
    echo "# ECLAIR analysis summary:"
    printf "Fixed reports: %d\n" "${fixed_reports}"
    printf "New reports: %d\n" "${new_reports}"
    echo "[Browse analysis](https://${ECLAIR_REPORT_HOST}:3787/fs${current_dir}/index.html)"
    echo "*****************************************************"
} >>"${current_dir}/summary.txt"
cat "${current_dir}/summary.txt"

# Generate a file index.html to browse the analysis
generate_index() {
    local prev_dir
    local next_dir
    local index_file
    local previous_db
    local fs

    fs="/fs"
    prev_dir="${fs}${current_dir}/prev"
    next_dir="${fs}${current_dir}/next"
    index_file="${current_dir}/index.html"
    previous_db="${fs}${prev_dir}/PROJECT.ecd"

    {
        echo "<!DOCTYPE html>"
        echo "<html lang=\"en\">"
        echo "<head>"
        echo "<meta charset=\"utf-8\">"
        echo "<title>${job_headline}: ECLAIR job #${current_job_id}</title>"
        echo "</head>"
        echo "<body>"
        echo "<h1>ECLAIR job #${current_job_id} for ${job_headline}</h1>"

        if [[ -d ${prev_dir} ]]; then
            echo "<p>Fixed reports: ${fixed_reports} (<a href=\"${previous_db}\">previous database</a>)</p>"
            echo "<p>New reports: ${new_reports} (<a href=\"${current_db}\">current database</a>)</p>"
        fi

        echo "<hr>"

        echo "<p>"
        if [[ -d ${prev_dir} ]]; then
            echo "<a href=\"${prev_dir}/index.html\">Previous job</a>"
            echo ", "
        fi
        echo "<a href=\"${next_dir}/index.html\">Next job</a>"
        if [[ -d ${prev_dir} ]]; then
            echo ", "
            echo "<a href=\"${results_root}\">Jobs</a>"
        fi
        echo "</p>"

        echo "</body>"
        echo "</html>"

    } >>"${index_file}"
}

generate_index
