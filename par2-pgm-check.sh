#!/bin/bash
# v. 20260719.092500 - boxed step headers and prominent RESULT banners

# 2026.07.19 - v. 0.1.7 - Step/RESULT lines use boxes (Unicode fallback) for visibility on PuTTY
# 2026.07.19 - v. 0.1.6 - Step 0: scan all hash files; report how many list in-scope PAR2 entries
# 2026.07.19 - v. 0.1.5 - Step 0: verify only in-scope PAR2 set in hash file; skip if hash has no .par2 lines
# 2026.07.18 - v. 0.1.4 - Step 3b: keep active .par2 dates matching original *_old.par2 backups
# 2026.07.18 - v. 0.1.1 - github-bin consistency: show_help, print_version_banner, script footer
# 2026.07.18 - v. 0.1.0 - initial release: misnamed-file detection, hash gate, interactive PAR2 metadata update
#
# par2-pgm-check.sh
#
# Verify a PAR2 set and detect misnamed files in a directory.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay] [par2-file] [directory] [options]

  [par2-file]   Main PAR2 index file (optional if exactly one index .par2 is in the directory)
  [directory]   Directory with data files (default: current directory or directory of <par2-file>)

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
  --repair             Repair damaged data and rename misnamed files to PAR2 names
  --yes, -y            Update PAR2 metadata without prompting when misnamed files found
  --no-rename          Detect misnamed files but do not offer/run PAR2 metadata update

Environment:
  PAR2_CMD             par2 executable (default: par2)
  PYTHON_CMD           python3 executable (default: python3)

If a .sha512 / .sha256 / .md5 file exists in the directory, Step 0 scans all
hash manifests, reports how many list in-scope PAR2 archives for this set, and
verifies checksums only in those file(s). Other hash entries are ignored.

Examples:
  $(basename "$0")
  $(basename "$0") "_2015.07.19_-_kosciol,_Santa_Monica.par2"
  $(basename "$0") "archive.par2" /path/to/files --yes
EOF
}

is_par2_index_file() {
    local base="$1"
    [[ "$base" == *.par2 || "$base" == *.PAR2 ]] || return 1
    [[ "$base" == *_old.par2 ]] && return 1
    [[ "$base" =~ \.vol[0-9]*[-+_][0-9]+\.par2$ ]] && return 1
    return 0
}

find_par2_index_in_dir() {
    local dir="$1"
    local f base
    local -a candidates=()

    shopt -s nullglob
    for f in "$dir"/*.par2 "$dir"/*.PAR2; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        is_par2_index_file "$base" || continue
        candidates+=("$f")
    done
    shopt -u nullglob

    if (( ${#candidates[@]} == 1 )); then
        printf '%s\n' "${candidates[0]}"
        return 0
    fi
    if (( ${#candidates[@]} == 0 )); then
        return 1
    fi

    echo "Multiple PAR2 index files found in $dir - specify which one to use:" >&2
    printf '  %s\n' "${candidates[@]}" >&2
    return 2
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

PAR2_CMD="${PAR2_CMD:-par2}"
PYTHON_CMD="${PYTHON_CMD:-python3}"
REPAIR=0
AUTO_RENAME=0
NO_RENAME=0
MISNAMED_DISK=()
MISNAMED_PAR2=()
RENAME_PAIRS=()
OUT2_FILE=""
RENAME_PY=""
PAR2_FILE=""
DATA_DIR=""
PROMPT_TIMEOUT="${PROMPT_TIMEOUT:-20}"

cleanup() {
    [[ -n "$OUT2_FILE" && -f "$OUT2_FILE" ]] && rm -f "$OUT2_FILE"
}
trap cleanup EXIT

die() {
    echo "Error: $*" >&2
    return_code=1
    . /root/bin/_script_footer.sh
    exit 1
}

finish() {
    local rc="${return_code:-0}"
    . /root/bin/_script_footer.sh
    exit "$rc"
}

PGM_HAVE_BOXES=no
if command -v boxes >/dev/null 2>&1; then
    PGM_HAVE_BOXES=yes
fi

pgm_emit_unicode_box() {
    local -a lines=( "$@" )
    local max_len=0 line w

    for line in "${lines[@]}"; do
        (( ${#line} > max_len )) && max_len=${#line}
    done
    (( max_len < 52 )) && max_len=52
    w=$(( max_len + 2 ))

    printf '┌%*s┐\n' "$w" '' | tr ' ' '─'
    for line in "${lines[@]}"; do
        printf '│ %-*s │\n' "$max_len" "$line"
    done
    printf '└%*s┘\n' "$w" '' | tr ' ' '─'
}

pgm_emit_boxed_block() {
    local design="$1"
    shift
    local -a lines=( "$@" )

    if [[ "$PGM_HAVE_BOXES" == yes ]]; then
        printf '%s\n' "${lines[@]}" | boxes -a c -d "$design"
    else
        pgm_emit_unicode_box "${lines[@]}"
    fi
}

pgm_print_step_header() {
    local title="$1"
    echo
    pgm_emit_boxed_block stone "$title"
    echo
}

pgm_outcome_header_for_kind() {
    case "$1" in
        ok)   printf '%s' '*** RESULT: OK ***' ;;
        warn) printf '%s' '*** RESULT: ATTENTION NEEDED ***' ;;
        err)  printf '%s' '*** RESULT: PROBLEM ***' ;;
        *)    printf '%s' '*** RESULT ***' ;;
    esac
}

pgm_print_outcome() {
    local kind="$1"
    shift
    local -a body=( "$@" )
    local -a lines
    local design=stone

    lines=( "$(pgm_outcome_header_for_kind "$kind")" )
    lines+=( "${body[@]}" )

    case "$kind" in
        ok) design=ada-box ;;
    esac

    echo
    pgm_emit_boxed_block "$design" "${lines[@]}"
    echo
}

pgm_par2_output_indicates_ok() {
    grep -qiE 'repair is not required|all files are (ok|correct)' <<< "$1"
}

pgm_extract_par2_ok_line() {
    grep -iE 'repair is not required|all files are (ok|correct)' <<< "$1" \
        | head -n 1 \
        | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//'
}

abs_path() {
    local path="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath "$path"
    else
        (
            cd "$(dirname "$path")" || exit 1
            echo "$(pwd -P)/$(basename "$path")"
        )
    fi
}

collect_data_files() {
    local dir="$1"
    local f base
    DATA_FILES=()
    shopt -s nullglob
    for f in "$dir"/*; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        case "$base" in
            *.par2|*.PAR2) continue ;;
            *_old.par2) continue ;;
            *.sha512|*.SHA512|*.sha256|*.SHA256|*.md5|*.MD5) continue ;;
            par2-pgm-check.sh|par2-pgm-rename.py) continue ;;
        esac
        DATA_FILES+=("$f")
    done
    shopt -u nullglob
}

run_par2() {
    local mode="$1"
    shift
    "$PAR2_CMD" "$mode" "$@"
}

run_rename_py() {
    "$PYTHON_CMD" "$RENAME_PY" "$@"
}

verify_par2_hashes() {
    local msg rc
    msg=$(run_rename_py hash verify "$DATA_DIR" "$PAR2_FILE" 2>&1) || true
    rc=$?
    echo "$msg"
    return "$rc"
}

update_par2_hashes() {
    local msg rc
    msg=$(run_rename_py hash update "$DATA_DIR" "$PAR2_FILE" 2>&1) || true
    rc=$?
    echo "$msg"
    return "$rc"
}

restore_par2_file_timestamps() {
    local dir="$1"
    local f backup_base active restored=0

    shopt -s nullglob
    for f in "$dir"/*_old.par2 "$dir"/*_old.PAR2; do
        [[ -f "$f" ]] || continue
        backup_base="$(basename -- "$f")"
        backup_base="${backup_base%_old.par2}"
        backup_base="${backup_base%_old.PAR2}"
        active=""
        if [[ -f "$dir/${backup_base}.par2" ]]; then
            active="$dir/${backup_base}.par2"
        elif [[ -f "$dir/${backup_base}.PAR2" ]]; then
            active="$dir/${backup_base}.PAR2"
        fi
        [[ -n "$active" ]] || continue
        touch -r "$f" -- "$active"
        printf '  %s\n' "$(basename -- "$active")"
        restored=$((restored + 1))
    done
    shopt -u nullglob

    if (( restored > 0 )); then
        echo "Restored original timestamps on ${restored} PAR2 file(s) (from *_old.par2 backup dates)."
    fi
}

extract_misnamed_pairs() {
    local out_file="$1"
    local disk_file par2_name

    MISNAMED_DISK=()
    MISNAMED_PAR2=()
    RENAME_PAIRS=()

    command -v "$PYTHON_CMD" >/dev/null 2>&1 || die "'$PYTHON_CMD' not found (needed to parse par2 output)."

    while IFS='|' read -r disk_file par2_name; do
        [[ -n "$disk_file" && -n "$par2_name" ]] || continue
        MISNAMED_DISK+=("$disk_file")
        MISNAMED_PAR2+=("$par2_name")
        RENAME_PAIRS+=("${par2_name}//${disk_file}")
    done < <("$PYTHON_CMD" - "$out_file" <<'PY'
import re
import sys

path = sys.argv[1]
with open(path, "rb") as handle:
    text = handle.read().decode("utf-8", errors="replace").replace("\r", "")

for line in text.split("\n"):
    if "is a match for" not in line or "File:" not in line:
        continue
    line = (
        line.replace("\u201c", '"')
        .replace("\u201d", '"')
        .replace("\u00ab", '"')
        .replace("\u00bb", '"')
    )
    match = re.search(
        r'File:\s*"([^"]+)"\s.*?\bis a match for\s*"([^"]+)"',
        line,
    )
    if match:
        print(f"{match.group(1)}|{match.group(2).rstrip('.')}")
PY
    )
}

prompt_and_apply_rename() {
    local i ans rename_args=()

    (( ${#RENAME_PAIRS[@]} > 0 )) || return 0

    if (( NO_RENAME == 1 )); then
        return 0
    fi

    if (( AUTO_RENAME == 0 )); then
        echo
        echo "Misnamed files can be fixed by updating filenames inside the PAR2 set"
        echo "(disk filenames stay unchanged)."
        echo "PAR2 index file: $(basename "$PAR2_FILE")"
        if ! read -t "$PROMPT_TIMEOUT" -r -p "Update PAR2 archives with the new filenames? [Y/n] (auto-yes in ${PROMPT_TIMEOUT}s) " ans; then
            ans=Y
            echo
        fi
        [[ -z "$ans" ]] && ans=Y
        case "$ans" in
            n|N|no|NO) echo "Skipped PAR2 metadata update."; return 0 ;;
        esac
    fi

    echo
    pgm_print_step_header "Step 3: update PAR2 metadata"
    rename_args=("$(basename "$PAR2_FILE")")
    for i in "${RENAME_PAIRS[@]}"; do
        rename_args+=("$i")
    done
    run_rename_py "${rename_args[@]}"
    local rename_rc=$?
    (( rename_rc == 0 )) || die "PAR2 metadata update failed (exit $rename_rc)."

    echo
    pgm_print_step_header "Step 3b: restore PAR2 file timestamps"
    echo "Setting active .par2 modification times to match the original *_old.par2 backups."
    restore_par2_file_timestamps "$DATA_DIR"

    echo
    pgm_print_step_header "Step 4: update hash file"
    update_par2_hashes || die "Failed to update hash file."

    echo
    pgm_print_step_header "Step 5: verify after update"
    run_par2 verify "$PAR2_FILE"
}

print_summary() {
    local out_file="$1"
    local missing=0
    local matches=0
    local wrong=""
    local rename_cmd
    local i
    local line

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line//$'\r'/}"
        case "$line" in
            Target:*" - missing.")
                echo "$line"
                missing=$((missing + 1))
                ;;
        esac
    done < "$out_file"

    wrong=$(grep -E '[0-9]+ file\(s\) have the wrong name\.' "$out_file" | head -1 || true)

    extract_misnamed_pairs "$out_file"
    matches=${#MISNAMED_DISK[@]}

    for i in "${!MISNAMED_DISK[@]}"; do
        echo "File: \"${MISNAMED_DISK[$i]}\" - is a match for \"${MISNAMED_PAR2[$i]}\"."
    done

    echo
    echo "Summary:"
    echo "  Missing targets (by PAR2 name): ${missing}"
    echo "  Content matches found on disk:  ${matches}"
    [[ -n "$wrong" ]] && echo "  ${wrong}"

    if (( matches > 0 )); then
        echo
        echo "Misnamed files detected (same data, different name on disk):"
        rename_cmd="./par2-pgm-rename.py $(printf '%q' "$(basename "$PAR2_FILE")")"
        for i in "${!MISNAMED_PAR2[@]}"; do
            printf '  PAR2 expects: %s\n' "${MISNAMED_PAR2[$i]}"
            printf '  Found on disk: %s\n' "${MISNAMED_DISK[$i]}"
            echo
            rename_cmd+=" $(printf '%q' "${MISNAMED_PAR2[$i]}//${MISNAMED_DISK[$i]}")"
        done
        if (( NO_RENAME == 0 && AUTO_RENAME == 0 )); then
            echo "You will be asked whether to update PAR2 metadata (default: yes, ${PROMPT_TIMEOUT}s timeout)."
        elif (( AUTO_RENAME == 1 )); then
            echo "PAR2 metadata will be updated automatically (--yes)."
        else
            echo "Manual command if needed:"
            echo
            echo "$rename_cmd"
        fi
        pgm_print_outcome warn \
            "Misnamed file(s) detected (same data, different name on disk)." \
            "See details above; update PAR2 metadata or use --no-rename."
        return 2
    fi

    if pgm_par2_output_indicates_ok "$out_file"; then
        local par2_ok_line
        par2_ok_line="$(pgm_extract_par2_ok_line "$out_file")"
        pgm_print_outcome ok \
            "Verification passed (directory scan)." \
            "${par2_ok_line:-All files match under PAR2 names.}"
        return 0
    fi

    if [[ -n "$wrong" ]]; then
        pgm_print_outcome warn \
            "Wrong PAR2 filename(s) detected, but rename pairs could not be parsed." \
            "Search Step 2 output for: File: \"...\" - is a match for \"...\"."
        return 2
    fi

    if grep -qiE 'repair is possible' "$out_file"; then
        pgm_print_outcome warn \
            "Repair is possible (damage or rename fixable)." \
            "Review Step 2 output above."
        return 2
    fi

    if (( missing > 0 )); then
        pgm_print_outcome err \
            "Files are missing and no content match was found in the directory." \
            "Missing targets (by PAR2 name): ${missing}"
        return 3
    fi

    pgm_print_outcome err \
        "Verification reported problems." \
        "Review Step 2 output above."
    return 2
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            . /root/bin/_script_footer.sh
            exit 0
            ;;
        -v|--version)
            print_version_banner
            . /root/bin/_script_footer.sh
            exit 0
            ;;
        --repair)
            REPAIR=1
            shift
            ;;
        --yes|-y)
            AUTO_RENAME=1
            shift
            ;;
        --no-rename)
            NO_RENAME=1
            shift
            ;;
        -*)
            echo "Unknown option: $1 (try --help)" >&2
            return_code=1
            finish
            ;;
        *)
            if [[ -z "$PAR2_FILE" ]]; then
                PAR2_FILE="$1"
            elif [[ -z "$DATA_DIR" ]]; then
                DATA_DIR="$1"
            else
                die "Unexpected argument: $1"
            fi
            shift
            ;;
    esac
done

if [[ -n "$PAR2_FILE" && -d "$PAR2_FILE" && -z "$DATA_DIR" ]]; then
    DATA_DIR="$PAR2_FILE"
    PAR2_FILE=""
fi

if [[ -z "$PAR2_FILE" ]]; then
    search_dir="${DATA_DIR:-.}"
    search_dir="$(abs_path "$search_dir")"
    [[ -d "$search_dir" ]] || die "Directory not found: $search_dir"
    find_rc=0
    PAR2_FILE="$(find_par2_index_in_dir "$search_dir")" || find_rc=$?
    if (( find_rc == 1 )); then
        show_help
        return_code=1
        finish
    fi
    (( find_rc == 0 )) || die "Could not select a PAR2 index file in: $search_dir"
    echo "Using PAR2 index: $(basename "$PAR2_FILE")"
fi

command -v "$PAR2_CMD" >/dev/null 2>&1 || die "'$PAR2_CMD' not found. Install par2cmdline or set PAR2_CMD."
command -v "$PYTHON_CMD" >/dev/null 2>&1 || die "'$PYTHON_CMD' not found."

PAR2_FILE="$(abs_path "$PAR2_FILE")"
[[ -f "$PAR2_FILE" ]] || die "PAR2 file not found: $PAR2_FILE"

if [[ -z "$DATA_DIR" ]]; then
    DATA_DIR="$(dirname "$PAR2_FILE")"
else
    DATA_DIR="$(abs_path "$DATA_DIR")"
fi

[[ -d "$DATA_DIR" ]] || die "Directory not found: $DATA_DIR"

RENAME_PY="$DATA_DIR/par2-pgm-rename.py"
if [[ -f "$RENAME_PY" ]]; then
    :
elif [[ -f "$(dirname "${BASH_SOURCE[0]}")/par2-pgm-rename.py" ]]; then
    RENAME_PY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/par2-pgm-rename.py"
elif command -v par2-pgm-rename.py >/dev/null 2>&1; then
    RENAME_PY="$(command -v par2-pgm-rename.py)"
else
    die "par2-pgm-rename.py not found in PATH, script directory, or: $DATA_DIR"
fi

collect_data_files "$DATA_DIR"
(( ${#DATA_FILES[@]} > 0 )) || die "No data files found in: $DATA_DIR"

echo "PAR2 file : $PAR2_FILE"
echo "Directory : $DATA_DIR"
echo "Data files: ${#DATA_FILES[@]}"
echo

pgm_print_step_header "Step 0: verify PAR2 archive checksums"
if ! verify_par2_hashes; then
    die "PAR2 archive checksum verification failed. Refusing to scan for misnamed files."
fi

pgm_print_step_header "Step 1: verify (PAR2 names only)"
OUT1=$(run_par2 verify "$PAR2_FILE" 2>&1)
RC1=$?
printf '%s\n\n' "$OUT1"

if pgm_par2_output_indicates_ok "$OUT1"; then
    par2_ok_line="$(pgm_extract_par2_ok_line "$OUT1")"
    pgm_print_outcome ok \
        "All files OK under PAR2 names." \
        "${par2_ok_line:-Verification passed under PAR2 names only.}"
    return_code=0
    finish
fi

pgm_print_step_header "Step 2: verify with directory scan (detect misnamed files)"
OUT2_FILE=$(mktemp "${TMPDIR:-/tmp}/par2-pgm-check.XXXXXX")
run_par2 verify "$PAR2_FILE" "${DATA_FILES[@]}" 2>&1 | tee "$OUT2_FILE"
RC2=${PIPESTATUS[0]}
echo

print_summary "$OUT2_FILE"
SUMMARY_RC=$?

if (( SUMMARY_RC == 2 && ${#RENAME_PAIRS[@]} > 0 )); then
    prompt_and_apply_rename
fi

if (( REPAIR == 1 )); then
    pgm_print_step_header "Repair (disk rename)"
    echo "Note: par2 repair renames disk files to match PAR2, not the other way around."
    set +e
    run_par2 repair "$PAR2_FILE" "${DATA_FILES[@]}"
    return_code=$?
    set -e
    finish
fi

return_code=$SUMMARY_RC
finish
