#!/bin/sh

set -e
set -x

# To be adjusted to local setup
ECLAIR_PATH=${ECLAIR_PATH:-/opt/bugseng/eclair/bin/}
eclair_report="${ECLAIR_PATH}eclair_report"

usage() {
    echo "Usage: $0 RESULTS_ROOT BRANCH BADGE_LABEL JOB_ID JOB_HEADLINE COMMIT_ID" >&2
    exit 2
}

[ $# -eq 6 ] || usage

results_root=$1
branch=$2
badge_label=$3
current_job_id=$4
job_headline=$5
commit_id=$6

results_branch_dir="${results_root}/${branch}"
current_dir="${results_branch_dir}/${current_job_id}"
current_db="${current_dir}/PROJECT.ecd"
current_index="${current_dir}/index.html"
previous_index="${current_dir}/prev/index.html"
commits_dir="${results_root}/commits"

mkdir -p "${commits_dir}"

# The group where eclair_report runs must be in this file's group
chmod g+w "${current_db}"

last_dir=${results_branch_dir}/last
last_job_id=
[ ! -d "${last_dir}" ] || last_job_id=$(basename "$(realpath "${last_dir}")")

# Generate a file index.html to browse the analysis
generate_index() {

    job_id=$1
    job_dir="${results_branch_dir}/${job_id}"
    prev_dir="${job_dir}/prev"
    next_dir="${job_dir}/next"

    new_reports=$(cat "${job_dir}/new_reports.txt")

    counts_msg=
    prev_link=
    next_link=
    latest_db_msg=

    if [ -d "${prev_dir}" ]; then
        fixed_reports=$(cat "${job_dir}/fixed_reports.txt")
        counts_msg=$(
            cat <<EOF
<p>Fixed reports: ${fixed_reports} (<a href="prev/PROJECT.ecd">previous database</a>)</p>
<p>New reports: ${new_reports} (<a href="PROJECT.ecd">current database</a>)</p>
EOF
        )
        prev_link=$(
            cat <<EOF
<a href="prev/index.html">Previous job</a>, 
EOF
        )
    else
        counts_msg=$(
            cat <<EOF
<p>Reports: ${new_reports} (<a href="PROJECT.ecd">current database</a>)</p>
EOF
        )
    fi

    if [ -d "${next_dir}" ]; then
        next_link=$(
            cat <<EOF
<a href="next/index.html">Next job</a>, 
EOF
        )
        latest_db_msg=$(
            cat <<EOF
<p>Browse the <a href="../last/index.html">latest job</a></p>
EOF
        )
    else
        latest_db_msg=$(
            cat <<EOF
<p>This is the latest job.</p>
EOF
        )
    fi

    cat <<EOF
<!DOCTYPE html>
<html lang="en">
 <head>
  <meta charset="utf-8">
  <link href="/rsrc/overall.css" rel="stylesheet" type="text/css">
  <title>${job_headline} - ECLAIR job #${job_id}</title>
 </head>
 <body>
  <div class="header">
   <a href="http://bugseng.com/eclair" target="_blank">
    <img src="/rsrc/eclair.png" alt="ECLAIR">
   </a>
   <span>${job_headline} - ECLAIR job #${job_id}</span>
  </div>
  ${counts_msg}
  ${latest_db_msg}
  <hr>
  <p>
   ${prev_link}${next_link}<a href="../">Jobs</a>
  </p>
  <div class="footer"><div>
   <a href="http://bugseng.com" target="_blank">
    <img src="/rsrc/bugseng.png" alt="BUGSENG">
    <span class="tagline">software verification done right.</span>
   </a>
   <br>
   <span class="copyright">
   The design of this web resource is Copyright © 2010-2022 BUGSENG srl. All rights reserved worldwide.
   </span>
  </div>
 </body>
</html>
EOF
}

if [ -n "${last_job_id}" ]; then
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
    anybadge -o --label="${badge_label}" --value="fixed ${fixed_reports} | new ${new_reports}" --file="${current_dir}/badge.svg"

    # Add link to previous run of current run
    ln -s "../${last_job_id}" "${current_dir}/prev"

    # Add link to next run of last run
    ln -s "../${current_job_id}" "${last_dir}/next"

    # Generate index for the current job
    generate_index "${current_job_id}" >"${current_index}"

    # Re-generate index for the previous job
    previous_job_id=$(grep -o "#[0-9]*" "${previous_index}" | head -1 | cut -c2-)
    generate_index "${previous_job_id}" >"${previous_index}"

else
    new_reports=$(${eclair_report} -db="${current_db}" '-print="",reports_count()')
    echo "${new_reports}" >"${results_branch_dir}/${current_job_id}/new_reports.txt"

    anybadge -o --label="${badge_label}" --value="reports: ${new_reports}" --file="${current_dir}/badge.svg"

    # Generate index for the current job
    generate_index "${current_job_id}" >"${current_index}"
fi

# Update last symlink
ln -sfn "${current_job_id}" "${last_dir}"

# Add a link relating commit id to last build done for it
ln -sfn "../${current_job_id}" "${commits_dir}/${commit_id}"

# Generate summary and print it (Github-specific)
# ANALYSIS_HOST is passed from tag_db.sh
{
    echo "# ECLAIR analysis summary:"
    printf "Fixed reports: %d\n" "${fixed_reports}"
    printf "New reports: %d\n" "${new_reports}"
    echo "[Browse analysis](${ANALYSIS_HOST}${current_index})"
} >>"${current_dir}/summary.txt"
cat "${current_dir}/summary.txt"
