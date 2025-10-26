#!/usr/bin/env bash
# for reliability
# e - exit on error
# u - error on undefined variable
# -o pipefail - catch errors in pipelines
set -euo pipefail

# helper function
usage() {
    echo "Usage: $0 <directory>" >&2
}

# check the number of arguments
if [[ $# -ne 1 ]]; then
    usage
    exit 1
fi

# check if the directory exists
if [[ ! -d "$project_dir" ]]; then
    echo "Error: the directory '$project_dir' does not exist or is not a directory." >&2
    exit 2
fi

echo "The given directory is correct, continuing..."

# My own notes
# >&2 -> redirects output to stderr (>&1 is just stdout)
# exit 0 - success
# exit 1 - general error (something failed)
# exit 2 - misuse of shell builtins or wrong usage (ex. wrong arguments)
# exit 3+ - custom error codes (own logic)
