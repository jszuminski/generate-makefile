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

# find all .c source files in the directory (not in subdirectories)
mapfile -t source_files < <(find "$project_dir" -maxdepth 1 -type f -name '*.c' | sort)

# check if any .c files were found
if (( ${#source_files[@]} == 0 )); then
    echo "Error: no .c source files found in '$project_dir'." >&2
    exit 5
fi

echo "Found ${#source_files[@]} source files:"
printf '   %s\n' "${source_files[@]}"

# detect which file contains main()
main_files=()
for f in "${source_files[@]}"; do
    # simple but effective regex; anchors allow leading spaces
    if grep -Eq '^[[:space:]]*int[[:space:]]+main[[:space:]]*\(' "$f"; then
        main_files+=("$f")
    fi
done

# validate number of mains
if (( ${#main_files[@]} == 0 )); then
    echo "Error: no file with a 'main' function found in '$project_dir'." >&2
    exit 5
elif (( ${#main_files[@]} > 1 )); then
    printf "Error: multiple files contain 'main':\n" >&2
    printf "  %s\n" "${main_files[@]}" >&2
    exit 6
fi

# derive executable name from the file with main()
main_basename=$(basename "${main_files[0]}")
exe_name="${main_basename%.*}"

echo "main() found in: $main_basename"
echo "Executable name will be: $exe_name"

# My own notes
# >&2 -> redirects output to stderr (>&1 is just stdout)
# exit 0 - success
# exit 1 - general error (something failed)
# exit 2 - misuse of shell builtins or wrong usage (ex. wrong arguments)
# exit 3+ - custom error codes (own logic)
# there can be no spaces between assignement to a variable (var=$1 not var = $1)
# bash 4 is required (in bash 3 there's no `mapfile`)