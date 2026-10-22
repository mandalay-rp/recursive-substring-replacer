#!/usr/bin/env bash
#
# replace.sh — recursively replace a literal string inside text files.
#
# Usage:
#   ./replace.sh [-d DIR] [-n] [-b] [-f] [-i] "search" "replace"
#
# Options:
#   -d DIR   directory to process (default: current directory)
#   -n       dry-run: only print files that would be changed
#   -b       keep backup copies next to each file (.bak suffix)
#   -f       replace only the first occurrence per file (default: all)
#   -i       case-insensitive search (requires GNU sed)
#   -h       show this help
#

set -euo pipefail

usage() {
    cat <<'EOF'
Usage: replace.sh [-d DIR] [-n] [-b] [-f] [-i] "search" "replace"
  -d DIR  directory to process (default: current)
  -n      dry-run, do not modify any files
  -b      keep backup copies (.bak)
  -f      replace only the first occurrence per file
  -i      case-insensitive search (GNU sed only)
  -h      show this help
EOF
}

dir="."
dry_run=0
backup=0
first_only=0
ignore_case=0

while getopts ":d:nbfih" opt; do
    case "$opt" in
        d) dir="$OPTARG" ;;
        n) dry_run=1 ;;
        b) backup=1 ;;
        f) first_only=1 ;;
        i) ignore_case=1 ;;
        h) usage; exit 0 ;;
        :) echo "Error: option -$OPTARG requires an argument" >&2; exit 1 ;;
        \?) echo "Error: unknown option -$OPTARG" >&2; usage >&2; exit 1 ;;
    esac
done
shift $((OPTIND - 1))

if [ "$#" -ne 2 ]; then
    usage >&2
    exit 1
fi

search=$1
replace=$2

[ -n "$search" ] || { echo "Error: search string must not be empty" >&2; exit 1; }
[ -d "$dir" ]    || { echo "Error: not a directory: $dir" >&2; exit 1; }

# ---- Escape characters for sed ----
# Escape every BRE/ERE metacharacter in the search pattern.
esc_search=$(printf '%s' "$search"  | sed -e 's/[][\\.*^$/]/\\&/g')
# Escape the delimiter, backslash, and ampersand in the replacement.
esc_replace=$(printf '%s' "$replace" | sed -e 's/[\/&\\]/\\&/g')

# ---- Build sed flags ----
sed_flags=""
[ "$first_only" -eq 0 ] && sed_flags="g"
[ "$ignore_case" -eq 1 ] && sed_flags="${sed_flags}I"

# ---- In-place mode: GNU sed vs BSD/macOS sed ----
if sed --version >/dev/null 2>&1; then
    # GNU sed
    if [ "$backup" -eq 1 ]; then sed_inplace=(-i.bak); else sed_inplace=(-i); fi
else
    # BSD sed (macOS) requires an explicit argument for -i
    if [ "$backup" -eq 1 ]; then sed_inplace=(-i .bak); else sed_inplace=(-i ''); fi
fi

# ---- Quick pre-check via grep (no file modification) ----
grep_flags=(-Iq -F)
[ "$ignore_case" -eq 1 ] && grep_flags+=(-i)

changed=0
skipped=0

while IFS= read -r -d '' file; do
    # Skip binary and empty files
    if ! grep -Iq . -- "$file" 2>/dev/null; then
        skipped=$((skipped + 1)); continue
    fi
    # Skip files without the search string
    if ! grep "${grep_flags[@]}" -- "$search" "$file"; then
        skipped=$((skipped + 1)); continue
    fi

    if [ "$dry_run" -eq 1 ]; then
        printf 'WOULD CHANGE: %s\n' "$file"
        changed=$((changed + 1))
        continue
    fi

    if sed "${sed_inplace[@]}" \
           "s/${esc_search}/${esc_replace}/${sed_flags}" -- "$file"; then
        printf 'CHANGED: %s\n' "$file"
        changed=$((changed + 1))
    else
        printf 'FAILED:  %s\n' "$file" >&2
    fi
done < <(find "$dir" -type f -not -path '*/.git/*' -print0)

printf '\nFiles changed: %d, files skipped: %d\n' "$changed" "$skipped"
