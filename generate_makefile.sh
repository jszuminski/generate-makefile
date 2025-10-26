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
project_dir=$1
if [[ ! -d "$project_dir" ]]; then
    echo "Error: the directory '$project_dir' does not exist or is not a directory." >&2
    exit 2
fi

echo "The given directory is correct, continuing..."

# check read permission
if [[ ! -r "$project_dir" ]]; then
    echo "Error: no read permission for directory '$project_dir'." >&2
    exit 3
fi

# check write permission
if [[ ! -w "$project_dir" ]]; then
    echo "Error: no write permission for directory '$project_dir'." >&2
    exit 4
fi

echo "Directory is accessible (read & write)."


# My own notes
# >&2 -> redirects output to stderr (>&1 is just stdout)
# exit 0 - success
# exit 1 - general error (something failed)
# exit 2 - misuse of shell builtins or wrong usage (ex. wrong arguments)
# exit 3+ - custom error codes (own logic)
# there can be no spaces between assignement to a variable (var=$1 not var = $1)
