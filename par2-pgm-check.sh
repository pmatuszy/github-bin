#!/bin/bash
# v. 20260719.095800 - steps numbered from 1; split timing summary at end of run

# 2026.07.19 - v. 0.1.12 - Timing summary (hash/PAR2/total); renumber steps from 1 not 0
# 2026.07.19 - v. 0.1.11 - Suppress duplicate par2 OK line above RESULT banner
# 2026.07.19 - v. 0.1.10 - Scope summary: data/hash counts; list only in-scope hash manifests
# 2026.07.19 - v. 0.1.9 - Resolve PAR2 set from user path (volume ok); fix die-in-subshell fallback
# 2026.07.19 - v. 0.1.8 - Accept PAR2 volume/hash/data entry points; print detected files at start
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
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay] [path] [directory] [options]

  [path]        PAR2 index or volume file, hash manifest (.sha512/.sha256/.md5), data file,
                or directory (optional if exactly one PAR2 index is in the working directory)
  [directory]   Directory with data files (default: directory of [path] or current directory)

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

If a .sha512 / .sha256 / .md5 file exists in the directory, Step 1 scans all
hash manifests, reports how many list in-scope PAR2 archives for this set, and
verifies checksums only in those file(s). Other hash entries are ignored.

Examples:
  $(basename "$0")
  $(basename "$0") "_2015.07.19_-_kosciol,_Santa_Monica.par2"
  $(basename "$0") "archive.vol0+1.par2"
  $(basename "$0") "archive.sha512"
  $(basename "$0") "archive.par2" /path/to/files --yes
EOF
}

is_par2_volume_file() {
    local base="$1"
    [[ "$base" =~ \.vol[0-9]*[-+_][0-9]+\.par2$ ]] || [[ "$base" =~ \.vol[0-9]*[-+_][0-9]+\.PAR2$ ]]
}

is_par2_any_active_file() {
    local base="$1"
    [[ "$base" == *.par2 || "$base" == *.PAR2 ]] || return 1
    [[ "$base" == *_old.par2 || "$base" == *_old.PAR2 ]] && return 1
    return 0
}

is_hash_manifest_file() {
    local base="$1"
    case "$base" in
        *.sha512|*.SHA512|*.sha256|*.SHA256|*.md5|*.MD5) return 0 ;;
    esac
    return 1
}

is_data_file_basename() {
    local base="$1"
    case "$base" in
        *.par2|*.PAR2) return 1 ;;
        *_old.par2|*_old.PAR2) return 1 ;;
        *.sha512|*.SHA512|*.sha256|*.SHA256|*.md5|*.MD5) return 1 ;;
        par2-pgm-check.sh|par2-pgm-rename.py) return 1 ;;
    esac
    return 0
}

par2_stem_from_par2_basename() {
    local base="$1"
    base="${base%.par2}"
    base="${base%.PAR2}"
    if [[ "$base" == *_old ]]; then
        base="${base%_old}"
    fi
    if is_par2_volume_file "$1"; then
        base="$(sed -E 's/\.vol[0-9]*[-+_][0-9]+$//' <<< "$base")"
    fi
    printf '%s' "$base"
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

find_all_par2_index_files() {
    local dir="$1"
    local -n _out=$2
    local f base

    _out=()
    shopt -s nullglob
    for f in "$dir"/*.par2 "$dir"/*.PAR2; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        is_par2_index_file "$base" || continue
        _out+=("$(abs_path "$f")")
    done
    shopt -u nullglob

    if (( ${#_out[@]} > 1 )); then
        IFS=$'\n' _out=($(printf '%s\n' "${_out[@]}" | LC_ALL=C sort -f))
        unset IFS
    fi
}

par2_stems_match() {
    [[ "${1,,}" == "${2,,}" ]]
}

pgm_sort_path_array() {
    local -n _arr=$1

    if (( ${#_arr[@]} > 1 )); then
        IFS=$'\n' _arr=($(printf '%s\n' "${_arr[@]}" | LC_ALL=C sort -f))
        unset IFS
    fi
}

collect_par2_set_for_ref_file() {
    local ref="$1"
    local -n _out=$2
    local ap dir base stem f fb fstem

    _out=()
    ap="$(abs_path "$ref")"
    dir="$(dirname "$ap")"
    base="$(basename "$ap")"
    stem="$(par2_stem_from_par2_basename "$base")"

    shopt -s nullglob
    for f in "$dir"/*.par2 "$dir"/*.PAR2; do
        [[ -f "$f" ]] || continue
        fb="$(basename "$f")"
        [[ "$fb" == *_old.par2 || "$fb" == *_old.PAR2 ]] && continue
        fstem="$(par2_stem_from_par2_basename "$fb")"
        if par2_stems_match "$stem" "$fstem"; then
            _out+=("$(abs_path "$f")")
        fi
    done
    shopt -u nullglob

    if (( ${#_out[@]} == 0 )); then
        _out+=("$ap")
    fi

    pgm_sort_path_array _out
}

list_par2_set_members() {
    local dir="$1"
    local stem="$2"
    local -n _members=$3
    local f base fstem

    _members=()
    shopt -s nullglob
    for f in "$dir"/*.par2 "$dir"/*.PAR2; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        [[ "$base" == *_old.par2 || "$base" == *_old.PAR2 ]] && continue
        fstem="$(par2_stem_from_par2_basename "$base")"
        if par2_stems_match "$stem" "$fstem"; then
            _members+=("$(abs_path "$f")")
        fi
    done
    shopt -u nullglob

    pgm_sort_path_array _members
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
POSITIONAL=()
MISNAMED_DISK=()
MISNAMED_PAR2=()
RENAME_PAIRS=()
OUT2_FILE=""
RENAME_PY=""
PAR2_FILE=""
DATA_DIR=""
PAR2_RESOLVED_FROM=""
USER_DIR_INPUT=""
USER_PAR2_INPUT=""
USER_HASH_INPUT=""
USER_DATA_INPUT=""
USER_ARG_PATHS=()
PAR2_SET_MEMBERS=()
RESOLVE_PAR2_ERROR=""
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
    pgm_print_timing_summary
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

pgm_filter_par2_verify_output() {
    local text="$1"
    sed -E '/^[[:space:]]*[Aa]ll files are (ok|correct).*repair is not required\.?[[:space:]]*$/Id' <<< "$text" \
        | sed -E -e :a -e '/^\s*$/{$d;N;ba' -e '}'
}

pgm_filter_par2_verify_stream() {
    sed -E '/^[[:space:]]*[Aa]ll files are (ok|correct).*repair is not required\.?[[:space:]]*$/Id'
}

pgm_format_elapsed() {
    local s="${1:-0}" h m
    (( s < 0 )) && s=0
    h=$(( s / 3600 )); s=$(( s % 3600 ))
    m=$(( s / 60 )); s=$(( s % 60 ))
    if (( h > 0 )); then
        printf '%dh %dm %ds' "$h" "$m" "$s"
    elif (( m > 0 )); then
        printf '%dm %ds' "$m" "$s"
    else
        printf '%ds' "$s"
    fi
}

pgm_timing_lap_to() {
    local var_name="$1"
    local now=$SECONDS

    printf -v "$var_name" '%s' "$(( now - PGM_TIMING_LAST ))"
    PGM_TIMING_LAST=$now
}

pgm_print_timing_summary() {
    local total=0

    [[ -n "${PGM_RUN_START:-}" ]] || return 0
    total=$(( SECONDS - PGM_RUN_START ))

    echo
    echo "--- Timing ---"
    printf '  Hash checksum check:        %s\n' "$(pgm_format_elapsed "${PGM_TIMING_HASH_SEC:-0}")"
    if (( ${PGM_TIMING_PAR2_SCAN_SEC:-0} > 0 )); then
        printf '  PAR2 verify (names only):  %s\n' "$(pgm_format_elapsed "${PGM_TIMING_PAR2_NAMES_SEC:-0}")"
        printf '  PAR2 verify (dir scan):    %s\n' "$(pgm_format_elapsed "${PGM_TIMING_PAR2_SCAN_SEC:-0}")"
    else
        printf '  PAR2 verify:               %s\n' "$(pgm_format_elapsed "${PGM_TIMING_PAR2_NAMES_SEC:-0}")"
    fi
    printf '  Total wall time:           %s\n' "$(pgm_format_elapsed "$total")"
    echo
}

pgm_describe_path_kind() {
    local path="$1"
    local base

    if [[ -d "$path" ]]; then
        printf '%s' 'directory'
        return 0
    fi

    base="$(basename "$path")"
    if is_hash_manifest_file "$base"; then
        printf '%s' 'hash manifest'
    elif is_par2_index_file "$base"; then
        printf '%s' 'PAR2 index'
    elif is_par2_volume_file "$base"; then
        printf '%s' 'PAR2 volume'
    elif is_par2_any_active_file "$base"; then
        printf '%s' 'PAR2 file'
    else
        printf '%s' 'data file'
    fi
}

apply_file_argument() {
    local arg="$1"
    local ap base

    [[ -e "$arg" ]] || die "Path not found: $arg"
    ap="$(abs_path "$arg")"
    base="$(basename "$ap")"

    USER_ARG_PATHS+=("$ap")

    if is_hash_manifest_file "$base"; then
        [[ -z "$USER_HASH_INPUT" ]] || die "Multiple hash files specified: $arg"
        USER_HASH_INPUT="$ap"
        return 0
    fi

    if is_par2_any_active_file "$base"; then
        [[ -z "$USER_PAR2_INPUT" ]] || die "Multiple PAR2 files specified: $arg"
        USER_PAR2_INPUT="$ap"
        return 0
    fi

    if is_data_file_basename "$base"; then
        [[ -z "$USER_DATA_INPUT" ]] || die "Multiple data files specified as entry point: $arg"
        USER_DATA_INPUT="$ap"
        return 0
    fi

    die "Unrecognized file type (expected PAR2, hash manifest, or data file): $base"
}

infer_data_dir_from_inputs() {
    if [[ -n "$USER_DIR_INPUT" ]]; then
        printf '%s\n' "$USER_DIR_INPUT"
        return 0
    fi
    if [[ -n "$USER_PAR2_INPUT" ]]; then
        dirname "$USER_PAR2_INPUT"
        return 0
    fi
    if [[ -n "$USER_HASH_INPUT" ]]; then
        dirname "$USER_HASH_INPUT"
        return 0
    fi
    if [[ -n "$USER_DATA_INPUT" ]]; then
        dirname "$USER_DATA_INPUT"
        return 0
    fi
    abs_path "."
}

resolve_par2_from_user_input() {
    local input="$1"
    local ap base member mb idx=""

    RESOLVE_PAR2_ERROR=""
    PAR2_RESOLVED_FROM=""
    PAR2_SET_MEMBERS=()
    PAR2_FILE=""

    [[ -e "$input" ]] || {
        RESOLVE_PAR2_ERROR="PAR2 file not found: $input"
        return 1
    }

    ap="$(abs_path "$input")"
    base="$(basename "$ap")"
    if ! is_par2_any_active_file "$base"; then
        RESOLVE_PAR2_ERROR="Not a PAR2 file: $input"
        return 1
    fi

    collect_par2_set_for_ref_file "$ap" PAR2_SET_MEMBERS

    for member in "${PAR2_SET_MEMBERS[@]}"; do
        mb="$(basename "$member")"
        if is_par2_index_file "$mb"; then
            idx="$member"
            break
        fi
    done

    if [[ -n "$idx" ]]; then
        PAR2_FILE="$idx"
        if [[ "$ap" != "$idx" ]]; then
            PAR2_RESOLVED_FROM="$ap"
        fi
        return 0
    fi

    PAR2_FILE="$ap"
    return 0
}

pgm_path_in_array() {
    local needle="$1"
    local -n _haystack=$2
    local item

    for item in "${_haystack[@]}"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

pgm_load_hash_inventory() {
    local msg rc=0
    local -a lines=()

    HASH_INV_TOTAL=0
    HASH_INV_WITH_PAR2=0
    HASH_INV_IN_SCOPE=0
    HASH_INV_RELEVANT=()
    HASH_INV_ERROR=""

    msg=$(run_rename_py hash inventory "$DATA_DIR" "$PAR2_FILE" 2>&1) || rc=$?
    if (( rc != 0 )); then
        HASH_INV_ERROR="$msg"
        return "$rc"
    fi

    mapfile -t lines <<< "$msg"
    HASH_INV_TOTAL="${lines[0]:-0}"
    HASH_INV_WITH_PAR2="${lines[1]:-0}"
    HASH_INV_IN_SCOPE="${lines[2]:-0}"
    if (( ${#lines[@]} > 3 )); then
        HASH_INV_RELEVANT=("${lines[@]:3}")
    fi
    return 0
}

pgm_print_startup_inventory() {
    local par2_dir stem user_par2_ap=""
    local -a par2_set=() index_candidates=()
    local i other_count=0 ignored_index_count=0 marker

    par2_dir="$(dirname "$PAR2_FILE")"
    stem="$(par2_stem_from_par2_basename "$(basename "$PAR2_FILE")")"
    find_all_par2_index_files "$par2_dir" index_candidates
    if (( ${#PAR2_SET_MEMBERS[@]} > 0 )); then
        par2_set=("${PAR2_SET_MEMBERS[@]}")
    else
        list_par2_set_members "$par2_dir" "$stem" par2_set
    fi
    [[ -n "$USER_PAR2_INPUT" ]] && user_par2_ap="$(abs_path "$USER_PAR2_INPUT")"

    echo "=== PAR2 check scope ==="
    echo "Data directory : $DATA_DIR"
    if [[ "$par2_dir" != "$DATA_DIR" ]]; then
        echo "PAR2 directory : $par2_dir"
    fi
    echo

    if (( ${#USER_ARG_PATHS[@]} > 0 )); then
        echo "User specified:"
        for i in "${USER_ARG_PATHS[@]}"; do
            printf '  %s (%s)\n' "$(basename "$i")" "$(pgm_describe_path_kind "$i")"
        done
        echo
    fi

    if [[ -n "$user_par2_ap" && "$user_par2_ap" != "$PAR2_FILE" ]]; then
        echo "PAR2 entry (specified): $(basename "$user_par2_ap")"
    fi
    if is_par2_index_file "$(basename "$PAR2_FILE")"; then
        echo "PAR2 index (in use): $(basename "$PAR2_FILE")"
    else
        echo "PAR2 verify file (in use): $(basename "$PAR2_FILE")"
        echo "Note: no separate PAR2 index file found in this set."
    fi

    if [[ -n "$USER_PAR2_INPUT" ]]; then
        for i in "${index_candidates[@]}"; do
            [[ "$i" == "$PAR2_FILE" ]] && continue
            if ! pgm_path_in_array "$i" par2_set; then
                ignored_index_count=$((ignored_index_count + 1))
            fi
        done
        if (( ignored_index_count > 0 )); then
            echo "Other PAR2 index file(s) in directory (ignored): ${ignored_index_count}"
        fi
    else
        for i in "${index_candidates[@]}"; do
            [[ "$i" == "$PAR2_FILE" ]] && continue
            other_count=$((other_count + 1))
        done
        if (( other_count > 0 )); then
            echo "Other PAR2 index file(s) in PAR2 directory:"
            for i in "${index_candidates[@]}"; do
                [[ "$i" == "$PAR2_FILE" ]] && continue
                printf '  %s\n' "$(basename "$i")"
            done
        elif (( ${#index_candidates[@]} == 1 )); then
            echo "PAR2 index file(s) in PAR2 directory: 1"
        else
            echo "PAR2 index file(s) in PAR2 directory: 0"
        fi
    fi

    echo "PAR2 set (${#par2_set[@]} file(s)):"
    if (( ${#par2_set[@]} == 0 )); then
        echo "  (none besides index)"
    else
        for i in "${par2_set[@]}"; do
            marker=""
            [[ "$i" == "$PAR2_FILE" ]] && marker="  [index]"
            [[ -n "$user_par2_ap" && "$i" == "$user_par2_ap" ]] && marker="  [user argument]"
            printf '  %s%s\n' "$(basename "$i")" "$marker"
        done
    fi
    echo

    if pgm_load_hash_inventory; then
        if (( HASH_INV_TOTAL == 0 )); then
            echo "Hash files: none in directory."
        elif (( HASH_INV_IN_SCOPE == 0 )); then
            echo "Hash files: ${HASH_INV_TOTAL} in directory; none list in-scope PAR2 archive(s) for this set."
        else
            echo "Hash files: ${HASH_INV_IN_SCOPE} of ${HASH_INV_TOTAL} list in-scope PAR2 archive(s) for this set:"
            for i in "${HASH_INV_RELEVANT[@]}"; do
                marker=""
                [[ -n "$USER_HASH_INPUT" && "$(abs_path "$USER_HASH_INPUT")" == "$i" ]] && marker="  [user argument]"
                printf '  %s%s\n' "$(basename "$i")" "$marker"
            done
        fi
    else
        echo "Hash files: inventory unavailable (${HASH_INV_ERROR%%$'\n'*})"
    fi
    echo

    echo "Data files: ${#DATA_FILES[@]} in directory."
    echo
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
    pgm_print_step_header "Step 4: update PAR2 metadata"
    rename_args=("$(basename "$PAR2_FILE")")
    for i in "${RENAME_PAIRS[@]}"; do
        rename_args+=("$i")
    done
    run_rename_py "${rename_args[@]}"
    local rename_rc=$?
    (( rename_rc == 0 )) || die "PAR2 metadata update failed (exit $rename_rc)."

    echo
    pgm_print_step_header "Step 4b: restore PAR2 file timestamps"
    echo "Setting active .par2 modification times to match the original *_old.par2 backups."
    restore_par2_file_timestamps "$DATA_DIR"

    echo
    pgm_print_step_header "Step 5: update hash file"
    update_par2_hashes || die "Failed to update hash file."

    echo
    pgm_print_step_header "Step 6: verify after update"
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
            "Search Step 3 output for: File: \"...\" - is a match for \"...\"."
        return 2
    fi

    if grep -qiE 'repair is possible' "$out_file"; then
        pgm_print_outcome warn \
            "Repair is possible (damage or rename fixable)." \
            "Review Step 3 output above."
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
        "Review Step 3 output above."
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
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

POSITIONAL=("${POSITIONAL[@]:-}")
for arg in "${POSITIONAL[@]}"; do
    if [[ -d "$arg" ]]; then
        [[ -z "$USER_DIR_INPUT" ]] || die "Multiple directories specified: $arg"
        USER_DIR_INPUT="$(abs_path "$arg")"
        USER_ARG_PATHS+=("$USER_DIR_INPUT")
    elif [[ -e "$arg" ]]; then
        apply_file_argument "$arg"
    else
        die "Path not found: $arg"
    fi
done

DATA_DIR="$(infer_data_dir_from_inputs)"
DATA_DIR="$(abs_path "$DATA_DIR")"
[[ -d "$DATA_DIR" ]] || die "Directory not found: $DATA_DIR"

if [[ -n "$USER_PAR2_INPUT" ]]; then
    if ! resolve_par2_from_user_input "$USER_PAR2_INPUT"; then
        die "$RESOLVE_PAR2_ERROR"
    fi
elif [[ -z "$PAR2_FILE" ]]; then
    find_rc=0
    PAR2_FILE="$(find_par2_index_in_dir "$DATA_DIR")" || find_rc=$?
    if (( find_rc == 1 )); then
        show_help
        return_code=1
        finish
    fi
    (( find_rc == 0 )) || die "Could not select a PAR2 index file in: $DATA_DIR"
fi

command -v "$PAR2_CMD" >/dev/null 2>&1 || die "'$PAR2_CMD' not found. Install par2cmdline or set PAR2_CMD."
command -v "$PYTHON_CMD" >/dev/null 2>&1 || die "'$PYTHON_CMD' not found."

PAR2_FILE="$(abs_path "$PAR2_FILE")"
[[ -f "$PAR2_FILE" ]] || die "PAR2 file not found: $PAR2_FILE"

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

pgm_print_startup_inventory

PGM_RUN_START=$SECONDS
PGM_TIMING_LAST=$SECONDS
PGM_TIMING_HASH_SEC=0
PGM_TIMING_PAR2_NAMES_SEC=0
PGM_TIMING_PAR2_SCAN_SEC=0

pgm_print_step_header "Step 1: verify PAR2 archive checksums"
if ! verify_par2_hashes; then
    die "PAR2 archive checksum verification failed. Refusing to scan for misnamed files."
fi
pgm_timing_lap_to PGM_TIMING_HASH_SEC

pgm_print_step_header "Step 2: verify (PAR2 names only)"
OUT1=$(run_par2 verify "$PAR2_FILE" 2>&1)
RC1=$?
pgm_timing_lap_to PGM_TIMING_PAR2_NAMES_SEC
printf '%s\n\n' "$(pgm_filter_par2_verify_output "$OUT1")"

if pgm_par2_output_indicates_ok "$OUT1"; then
    par2_ok_line="$(pgm_extract_par2_ok_line "$OUT1")"
    pgm_print_outcome ok \
        "All files OK under PAR2 names." \
        "${par2_ok_line:-Verification passed under PAR2 names only.}"
    return_code=0
    finish
fi

pgm_print_step_header "Step 3: verify with directory scan (detect misnamed files)"
OUT2_FILE=$(mktemp "${TMPDIR:-/tmp}/par2-pgm-check.XXXXXX")
run_par2 verify "$PAR2_FILE" "${DATA_FILES[@]}" 2>&1 | tee "$OUT2_FILE" | pgm_filter_par2_verify_stream
RC2=${PIPESTATUS[0]}
pgm_timing_lap_to PGM_TIMING_PAR2_SCAN_SEC
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
