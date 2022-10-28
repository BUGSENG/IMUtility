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

update_yml=${analysis_output_dir}/update.yml
${eclair_report_host_sh} "${current_job_dir}/update_push.sh \
'${artifacts_dir}' '${job_id}' '${job_headline}' \
'${commit_id}' '${branch}' '${badge_label}'" >"${update_yml}"

fixed_reports=
new_reports=
unfixed_reports=
while read -r line; do
    var=${line%%: *}
    val=${line#*: }
    eval "${var}"="${val}"
done <"${update_yml}"

current_index_html_url=${eclair_report_url_prefix}/fs/${current_job_dir}/index.html

[ "${job_summary_file}" = /dev/stdout ] || exec >"${job_summary_file}"

case ${ci} in
github)
    cat <<EOF
[![ECLAIR](${eclair_report_url_prefix}/rsrc/eclair.png)](https://www.bugseng.com/eclair)
# ECLAIR analysis summary:
Fixed reports: ${fixed_reports}

Unfixed reports: ${unfixed_reports} [new: ${new_reports}]

[Browse analysis](${current_index_html_url})
EOF
    ;;
gitlab)
    esc=$(printf '\e')
    cr=$(printf '\r')
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
