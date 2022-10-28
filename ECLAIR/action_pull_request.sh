#!/bin/sh

set -e

cd "$(dirname "$0")"

usage() {
    echo "Usage: $0 ANALYSIS_OUTPUT_DIR COMMIT_ID BASE_COMMIT_ID" >&2
    exit 2
}

[ $# -eq 3 ] || usage

# Source variables
. ./action.settings

analysis_output_dir=$1
#commit_id=$2
base_commit_id=$3

current_job_dir=${eclair_report_host_scp}${artifacts_dir}/pr/${job_id}

# create a directory for the analysis artifacts
${eclair_report_host_sh} "mkdir -p '${current_job_dir}'"

# Transfer the database to eclair_report_host
scp "${analysis_output_dir}/PROJECT.ecd" "${current_job_dir}"

# Send the scripts to eclair report host
scp update_pull_request.sh \
    "${eclair_report_host_scp}${current_job_dir}"

update_yml=${analysis_output_dir}/update.yml

${eclair_report_host_sh} "${current_job_dir}/update_pull_request.sh \
'${artifacts_dir}' '${job_id}' '${job_headline}' \
'${base_commit_id}'" >"${update_yml}"

fixed_reports=
new_reports=
unfixed_reports=
while read -r line; do
    var=${line%%: *}
    val=${line#*: }
    eval "${var}"="${val}"
done <"${update_yml}"

current_index_html_url=${eclair_report_url_prefix}/fs/${current_job_dir}/index.html
summary_txt_file="summary.txt"

cat <<EOF >"${summary_txt_file}"
[![ECLAIR](${eclair_report_url_prefix}/rsrc/eclair.png)](https://www.bugseng.com/eclair)
# ECLAIR analysis summary:
Fixed reports: ${fixed_reports}

Unfixed reports: ${unfixed_reports} [new: ${new_reports}]

[Browse analysis](${current_index_html_url})
EOF

case ${ci} in
github)
    gh api \
        --method POST \
        "/repos/${repository}/issues/${pr_id}/comments" \
        -H "Accept: application/vnd.github.raw+json" \
        -F body="@${summary_txt_file}" \
        --silent
    ;;
gitlab)
    curl --request POST \
        "https://eclairit.com:8444/api/v4/projects/${CI_PROJECT_ID?:}/merge_requests/${pr_id}/notes" \
        -H "PRIVATE-TOKEN: ${ECLAIRIT_TOKEN?:}" \
        -F body="<${summary_txt_file}" \
        --silent
    ;;
*) ;;
esac

[ "${job_summary_file}" = /dev/stdout ] || exec >"${job_summary_file}"

case ${ci} in
github)
    cat "${summary_txt_file}"
    ;;
gitlab)
    esc=$(printf '\e')
    cr=$(printf '\r')
    # Generate summary and print it (GitLab-specific)
    cat <<EOF
${esc}[0Ksection_start:$(date +%s):ECLAIR_summary${cr}${esc}[0K${esc}[1m${esc}[36mECLAIR analysis summary${esc}[m
Fixed reports: ${fixed_reports}
Unfixed reports: ${unfixed_reports} [new: ${new_reports}]
Browse analysys: ${esc}[33m${current_index_html_url}${esc}[m
${esc}[0Ksection_end:$(date +%s):ECLAIR_summary${cr}${esc}[0K
EOF
    ;;
*) : ;;
esac
