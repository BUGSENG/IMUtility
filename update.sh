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

current_dir="${results_root}/${current_job_id}"
current_db="${current_dir}/PROJECT.ecd"
current_index="${current_dir}/index.html"
commits_dir="${results_root}/commits"

mkdir -p "${commits_dir}"

# The group where eclair_report runs must be in this file's group
chmod -R g+w "${current_db}"

last_dir=${results_root}/last
last_job_id=
[[ ! -d "${last_dir}" ]] || last_job_id=$(basename "$(realpath "${last_dir}")")

# Generate a file index.html to browse the analysis
generate_index() {

    local current_dir
    local prev_dir
    local next_dir

    # HTML elements
    local counts_msg
    local prev_link
    local next_link

    current_dir=$1
    prev_dir="${current_dir}/prev"
    next_dir="${current_dir}/next"

    if [[ -d ${prev_dir} ]]; then
        counts_msg="<p>Fixed reports: ${fixed_reports} (<a href=\"prev/PROJECT.ecd\">previous database</a>)</p>
                    <p>New reports: ${new_reports} (<a href=\"PROJECT.ecd\">current database</a>)</p>"
        prev_link="<a href=\"prev/index.html\">Previous job</a>, "
    fi

    if [[ -d ${next_dir} ]]; then
        current_db_msg="<a href=\"PROJECT.ecd\">current database</a>)</p>"
        next_link="<a href=\"next/index.html\">Next job</a>, "
    fi

    cat <<EOF
    <!DOCTYPE html>
    <html lang="en">
    <head>
    <meta charset="utf-8">
    <link href="/rsrc/overall.css" rel="stylesheet" type="text/css">
    <title>${job_headline}: ECLAIR job #${current_job_id}</title>
    </head>
    <body>

    <div class="header">
        <a href="http://bugseng.com/eclair" target="_blank">
            <img src="/rsrc/eclair.png" alt="ECLAIR">
        </a>
        <span>${job_headline}: ECLAIR job #${current_job_id}</span>
    </div>
    ${current_db_msg}
    ${counts_msg}
    <br>
    <p>
        ${prev_link}${next_link}<a href="../">Jobs</a>
    </p>
    <div class="footer"><div>
        <a href="http://bugseng.com" target="_blank"><img src="/rsrc/bugseng.png" alt="BUGSENG">
            <span class="tagline">software verification done right.</span>
        </a>
        <br>
        <span class="copyright">
            The design of this web resource is Copyright © 2010-2022 BUGSENG srl. All rights reserved worldwide.
        </span>
    </div></div>

    </body>
    </html>
EOF
}

if [[ -n "${last_job_id}" ]]; then
    last_db=${last_dir}/PROJECT.ecd

    # Tag previous and current databases
    ${eclair_report} -setq=diff_tag_domain1,next -setq=diff_tag_domain2,prev \
        -tag_diff="'${last_db}','${current_db}'"

    # Count reports
    fixed_reports=$(${eclair_report} -db="${last_db}" -sel_tag_glob=diff_next,next,missing '-print="",reports_count()')
    new_reports=$(${eclair_report} -db="${current_db}" -sel_tag_glob=diff_prev,prev,missing '-print="",reports_count()')

    # Generate badge for the current run
    anybadge -o --label="ECLAIR" --value="fixed ${fixed_reports} | new ${new_reports}" --file="${current_dir}/badge.svg"

    # Add link to previous run of current run
    ln -s "../${last_job_id}" "${current_dir}/prev"

    # Add link to next run of last run
    ln -s "../${current_job_id}" "${last_dir}/next"

    # Generate index for the current job
    generate_index "${current_dir}" >"${current_index}"

    # Re-generate index for the previous job
    generate_index "${current_dir}/prev" >"${current_dir}/prev/index.html"

else
    new_reports=$(${eclair_report} -db="${current_db}" '-print="",reports_count()')
    anybadge -o --label="ECLAIR ${current_job_id}" --value="reports: ${new_reports}" --file="${current_dir}/badge.svg"

    # Generate index for the current job
    generate_index "${current_dir}" >"${current_index}"
fi

# Update last symlink
ln -sfn "${current_job_id}" "${results_root}/last"

# Add a link relating commit id to last build done for it
ln -sfn "../${current_job_id}" "${commits_dir}/${commit_id}"

# Generate summary and print it (Github-specific)
{
    echo "# ECLAIR analysis summary:"
    printf "Fixed reports: %d\n" "${fixed_reports}"
    printf "New reports: %d\n" "${new_reports}"
    echo "[Browse analysis](https://${ECLAIR_REPORT_HOST}/fs${current_index})"
} >>"${current_dir}/summary.txt"
cat "${current_dir}/summary.txt"
