#!/bin/sh

set -e
set -x

# To be adjusted to local setup
ECLAIR_PATH=${ECLAIR_PATH:-/opt/bugseng/eclair/bin/}
eclair_report=${ECLAIR_PATH}eclair_report

usage() {
    echo "Usage: $0 CI URL_PREFIX ARTIFACTS_DIR JOB_ID JOB_HEADLINE COMMIT_ID BRANCH BADGE_LABEL " >&2
    exit 2
}

[ $# -eq 8 ] || usage

ci=$1
url_prefix=$2
artifacts_dir=$3
current_job_id=$4
job_headline=$5
commit_id=$6
branch=$7
badge_label=$8

commits_dir=${artifacts_dir}/commits
artifacts_branch_dir=${artifacts_dir}/${branch}
current_dir=${artifacts_branch_dir}/${current_job_id}
current_db=${current_dir}/PROJECT.ecd
current_index_html=${current_dir}/index.html
current_index_html_url=${url_prefix}/fs${current_index_html}
previous_index=${current_dir}/prev/index.html

mkdir -p "${commits_dir}"

# The group running eclair_report must be in this file's group
chmod g+w "${current_db}"

latest_dir=${artifacts_branch_dir}/latest
latest_job_id=
[ ! -d "${latest_dir}" ] || latest_job_id=$(basename "$(realpath "${latest_dir}")")

# Generate a file index.html to browse the analysis
generate_index_html() {

    job_id=$1
    job_dir=${artifacts_branch_dir}/${job_id}
    prev_dir=${job_dir}/prev
    next_dir=${job_dir}/next

    local_unfixed_reports=$(cat "${job_dir}/unfixed_reports.txt")
    local_new_reports=$(cat "${job_dir}/new_reports.txt")

    counts_msg=
    prev_link=
    next_link=
    latest_db_msg=

    if [ -d "${prev_dir}" ]; then
        local_fixed_reports=$(cat "${job_dir}/fixed_reports.txt")
        counts_msg=$(
            cat <<EOF
<p>Fixed reports: ${local_fixed_reports} (<a href="prev/PROJECT.ecd">previous database</a>)</p>
<p>Unfixed reports: ${local_unfixed_reports} [new: ${local_new_reports}] (<a href="PROJECT.ecd">current database</a>)</p>
EOF
        )
        prev_link=$(
            cat <<EOF
<a href="prev/index.html">Previous analysis</a>,
EOF
        )
    else
        counts_msg=$(
            cat <<EOF
<p>Unfixed reports: ${local_unfixed_reports} (<a href="PROJECT.ecd">current database</a>)</p>
EOF
        )
    fi

    if [ -d "${next_dir}" ]; then
        next_link=$(
            cat <<EOF
<a href="next/index.html">Next analysis</a>,
EOF
        )
        latest_db_msg=$(
            cat <<EOF
<p>Browse the <a href="../latest/index.html">latest analysis</a></p>
EOF
        )
    else
        latest_db_msg=$(
            cat <<EOF
<p>This is the latest analysis.</p>
EOF
        )
    fi

    cat <<EOF
<!DOCTYPE html>
<html lang="en">
 <head>
  <meta charset="utf-8">
  <link href="/rsrc/overall.css" rel="stylesheet" type="text/css">
  <title>${job_headline} - ECLAIR analysis #${job_id}</title>
 </head>
 <body>
  <div class="header">
   <a href="http://bugseng.com/eclair" target="_blank">
    <img src="/rsrc/eclair.png" alt="ECLAIR">
   </a>
   <span>${job_headline} - ECLAIR analysis #${job_id}</span>
  </div>
  ${counts_msg}
  ${latest_db_msg}
  <hr>
  <p>
   ${prev_link} ${next_link} <a href="../">All analyses</a>
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

unfixed_reports=$(${eclair_report} -db="'${current_db}'" -sel_unfixed=unfixed '-print="",reports_count()')
echo "${unfixed_reports}" >"${artifacts_branch_dir}/${current_job_id}/unfixed_reports.txt"

if [ -n "${latest_job_id}" ]; then
    latest_db=${latest_dir}/PROJECT.ecd

    # Tag previous and current databases
    ${eclair_report} -setq=diff_tag_domain1,next -setq=diff_tag_domain2,prev \
        -tag_diff="'${latest_db}','${current_db}'"

    # Count reports
    fixed_reports=$(${eclair_report} -db="'${latest_db}'" -sel_unfixed=unfixed -sel_tag_glob=diff_next,next,missing '-print="",reports_count()')
    echo "${fixed_reports}" >"${artifacts_branch_dir}/${current_job_id}/fixed_reports.txt"
    new_reports=$(${eclair_report} -db="'${current_db}'" -sel_unfixed=unfixed -sel_tag_glob=diff_prev,prev,missing '-print="",reports_count()')
    echo "${new_reports}" >"${artifacts_branch_dir}/${current_job_id}/new_reports.txt"

    # Generate badge for the current run
    anybadge -o --label="${badge_label}" --value="fixed ${fixed_reports} | unfixed ${unfixed_reports} | new ${new_reports}" --file="${current_dir}/badge.svg"

    # Add link to previous run of current run
    ln -s "../${latest_job_id}" "${current_dir}/prev"

    # Add link to next run of latest run
    ln -s "../${current_job_id}" "${latest_dir}/next"

    # Generate index for the current analysis
    generate_index_html "${current_job_id}" >"${current_index_html}"

    # Re-generate index for the previous analysis
    previous_job_id=$(grep -o "#[0-9]*" "${previous_index}" | head -1 | cut -c2-)
    generate_index_html "${previous_job_id}" >"${previous_index}"

else

    echo "${unfixed_reports}" >"${artifacts_branch_dir}/${current_job_id}/new_reports.txt"
    anybadge -o --label="${badge_label}" --value="unfixed: ${unfixed_reports}" --file="${current_dir}/badge.svg"

    # Generate index for the current analysis
    generate_index_html "${current_job_id}" >"${current_index_html}"
fi

# Update latest symlink
ln -sfn "${current_job_id}" "${latest_dir}"

# Add a link relating commit id to latest build done for it
ln -sfn "../${branch}/${current_job_id}" "${commits_dir}/${commit_id}"

case "${ci}" in
github)
    # Generate summary and print it (GitHub-specific)
    echo "[![ECLAIR](${url_prefix}/rsrc/eclair.png)](https://www.bugseng.com/eclair)"
    echo "# ECLAIR analysis summary:"
    if [ -n "${latest_job_id}" ]; then
        echo "Fixed reports: ${fixed_reports}"
        echo "Unfixed reports: ${unfixed_reports} [new: ${new_reports}]"
    else
        echo "Unfixed reports: ${unfixed_reports}"
    fi
    echo "[Browse analysis](${current_index_html_url})"
    ;;
gitlab)
    # Generate summary and print it (GitLab-specific)
    esc=$(printf '\e')
    cr=$(printf '\r')
    echo "${esc}[0KECLAIR analysis summary:${cr}"
    if [ -n "${latest_job_id}" ]; then
        echo "Fixed reports: ${fixed_reports}"
        echo "Unfixed reports: ${unfixed_reports} [new: ${new_reports}]"
    else
        echo "Unfixed reports: ${unfixed_reports}"
    fi
    echo "Browse analysys: ${esc}[33m${current_index_html_url}${esc}[m"
    ;;
*) ;;
esac >"${current_dir}/summary.txt"
cat "${current_dir}/summary.txt"
