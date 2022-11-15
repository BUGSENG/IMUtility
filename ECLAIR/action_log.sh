#!/bin/sh
# set -u is intentionally not used, as it would require
# to specify unneeded variables
set -e

usage() {
    echo "Usage: $0 SECTION_ID SECTION_NAME FILE EXIT_CODE" >&2
    exit 2
}

[ $# -eq 4 ] || usage

# Load utility functions
. "$(dirname "$0")/action.settings"

log_file "$@"
