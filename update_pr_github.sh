#!/bin/bash

set -e

# To be adjusted to local setup
ECLAIR_PATH=${ECLAIR_PATH:-/opt/bugseng/eclair/bin/}
eclair_report="${ECLAIR_PATH}eclair_report"

usage() {
    echo "Usage: $0 RESULTS_ROOT PR_NUMBER JOB_ID JOB_HEADLINE PR_HEADLINE PR_BASE_SHA" >&2
    exit 2
}

[[ "$#" -eq 6 ]] || usage

results_root="$1"
pr_number="$2"
current_job_id="$3"
job_headline="$4"
pr_headline="$5"
pr_base_sha="$6"

commits_dir="${results_root}/commits"

# PR HEAD variables
pr_dir="${results_root}/pr"
pr_current_dir="${pr_dir}/${current_job_id}"
pr_db="${pr_current_dir}/PROJECT.ecd"
pr_index="${pr_current_dir}/index.html"

mkdir -p "${commits_dir}"
mkdir -p "${pr_current_dir}"

# PR base variables
base_dir="${commits_dir}/${pr_base_sha}"
base_job_id=
[[ ! -d "${base_dir}" ]] || base_job_id=$(basename "$(realpath "${base_dir}")")
# For PRs, the base db is copied in the current PR's subdir, to avoid altering it
pr_base_db_name="PROJECT_base.ecd"
cp "${base_dir}/PROJECT.ecd" "${pr_current_dir}/${pr_base_db_name}"
pr_base_db="${pr_current_dir}/${pr_base_db_name}"

# The group where eclair_report runs must be in this file's group
chmod g+w "${pr_db}" "${pr_base_db}"

# Generate a file index.html for PRs
generate_index_pr() {

    # HTML elements
    local counts_msg
    local base_link

    if [[ -d ${base_dir} ]]; then
        counts_msg="<p>Fixed reports: ${fixed_reports} (<a href=\"${pr_base_db_name}\">PR base database</a>)</p>
                    <p>New reports: ${new_reports} (<a href=\"PROJECT.ecd\">PR head database</a>)</p>"
        base_link="<p><a href=\"base/index.html\">PR base job</a></p>"
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
    <h1>${pr_headline}</h1>
    ${counts_msg}
    <br>
    ${base_link}
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

if [[ -n "${base_job_id}" ]]; then

    # Tag previous and current databases
    ${eclair_report} -setq=diff_tag_domain1,next -setq=diff_tag_domain2,prev \
        -tag_diff="'${pr_base_db}','${pr_db}'"

    # Count reports
    fixed_reports=$(${eclair_report} -db="${pr_base_db}" -sel_tag_glob=diff_next,next,missing '-print="",reports_count()')
    new_reports=$(${eclair_report} -db="${pr_db}" -sel_tag_glob=diff_prev,prev,missing '-print="",reports_count()')

    # Generate badge for the current run
    anybadge -o --label="ECLAIR" --value="fixed ${fixed_reports} | new ${new_reports}" --file="${pr_current_dir}/badge.svg"

    # Add link to base commit of the current run
    ln -s "../../${base_job_id}" "${pr_current_dir}/base"

    # Generate index for the PR
    generate_index_pr >"${pr_index}"
else
    # No base commit analysis found
    # TODO: what to do?
    new_reports=$(${eclair_report} -db="${pr_db}" '-print="",reports_count()')
    anybadge -o --label="ECLAIR ${current_job_id}" --value="reports: ${new_reports}" --file="${pr_current_dir}/badge.svg"

    # Generate index for the current job
    generate_index "${pr_current_dir}" >"${pr_index}"
fi

# Generate summary and print it (Github-specific)
{
    echo '[![ECLAIR](https://eclairit.com:3787/rsrc/eclair.png)](https://www.bugseng.com/eclair)'
    echo "# ECLAIR analysis summary:"
    printf "Fixed reports: %d\n" "${fixed_reports}"
    printf "New reports: %d\n" "${new_reports}"
    echo "[Browse analysis](https://${ECLAIR_REPORT_HOST}/fs${pr_index})"
} >"${pr_current_dir}/summary.txt"
cat "${pr_current_dir}/summary.txt"

# Create a comment on the PR
repo="${job_headline}"
gh api \
    --method POST \
    -H "Accept: application/vnd.github.raw+json" \
    "/repos/${repo}/issues/${pr_number}/comments" \
    -F body='@'"${pr_current_dir}/summary.txt" \
    --silent
