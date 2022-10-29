#!/bin/sh

set -eu

# To be adjusted to local setup
ECLAIR_PATH=${ECLAIR_PATH:-/opt/bugseng/eclair/bin/}
eclair_report=${ECLAIR_PATH}eclair_report

usage() {
    echo "Usage: $0 ARTIFACTS_DIR JOB_ID JOB_HEADLINE BASE_COMMIT_ID" >&2
    exit 2
}

[ $# -eq 4 ] || usage

artifacts_dir=$1
current_job_id=$2
job_headline=$3
base_commit_id=$4

commits_dir=${artifacts_dir}/commits
current_dir=${artifacts_dir}/pr/${current_job_id}
current_db=${current_dir}/PROJECT.ecd
current_index_html=${current_dir}/index.html

mkdir -p "${commits_dir}"

# The group running eclair_report must be in this file's group
chmod g+w "${current_db}"

# PR base variables
base_dir=${commits_dir}/${base_commit_id}
base_job_id=
[ ! -d "${base_dir}" ] || base_job_id=$(basename "$(realpath "${base_dir}")")
# For PRs, the base db is copied in the current PR's subdir, to avoid altering it
base_db_name='PROJECT_base.ecd'
cp -a "${base_dir}/PROJECT.ecd" "${current_dir}/${base_db_name}"
base_db=${current_dir}/${base_db_name}

# Generate a file index.html for PRs
generate_index_html() {

    # HTML elements
    counts_msg=
    base_link=

    if [ -d "${base_dir}" ]; then
        counts_msg=$(
            cat <<EOF
<p>Fixed reports: ${fixed_reports} (<a href="${base_db_name}">Base database</a>)</p>
<p>Unfixed reports: ${unfixed_reports} [new: ${new_reports}] (<a href="PROJECT.ecd">Merged database</a>)</p>
EOF
        )
        base_link=$(
            cat <<EOF
<a href="base/index.html">Base analysis</a>
EOF
        )
    fi

    cat <<EOF
<!DOCTYPE html>
<html lang="en">
 <head>
  <meta charset="utf-8">
  <link href="/rsrc/overall.css" rel="stylesheet" type="text/css">
  <title>${job_headline}: ECLAIR analysis #${current_job_id}</title>
 </head>
 <body>
  <div class="header">
   <a href="http://bugseng.com/eclair" target="_blank">
    <img src="/rsrc/eclair.png" alt="ECLAIR">
   </a>
   <span>${job_headline}: ECLAIR analysis #${current_job_id}</span>
  </div>
  ${counts_msg}
  <hr>
  <p>
   ${base_link} <a href="../">All PR analyses</a>
  </p>
  <div class="footer"><div>
   <a href="http://bugseng.com" target="_blank"><img src="/rsrc/bugseng.png" alt="BUGSENG">
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

unfixed_reports=$(${eclair_report} -db="'${base_db}'" -sel_unfixed=unfixed '-print="",reports_count()')

if [ -n "${base_job_id}" ]; then

    # Tag previous and current databases
    ${eclair_report} -setq=diff_tag_domain1,next -setq=diff_tag_domain2,prev \
        -tag_diff="'${base_db}','${current_db}'"

    # Count reports
    fixed_reports=$(${eclair_report} -db="'${base_db}'" -sel_unfixed=unfixed -sel_tag_glob=diff_next,next,missing '-print="",reports_count()')
    new_reports=$(${eclair_report} -db="'${current_db}'" -sel_unfixed=unfixed -sel_tag_glob=diff_prev,prev,missing '-print="",reports_count()')

    # Generate badge for the current run
    #anybadge -o --label="ECLAIR" --value="fixed ${fixed_reports} | new ${new_reports}" --file="${current_dir}/badge.svg"

    # Add link to base commit of the current run
    ln -s "../../commits/${base_commit_id}" "${current_dir}/base"

    # Generate index for the PR
    generate_index_html >"${current_index_html}"
else
    # No base commit analysis found
    # TODO: what to do?
    #anybadge -o --label="ECLAIR ${current_job_id}" --value="unfixed: ${unfixed_reports}" --file="${current_dir}/badge.svg"

    # Generate index for the current analysis
    generate_index_html >"${current_index_html}"
fi

echo "fixed_reports: ${fixed_reports}"
echo "new_reports: ${new_reports}"
echo "unfixed_reports: ${unfixed_reports}"
