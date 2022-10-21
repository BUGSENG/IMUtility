#!/bin/sh

set -e

PROJECT_PATH_VARIANT="${PROJECT_ARTIFACTS_PATH}/${VARIANT}"

CURRENT_JOB_ID="${JOB_ID}"
CURRENT_DB="${PROJECT_PATH_VARIANT}/${CURRENT_JOB_ID}/PROJECT.ecd"
CURRENT_ECDF="${PROJECT_PATH_VARIANT}/${CURRENT_JOB_ID}/.ecdf/"

PREVIOUS_JOB_ID=$(cat "${PROJECT_PATH_VARIANT}/last/id") # retrieve last successful run id (if any)

if [ -n "${PREVIOUS_JOB_ID}" ]; then
    PREVIOUS_DB="${PROJECT_PATH_VARIANT}/${PREVIOUS_JOB_ID}/PROJECT.ecd"
    PREVIOUS_ECDF="${PROJECT_PATH_VARIANT}/${PREVIOUS_JOB_ID}/.ecdf/"
    PREVIOUS_MISSING=$(cat "${PROJECT_PATH_VARIANT}/last/prev_missing")
    OLD_PREVIOUS_JOB_ID=$(cat "${PROJECT_PATH_VARIANT}/previous/id")

    # Tag previous and current databases
    eclair_report -setq=diff_tag_domain1,next -setq=diff_tag_domain2,prev \
        -tag_diff="${PROJECT_PATH_VARIANT}/${PREVIOUS_JOB_ID}/PROJECT.ecd,\
    ${PROJECT_PATH_VARIANT}/${CURRENT_JOB_ID}/PROJECT.ecd"

    # Count reports
    new_reports=$(eclair_report -db="${PREVIOUS_DB}" -sel_tag_glob=diff_prev,prev,missing '-print="",reports_count()')
    fixed_reports=$(eclair_report -db="${CURRENT_DB}" -sel_tag_glob=diff_next,next,missing '-print="",reports_count()')

    # Generate badge for the current run
    anybadge --label="ECLAIR #${CURRENT_JOB_ID}" --value="not in #${PREVIOUS_JOB_ID}: ${new_reports}" --file="${CURRENT_ECDF}/badge.svg"
    # Modify the badge of the previous run
    if [ -n "${PREVIOUS_MISSING}" ]; then
        anybadge --label="ECLAIR #${PREVIOUS_JOB_ID}" \
            --value="not in #${OLD_PREVIOUS_JOB_ID}: ${PREVIOUS_MISSING}, not in #${CURRENT_JOB_ID}: ${fixed_reports}" --file="${PREVIOUS_ECDF}/badge.svg"
    else
        # The previous run was the first
        anybadge --label="ECLAIR #${PREVIOUS_JOB_ID}" \
            --value="#reports: ${PREVIOUS_MISSING},not in #${CURRENT_JOB_ID}: ${fixed_reports}" --file="${PREVIOUS_ECDF}/badge.svg"
    fi

    # Write report counts to files
    echo "${new_reports}" >"${PROJECT_PATH_VARIANT}/${CURRENT_JOB_ID}/prev_missing"
    # Is it needed?
    #echo "${fixed_reports}" >"${PROJECT_PATH_VARIANT}/${PREVIOUS_JOB_ID}/next_missing"

    # Switch previous symlink
    ln -sf "${PROJECT_PATH_VARIANT}/${PREVIOUS_JOB_ID}" "${PROJECT_PATH_VARIANT}/previous"

else
    report_count=$(eclair_report -db="${CURRENT_DB}" '-print="",reports_count()')
    anybadge --label="ECLAIR ${CURRENT_JOB_ID}" --value=" #reports: ${report_count}"
    # Write report count to file
    echo "${report_count}" >"${PROJECT_PATH_VARIANT}/${CURRENT_JOB_ID}/prev_missing"
fi

# Empty svg for the next run
anybadge --label="ECLAIR #$((CURRENT_JOB_ID + 1))" --value="missing" --color="red"

# Write this job's id for future use
echo "${CURRENT_JOB_ID}" >"${PROJECT_PATH_VARIANT}/${CURRENT_JOB_ID}/id"

# Update last symlink
ln -sf "${PROJECT_PATH_VARIANT}/${CURRENT_JOB_ID}" "${PROJECT_PATH_VARIANT}/last"
