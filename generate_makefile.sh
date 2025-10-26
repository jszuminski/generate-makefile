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

# NEW: pick a compiler usable for dependency gen (portable on macOS: cc -> clang)
compiler="${CC:-cc}"
if ! command -v "$compiler" >/dev/null 2>&1; then
    echo "Error: no C compiler found (tried '\$CC' and 'cc'). Install Xcode Command Line Tools or GCC/Clang." >&2
    exit 8
fi

# find all .c source files in the directory (not in subdirectories)
# NEW: portable fallback for macOS bash 3 (no 'mapfile')
if type mapfile >/dev/null 2>&1; then
    mapfile -t source_files < <(find "$project_dir" -maxdepth 1 -type f -name '*.c' | LC_ALL=C sort)
else
    source_files=()
    while IFS= read -r f; do source_files+=("$f"); done < <(find "$project_dir" -maxdepth 1 -type f -name '*.c' | LC_ALL=C sort)
fi

# check if any .c files were found
if (( ${#source_files[@]} == 0 )); then
    echo "Error: no .c source files found in '$project_dir'." >&2
    exit 5
fi

# NEW: verify readability of each source file (clearer error if permissions are off)
for f in "${source_files[@]}"; do
    if [[ ! -r "$f" ]]; then
        echo "Error: source file is not readable: $f" >&2
        exit 3
    fi
done

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

# detect local headers directory and prepare include flag
headers_dir="$project_dir/headers"
include_flag=""
if [[ -d "$headers_dir" ]]; then
    include_flag='-Iheaders'
    echo "Found headers/: will use $include_flag"
    # NEW: optional readability check for headers directory
    if [[ ! -r "$headers_dir" ]]; then
        echo "Error: headers/ directory exists but is not readable." >&2
        exit 3
    fi
else
    echo "Warning: no 'headers/' directory found. Continuing without local includes." >&2
fi

# build relative_sources (basenames) from source_files
relative_sources=()
for src in "${source_files[@]}"; do
    relative_sources+=("$(basename "$src")")
done

# generate dependency lines for each .c file
dependency_lines=()
for src in "${relative_sources[@]}"; do
    # Run compiler in the project directory, with optional -Iheaders
    # The -MM flag outputs dependencies in Makefile format.
    # NEW: expand include flag safely only if set
    deps=$(cd "$project_dir" && "$compiler" -MM ${include_flag:+$include_flag} "$src" 2>/dev/null || true)
    # NEW: skip empty outputs to avoid blank lines
    if [[ -n "${deps//[[:space:]]/}" ]]; then
        dependency_lines+=("$deps")
    fi
done

echo "Generated dependency lines:"
printf '%s\n' "${dependency_lines[@]}"

# derive object filenames from relative_sources
objects=()
for src in "${relative_sources[@]}"; do
    objects+=("${src%.c}.o")
done

# stage Makefile header (preview only)
echo "Makefile header preview:"
{
  echo "CC ?= gcc"
  echo "CFLAGS ?= -O2 -Wall -Wextra -std=c11"
  if [[ -d "$headers_dir" ]]; then
    echo "INCLUDES := -Iheaders"
  else
    echo "INCLUDES :="
  fi
  echo "SRCS := ${relative_sources[*]}"
  echo "OBJS := ${objects[*]}"
  echo "TARGET := $exe_name"
} | sed 's/^/  /'

# write Makefile atomically
tmpfile="$(mktemp "$project_dir/.Makefile.tmp.XXXXXX")"

{
  echo "CC ?= gcc"
  echo "CFLAGS ?= -O2 -Wall -Wextra -std=c11"
  if [[ -d "$headers_dir" ]]; then
    echo "INCLUDES := -Iheaders"
  else
    echo "INCLUDES :="
  fi
  echo "SRCS := ${relative_sources[*]}"
  echo "OBJS := ${relative_sources[*]//.c/.o}"
  echo "TARGET := $exe_name"
  echo
  echo "all: \$(TARGET)"
  echo
  echo "\$(TARGET): \$(OBJS)"
  echo "	\$(CC) \$(OBJS) -o \$@ \$(LDFLAGS)"
  echo
  echo "%.o: %.c"
  echo "	\$(CC) \$(CFLAGS) \$(INCLUDES) -c \$< -o \$@"
  echo
  echo "# Dependencies generated by gcc -MM"
  printf '%s\n' "${dependency_lines[@]}"
  echo
  echo ".PHONY: all clean"
  echo "clean:"
  echo "	rm -f \$(OBJS) \$(TARGET)"
  # NEW: convenience run target (optional but handy)
  echo
  echo ".PHONY: run"
  echo "run: \$(TARGET)"
  echo "	./\$(TARGET)"
} > "$tmpfile"

mv "$tmpfile" "$project_dir/Makefile"
echo "Wrote Makefile to: $project_dir/Makefile"


# My own notes
# >&2 -> redirects output to stderr (>&1 is just stdout)
# exit 0 - success
# exit 1 - general error (something failed)
# exit 2 - misuse of shell builtins or wrong usage (ex. wrong arguments)
# exit 3+ - custom error codes (own logic)
# there can be no spaces between assignement to a variable (var=$1 not var = $1)
# bash 4 is required (in bash 3 there's no `mapfile`)
