#!/usr/bin/env bash
# 2026.04.02 - v. 5.7 - remove _OSiOLEK.com and LEK.PL fragments from names
# 2026.04.02 - v. 5.6 - update only local hash files after plain file/directory renames and verify only changed checksum files
# 2026.04.02 - v. 5.5 - support comments in _exclude-rename.sh.txt with lines starting with #
# 2026.04.02 - v. 5.4 - added mojibake replacement Ĺ� -> L
# 2026.04.02 - v. 5.3 - normalize _exclude-rename.sh.txt from CRLF to LF before loading and expand mojibake fixes
# 2026.04.02 - v. 5.2 - expanded mojibake replacements and kept whole-script delivery
# 2026.04.02 - v. 5.1 - support local exclude filters from _exclude-rename.sh.txt
# 2026.04.01 - v. 5.0 - added mojibake replacements for selected broken Polish characters
# 2026.04.01 - v. 4.9 - process deeper paths first to avoid stale child paths after parent directory renames
# 2026.04.01 - v. 4.8 - ask before checking large hash files in real mode
# 2026.04.01 - v. 4.7 - nicer startup banner and flush terminal input buffer before interactive reads
# 2026.04.01 - v. 4.6 - sort processed entries alphabetically and print version info at startup
# 2026.04.01 - v. 4.5 - clarify recovery logging and always normalize hash files to Unix format before checks in real mode
# 2026.04.01 - v. 4.4 - add rollback of current checksum-group operation on Ctrl-C
# 2026.03.31 - v. 4.3 - fixed missing VERBOSE_MAIN_EVERY variable in verbose mode
# 2026.03.31 - v. 4.2 - removed whole-tree path discovery; use local directory processing only
# 2026.03.31 - v. 4.1 - verbose logs go to stderr so command substitutions are not corrupted
# 2026.03.31 - v. 4.0 - removed slow whole-tree recovery fallback; only fast same-directory recovery is used
# 2026.03.31 - v. 3.9 - fast same-directory recovery for normalized missing checksum refs
# 2026.03.31 - v. 3.8 - added ERR trap to show line number, exit code, and failed command
# 2026.03.31 - v. 3.7 - fixed silent exits caused by set -e with post-increment arithmetic
# 2026.03.31 - v. 3.6 - only do checksum verification when renames or checksum-file modifications are actually needed
# 2026.03.31 - v. 3.4 - added -v / --verbose logging
# 2026.03.31 - v. 3.3 - verify checksum files from their own directory
# 2026.03.31 - v. 3.1 - print clear info after Windows to Unix checksum file conversion was actually done
# 2026.03.31 - v. 3.0 - always normalize checksum files from CRLF to LF before any checks in real mode
# 2026.03.31 - v. 2.8 - treat .sha512 and .md5 with exactly the same logic
# 2026.03.31 - v. 2.7 - stop the whole script immediately when checksum verification fails
# 2026.03.31 - v. 2.6 - add .md5 support with before/after verification and content updates
# 2026.03.27 - v. 2.0 - preserve original top-level path style (with or without ./) in transform_name()
# 2026.03.27 - v. 1.8 - added Call_recording rule
# 2026.03.27 - v. 1.7 - made Sprache/Voice/Screen_Recording patterns tolerant to -/_ after normalization
# 2026.03.27 - v. 1.6 - in real mode, default answer is YES for rename prompts
# 2026.03.27 - v. 1.5 - added question: current directory only vs also subdirectories
# 2026.03.27 - v. 1.4 - apply special media renames after basic normalization
# 2026.03.27 - v. 1.3 - fixed top-level path handling: keep ./ prefix in transform_name()
# 2026.03.27 - v. 1.2 - added many changes about media files

SCRIPT_VERSION="2026.04.02 - v. 5.7"
LARGE_HASHFILE_LINE_THRESHOLD=20
EXCLUDE_FILTERS_FILE="./_exclude-rename.sh.txt"

set -Eeuo pipefail
shopt -s nullglob

VERBOSE=0
VERBOSE_MAIN_EVERY=200

CURRENT_OP_ACTIVE=0
CURRENT_OP_LABEL=""
CURRENT_OP_SUM_OLD=""
CURRENT_OP_SUM_NEW=""
CURRENT_OP_SUM_RENAMED=0
CURRENT_OP_CONTENT_FILE=""
CURRENT_OP_CONTENT_BACKUP=""
declare -a CURRENT_OP_FILE_OLDS=()
declare -a CURRENT_OP_FILE_NEWS=()

declare -a EXCLUDE_FILTERS=()

on_err() {
    local exit_code="$1"
    local line_no="$2"
    local cmd="$3"
    echo
    echo "ERROR: command failed at line $line_no with exit code $exit_code" >&2
    echo "FAILED COMMAND: $cmd" >&2
}
trap 'on_err "$?" "$LINENO" "$BASH_COMMAND"' ERR

usage() {
    cat <<'EOF'
Usage: rename.sh [-v|--verbose] [-h|--help]

Options:
  -v, --verbose   Show extra diagnostic output
  -h, --help      Show this help
EOF
}

flush_stdin() {
    local discard
    while IFS= read -r -t 0 -n 1 discard; do
        :
    done
}

preserve_timestamps_inplace() {
    local file="$1"; shift
    local ref
    ref="$(mktemp)"
    touch -r "$file" "$ref"
    "$@"
    touch -r "$ref" "$file"
    rm -f "$ref"
}

text_file_has_crlf() {
    local f="$1"
    LC_ALL=C grep -q $'\r' -- "$f"
}

normalize_text_file_to_unix() {
    local f="$1"

    if command -v dos2unix >/dev/null 2>&1; then
        preserve_timestamps_inplace "$f" dos2unix -q -- "$f"
    else
        preserve_timestamps_inplace "$f" sed -i 's/\r$//' -- "$f"
    fi
}

normalize_exclude_filters_file_if_needed() {
    [[ -f "$EXCLUDE_FILTERS_FILE" ]] || return 0

    if text_file_has_crlf "$EXCLUDE_FILTERS_FILE"; then
        echo "Exclude filter file normalize: converting CRLF to LF: $EXCLUDE_FILTERS_FILE"
        normalize_text_file_to_unix "$EXCLUDE_FILTERS_FILE"
        echo "Exclude filter file normalize done: converted from Windows format to Unix format: $EXCLUDE_FILTERS_FILE"
    fi
}

load_exclude_filters() {
    local line
    EXCLUDE_FILTERS=()

    [[ -f "$EXCLUDE_FILTERS_FILE" ]] || return 0

    normalize_exclude_filters_file_if_needed

    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line%$'\r'}"
        [[ -n "$line" ]] || continue
        [[ "$line" =~ ^# ]] && continue
        EXCLUDE_FILTERS+=( "$line" )
    done < "$EXCLUDE_FILTERS_FILE"
}

is_excluded_by_filter_file() {
    local p="$1"
    local filter

    for filter in "${EXCLUDE_FILTERS[@]}"; do
        if [[ "$p" == *"$filter"* ]]; then
            return 0
        fi
    done
    return 1
}

for arg in "$@"; do
    case "$arg" in
        -v|--verbose)
            VERBOSE=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

load_exclude_filters

echo
echo "============================================================"
echo "  rename.sh  •  safe media + checksum rename helper"
echo "  version: $SCRIPT_VERSION"
echo "============================================================"

if [[ -f "$EXCLUDE_FILTERS_FILE" ]]; then
    echo
    echo "Exclude filter file detected: $EXCLUDE_FILTERS_FILE"
    echo "Loaded filters: ${#EXCLUDE_FILTERS[@]}"
fi

echo
echo "Use colors?"
echo "  [Y] Yes (default)"
echo "  [N] No"
echo "  [Q] Quit"
echo -n "Choice [Y/n/q]: "

use_colors=yes
input=""

flush_stdin
read -t 60 -n 1 input || true
echo

if [[ "$input" =~ [Qq] ]]; then
    echo "Quitting."
    exit 0
elif [[ "$input" =~ [Nn] ]]; then
    use_colors=no
fi

if [[ "$use_colors" == "yes" ]]; then
    RED='\e[31m'
    GREEN='\e[32m'
    CYAN='\e[36m'
    YELLOW='\e[33m'
    RESET='\e[0m'
else
    RED=''
    GREEN=''
    CYAN=''
    YELLOW=''
    RESET=''
fi

ARROW="→"

vlog() {
    (( VERBOSE == 1 )) || return 0
    echo -e "${CYAN}[VERBOSE]${RESET} $*" >&2
}

rollback_current_operation() {
    local idx old new

    (( CURRENT_OP_ACTIVE == 1 )) || return 0

    echo
    echo -e "${YELLOW}INTERRUPT:${RESET} Ctrl-C received. Reverting current ${CURRENT_OP_LABEL,,} operation..."

    if [[ -n "$CURRENT_OP_CONTENT_FILE" && -n "$CURRENT_OP_CONTENT_BACKUP" && -e "$CURRENT_OP_CONTENT_BACKUP" ]]; then
        if [[ -e "$CURRENT_OP_CONTENT_FILE" ]]; then
            cp -p -- "$CURRENT_OP_CONTENT_BACKUP" "$CURRENT_OP_CONTENT_FILE"
            echo -e "${CYAN}ROLLBACK:${RESET} restored content of: $CURRENT_OP_CONTENT_FILE"
        elif [[ "$CURRENT_OP_SUM_RENAMED" -eq 1 && -e "$CURRENT_OP_SUM_NEW" ]]; then
            cp -p -- "$CURRENT_OP_CONTENT_BACKUP" "$CURRENT_OP_SUM_NEW"
            echo -e "${CYAN}ROLLBACK:${RESET} restored content of: $CURRENT_OP_SUM_NEW"
        fi
    fi

    if [[ "$CURRENT_OP_SUM_RENAMED" -eq 1 && -e "$CURRENT_OP_SUM_NEW" ]]; then
        mv -f -- "$CURRENT_OP_SUM_NEW" "$CURRENT_OP_SUM_OLD"
        echo -e "${CYAN}ROLLBACK:${RESET} ${CURRENT_OP_LABEL} file renamed back:"
        echo "  $CURRENT_OP_SUM_NEW -> $CURRENT_OP_SUM_OLD"
    fi

    for (( idx=${#CURRENT_OP_FILE_OLDS[@]}-1; idx>=0; idx-- )); do
        old="${CURRENT_OP_FILE_OLDS[$idx]}"
        new="${CURRENT_OP_FILE_NEWS[$idx]}"
        if [[ -e "$new" ]]; then
            mv -f -- "$new" "$old"
            echo -e "${CYAN}ROLLBACK:${RESET} referenced file renamed back:"
            echo "  $new -> $old"
        fi
    done

    if [[ -n "$CURRENT_OP_CONTENT_BACKUP" && -e "$CURRENT_OP_CONTENT_BACKUP" ]]; then
        rm -f -- "$CURRENT_OP_CONTENT_BACKUP"
    fi

    CURRENT_OP_ACTIVE=0
    CURRENT_OP_LABEL=""
    CURRENT_OP_SUM_OLD=""
    CURRENT_OP_SUM_NEW=""
    CURRENT_OP_SUM_RENAMED=0
    CURRENT_OP_CONTENT_FILE=""
    CURRENT_OP_CONTENT_BACKUP=""
    CURRENT_OP_FILE_OLDS=()
    CURRENT_OP_FILE_NEWS=()

    echo -e "${GREEN}ROLLBACK DONE.${RESET}"
}

on_interrupt() {
    trap - INT
    rollback_current_operation
    exit 130
}
trap 'on_interrupt' INT

begin_current_operation() {
    local label="$1"
    local sum_old="$2"
    local sum_new="$3"

    CURRENT_OP_ACTIVE=1
    CURRENT_OP_LABEL="$label"
    CURRENT_OP_SUM_OLD="$sum_old"
    CURRENT_OP_SUM_NEW="$sum_new"
    CURRENT_OP_SUM_RENAMED=0
    CURRENT_OP_CONTENT_FILE="$sum_old"
    CURRENT_OP_CONTENT_BACKUP="$(mktemp)"
    cp -p -- "$sum_old" "$CURRENT_OP_CONTENT_BACKUP"
    CURRENT_OP_FILE_OLDS=()
    CURRENT_OP_FILE_NEWS=()
}

register_current_file_rename() {
    local old="$1"
    local new="$2"
    CURRENT_OP_FILE_OLDS+=( "$old" )
    CURRENT_OP_FILE_NEWS+=( "$new" )
}

mark_current_sum_renamed() {
    CURRENT_OP_SUM_RENAMED=1
    CURRENT_OP_CONTENT_FILE="$CURRENT_OP_SUM_NEW"
}

finish_current_operation() {
    if [[ -n "$CURRENT_OP_CONTENT_BACKUP" && -e "$CURRENT_OP_CONTENT_BACKUP" ]]; then
        rm -f -- "$CURRENT_OP_CONTENT_BACKUP"
    fi

    CURRENT_OP_ACTIVE=0
    CURRENT_OP_LABEL=""
    CURRENT_OP_SUM_OLD=""
    CURRENT_OP_SUM_NEW=""
    CURRENT_OP_SUM_RENAMED=0
    CURRENT_OP_CONTENT_FILE=""
    CURRENT_OP_CONTENT_BACKUP=""
    CURRENT_OP_FILE_OLDS=()
    CURRENT_OP_FILE_NEWS=()
}

echo
echo "Select mode:"
echo "  [D] Dry-run (default)"
echo "  [R] Real rename (interactive)"
echo "  [Q] Quit"
echo -n "Choice [D/r/q]: "

mode="dry-run"
input=""

flush_stdin
read -t 60 -n 1 input || true
echo

if [[ "$input" =~ [Qq] ]]; then
    echo "Quitting."
    exit 0
elif [[ "$input" =~ [Rr] ]]; then
    mode="real"
fi

echo -e "Mode selected: ${CYAN}$mode${RESET}"

echo
echo "What should be processed?"
echo "  [C] Current directory only (default)"
echo "  [S] Also subdirectories"
echo "  [Q] Quit"
echo -n "Choice [C/s/q]: "

process_scope="current"
input=""

flush_stdin
read -t 60 -n 1 input || true
echo

if [[ "$input" =~ [Qq] ]]; then
    echo "Quitting."
    exit 0
elif [[ "$input" =~ [Ss] ]]; then
    process_scope="subdirs"
fi

echo -e "Scope selected: ${CYAN}$process_scope${RESET}"
sleep 1

vlog "Verbose mode enabled"

is_excluded_path() {
    local p="$1"
    [[ "$(basename -- "$p")" == "[Originals]" ]]
}

is_checksum_file() {
    local p="$1"
    [[ "$p" == *.sha512 || "$p" == *.md5 ]]
}

checksum_kind() {
    local p="$1"
    if [[ "$p" == *.sha512 ]]; then
        printf 'sha512'
    elif [[ "$p" == *.md5 ]]; then
        printf 'md5'
    else
        return 1
    fi
}

checksum_label() {
    local p="$1"
    case "$(checksum_kind "$p")" in
        sha512) printf 'SHA512' ;;
        md5)    printf 'MD5' ;;
    esac
}

checksum_cmd() {
    local p="$1"
    case "$(checksum_kind "$p")" in
        sha512) printf 'sha512sum' ;;
        md5)    printf 'md5sum' ;;
    esac
}

count_checksum_entries() {
    local sum_file="$1"
    awk 'NF > 0 {count++} END {print count+0}' < <(extract_checksum_entries "$sum_file")
}

confirm_large_hash_check() {
    local sum_file="$1"
    local label="$2"
    local line_count="$3"
    local answer=""

    if (( line_count <= LARGE_HASHFILE_LINE_THRESHOLD )); then
        return 0
    fi

    echo
    echo -e "${YELLOW}${label} NOTICE:${RESET} '$sum_file' contains $line_count checksum line(s)."
    echo "Checking it may take a long time."
    echo -n "Check this file and continue? [Y/n/q]: "

    flush_stdin
    read -t 300 -n 1 answer || true
    echo

    case "$answer" in
        q|Q)
            stopped_by_user=yes
            return 2
            ;;
        n|N)
            return 1
            ;;
        *)
            return 0
            ;;
    esac
}

stop_on_checksum_failure() {
    local sum_file="$1"
    local phase="$2"
    local label
    label="$(checksum_label "$sum_file")"

    echo -e "${RED}${label} ERROR:${RESET} ${label} verification ${phase} failed for '$sum_file'."
    echo -e "${RED}STOPPING:${RESET} Script execution aborted because ${label} is incorrect."
    exit 1
}

transform_basename() {
    local new="$1"

    # mojibake fixes
    new="${new//Ä™/e}"
    new="${new//Ĺ„/n}"
    new="${new//Ä‡/c}"
    new="${new//ĹĽ/z}"
    new="${new//Ăl/o}"
    new="${new//Ĺ›/s}"
    new="${new//Ä…/a}"
    new="${new//Ĺş/z}"
    new="${new//Ĺ�/L}"
    new="${new//Ă/s}"
    new="${new//Ăł/o}"
    new="${new//Ĺ‚/l}"

    new="${new//ą/a}"
    new="${new//ć/c}"
    new="${new//ę/e}"
    new="${new//ł/l}"
    new="${new//ń/n}"
    new="${new//ó/o}"
    new="${new//ś/s}"
    new="${new//ż/z}"
    new="${new//ź/z}"

    new="${new//Ą/A}"
    new="${new//Ć/C}"
    new="${new//Ę/E}"
    new="${new//Ł/L}"
    new="${new//Ń/N}"
    new="${new//Ó/O}"
    new="${new//Ś/S}"
    new="${new//Ż/Z}"
    new="${new//Ź/Z}"

    new="${new//(/_}"
    new="${new//)/_}"
    new="${new//\{/_}"
    new="${new//\}/_}"
    new="${new//\[/_}"
    new="${new//\]/_}"
    new="${new//,/_}"

    new="${new//!/.}"
    new="${new// /_}"
    new="${new//\'/_}"
    new="${new//&/_and_}"
    new="${new//•/-}"

    # remove unwanted fragments from names
    new="${new//_OSiOLEK.com/}"
    new="${new//LEK.PL/}"

    new=$(printf '%s' "$new" | sed -E '
        s/__+/_/g;
        s/_\././g;
        s/_$//;
        s/\.$//;
    ')

    if [[ "$new" =~ ^signal-([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-[0-9]+(\.[^.]+)$ ]]; then
        printf '%s%s%s_%s%s%s-signal%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" \
            "${BASH_REMATCH[7]}"
        return
    fi

    if [[ "$new" =~ ^Screenshot_([0-9]{8}_[0-9]{6}_.+)(\.[^.]+)$ ]]; then
        printf '%s-screenshot%s' \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[2]}"
        return
    fi

    if [[ "$new" =~ ^Screen_Recording_([0-9]{8})[-_]([0-9]{6})[-_](.+)(\.[^.]+)$ ]]; then
        printf '%s_%s_-_Screen_Recording_-_%s%s' \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[2]}" \
            "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}"
        return
    fi

    if [[ "$new" =~ ^Call_recording_(.+)_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_Call_recording_-_%s%s' \
            "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[6]}"
        return
    fi

    if [[ "$new" =~ ^Call_recording_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})[-_](.+)(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_Call_recording_-_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[6]}"
        return
    fi

    if [[ "$new" =~ ^Sprache_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})[-_](.+)(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_VoiceRecorder_-_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[6]}"
        return
    fi

    if [[ "$new" =~ ^Sprache_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_VoiceRecorder%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}"
        return
    fi

    if [[ "$new" =~ ^Voice_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})[-_](.+)(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_VoiceRecorder_-_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[6]}"
        return
    fi

    if [[ "$new" =~ ^Voice_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_VoiceRecorder%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}"
        return
    fi

    printf '%s' "$new"
}

transform_name() {
    local f="$1"
    local dir base newbase

    dir="$(dirname -- "$f")"
    base="$(basename -- "$f")"
    newbase="$(transform_basename "$base")"

    if [[ "$dir" == "." ]]; then
        if [[ "$f" == ./* ]]; then
            printf './%s' "$newbase"
        else
            printf '%s' "$newbase"
        fi
    else
        printf '%s/%s' "$dir" "$newbase"
    fi
}

text_file_has_crlf() {
    local f="$1"
    LC_ALL=C grep -q $'\r' -- "$f"
}

normalize_text_file_to_unix() {
    local f="$1"

    if command -v dos2unix >/dev/null 2>&1; then
        preserve_timestamps_inplace "$f" dos2unix -q -- "$f"
    else
        preserve_timestamps_inplace "$f" sed -i 's/\r$//' -- "$f"
    fi
}

checksum_file_has_crlf() {
    local sum_file="$1"
    text_file_has_crlf "$sum_file"
}

normalize_checksum_file() {
    local sum_file="$1"
    normalize_text_file_to_unix "$sum_file"
}

ensure_checksum_file_unix_format() {
    local sum_file="$1"
    local label
    label="$(checksum_label "$sum_file")"

    if checksum_file_has_crlf "$sum_file"; then
        if [[ "$mode" == "dry-run" ]]; then
            echo -e "${CYAN}[DRY-RUN] Would convert ${label} file from CRLF to LF:${RESET} $sum_file"
        else
            echo -e "${CYAN}${label} NORMALIZE:${RESET} converting CRLF to LF: $sum_file"
            normalize_checksum_file "$sum_file"
            echo -e "${CYAN}${label} NORMALIZE DONE:${RESET} converted from Windows format to Unix format: $sum_file"
        fi
    fi
}

extract_checksum_entries() {
    local sum_file="$1"
    sed -E 's/\r$//' -- "$sum_file" | while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if [[ "$line" =~ ^([0-9a-fA-F]+)[[:space:]]+\*?(.*)$ ]]; then
            printf '%s\t%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        fi
    done
}

checksum_check() {
    local sum_file="$1"
    local kind sum_dir sum_base
    kind="$(checksum_kind "$sum_file")"
    sum_dir="$(dirname -- "$sum_file")"
    sum_base="$(basename -- "$sum_file")"

    if [[ "$mode" == "real" ]]; then
        ensure_checksum_file_unix_format "$sum_file"
    fi

    vlog "Running $(checksum_cmd "$sum_file") check in directory '$sum_dir' for file '$sum_base'"

    if [[ "$mode" == "dry-run" ]]; then
        (
            cd "$sum_dir"
            case "$kind" in
                sha512) sha512sum -c --quiet -- <(sed 's/\r$//' -- "$sum_base") ;;
                md5)    md5sum    -c --quiet -- <(sed 's/\r$//' -- "$sum_base") ;;
            esac
        )
    else
        (
            cd "$sum_dir"
            case "$kind" in
                sha512) sha512sum -c --quiet -- "$sum_base" ;;
                md5)    md5sum    -c --quiet -- "$sum_base" ;;
            esac
        )
    fi
}

checksum_of_file() {
    local kind="$1"
    local file="$2"

    case "$kind" in
        sha512) sha512sum -- "$file" | awk '{print tolower($1)}' ;;
        md5)    md5sum    -- "$file" | awk '{print tolower($1)}' ;;
    esac
}

sed_escape_regex() {
    printf '%s' "$1" | sed -e 's/[.[\*^$()+?{}|\\/]/\\&/g'
}

sed_escape_repl() {
    printf '%s' "$1" | sed -e 's/[&\\/]/\\&/g'
}

strip_leading_dot_slash() {
    local p="$1"
    printf '%s' "${p#./}"
}

relative_path() {
    local from_dir="$1"
    local target="$2"
    python3 - "$from_dir" "$target" <<'PY'
import os, sys
from_dir = sys.argv[1]
target = sys.argv[2]
print(os.path.relpath(target, from_dir))
PY
}

format_ref_for_checksum_file() {
    local sum_file="$1"
    local original_ref="$2"
    local actual_path="$3"
    local sum_dir rel

    sum_dir="$(dirname -- "$sum_file")"

    if [[ "$original_ref" == /* ]]; then
        python3 - "$actual_path" <<'PY'
import os, sys
print(os.path.abspath(sys.argv[1]))
PY
        return
    fi

    rel="$(relative_path "$sum_dir" "$actual_path")"

    if [[ "$original_ref" == ./* ]]; then
        printf './%s' "$rel"
    else
        printf '%s' "$rel"
    fi
}

update_checksum_content_refs() {
    local sum_file="$1"
    local old_name="$2"
    local new_name="$3"

    local old_re1 new_re1 old_re2 new_re2
    old_re1="$(sed_escape_regex "$old_name")"
    new_re1="$(sed_escape_repl "$new_name")"

    old_re2="$(sed_escape_regex "$(strip_leading_dot_slash "$old_name")")"
    new_re2="$(sed_escape_repl "$(strip_leading_dot_slash "$new_name")")"

    vlog "Updating checksum content in '$sum_file': '$old_name' -> '$new_name'"

    preserve_timestamps_inplace "$sum_file" \
        sed -i -E \
            -e "s|([[:space:]]\\*?)${old_re1}\$|\\1${new_re1}|g" \
            -e "s|([[:space:]]\\*?)${old_re2}\$|\\1${new_re2}|g" \
            -- "$sum_file"
}

resolve_checksum_ref_path() {
    local sum_file="$1"
    local ref="$2"
    local sum_dir candidate

    sum_dir="$(dirname -- "$sum_file")"

    if [[ "$ref" == /* ]]; then
        printf '%s' "$ref"
        return
    fi

    if [[ "$ref" == ./* ]]; then
        if [[ "$sum_dir" == "." ]]; then
            printf '%s' "$ref"
        else
            printf '%s/%s' "$sum_dir" "${ref#./}"
        fi
        return
    fi

    if [[ "$sum_dir" == "." ]]; then
        if [[ -e "./$ref" ]]; then
            printf './%s' "$ref"
        else
            printf '%s' "$ref"
        fi
    else
        candidate="$sum_dir/$ref"
        printf '%s' "$candidate"
    fi
}

variant_family_info() {
    local p="$1"
    local base stem variant ext

    base="$(basename -- "$p")"
    if [[ "$base" =~ ^(.+)_((ORG)|(OUTPUT)|(EXCLUDE))(\.[^.]+)$ ]]; then
        stem="${BASH_REMATCH[1]}"
        variant="${BASH_REMATCH[2]}"
        ext="${BASH_REMATCH[6]}"
        printf '%s|%s|%s' "$stem" "$variant" "$ext"
        return 0
    fi
    return 1
}

print_grouped_checksum_missing_warning() {
    local sum_file="$1"
    shift
    local -a refs=( "$@" )

    local ref info stem variant ext key rest
    local -A family_variants=()
    local found_group=no

    for ref in "${refs[@]}"; do
        if info="$(variant_family_info "$ref")"; then
            stem="${info%%|*}"
            rest="${info#*|}"
            variant="${rest%%|*}"
            ext="${rest##*|}"
            key="$stem"
            family_variants["$key"]+="${variant} "
            found_group=yes
        fi
    done

    [[ "$found_group" == "yes" ]] || return 0

    echo -e "${YELLOW}CHECKSUM GROUP WARNING:${RESET} '$sum_file' contains grouped ORG/OUTPUT/EXCLUDE-style references."

    local family present_variants expected_variants expected_variant
    for family in "${!family_variants[@]}"; do
        present_variants="${family_variants[$family]}"
        expected_variants="ORG OUTPUT"

        for expected_variant in $expected_variants; do
            [[ "$present_variants" == *"${expected_variant} "* ]] && continue
            echo -e "  ${YELLOW}Missing reference in group:${RESET} ${family}_${expected_variant}.*"
        done
    done
}

find_best_path_for_missing_ref() {
    local missing_ref="$1"
    local expected_hash="$2"
    local sum_file="$3"

    local kind wanted_base wanted_norm missing_dir
    local fast_base fast_path fast_hash

    kind="$(checksum_kind "$sum_file")"
    wanted_base="$(basename -- "$missing_ref")"
    wanted_norm="$(transform_basename "$wanted_base")"
    missing_dir="$(dirname -- "$missing_ref")"

    vlog "Trying to recover missing ref '$missing_ref' (expected hash: ${expected_hash:-none})"

    fast_base="$wanted_norm"
    fast_path="${missing_dir}/${fast_base}"

    if [[ -f "$fast_path" ]]; then
        vlog "Fast recovery candidate in same directory: '$fast_path'"
        if [[ -n "$expected_hash" ]]; then
            fast_hash="$(checksum_of_file "$kind" "$fast_path")"
            vlog "Fast recovery candidate has $kind=$fast_hash"
            if [[ "${fast_hash,,}" == "${expected_hash,,}" ]]; then
                vlog "Fast recovery candidate checksum matches"
                printf '%s' "$fast_path"
                return 0
            else
                vlog "Fast recovery candidate checksum does not match"
            fi
        else
            vlog "Fast recovery candidate accepted (no expected hash available)"
            printf '%s' "$fast_path"
            return 0
        fi
    fi

    vlog "Fast same-directory recovery failed for '$missing_ref'"
    return 1
}

files_examined=0
files_affected=0
files_skipped=0
stopped_by_user=no
rename_all=no

declare -a renamed_list=()
declare -A recorded
declare -A processed

record_rename() {
    local old="$1" new="$2"
    local key="$old|$new"
    [[ -n "${recorded[$key]+x}" ]] && return 0
    recorded["$key"]=1
    renamed_list+=("$key")
}

list_local_checksum_files() {
    local dir="$1"
    local -n _out_ref="$2"

    _out_ref=()
    while IFS= read -r -d '' sum; do
        _out_ref+=( "$sum" )
    done < <(find "$dir" -mindepth 1 -maxdepth 1 -type f \( -name '*.sha512' -o -name '*.md5' \) -print0 | sort -z)
}

collect_checksum_updates_for_path() {
    local sum_file="$1"
    local old_path="$2"
    local new_path="$3"
    local is_dir_rename="$4"

    local old_abs new_abs sum_dir ref_hash ref_raw ref_resolved ref_abs ref_new ref_new_written
    local matched=1

    old_abs="$(python3 - "$old_path" <<'PY'
import os, sys
print(os.path.abspath(sys.argv[1]))
PY
)"
    new_abs="$(python3 - "$new_path" <<'PY'
import os, sys
print(os.path.abspath(sys.argv[1]))
PY
)"
    sum_dir="$(dirname -- "$sum_file")"

    CHECKSUM_UPDATE_OLD_REFS=()
    CHECKSUM_UPDATE_NEW_REFS=()

    while IFS=$'\t' read -r ref_hash ref_raw; do
        [[ -n "$ref_raw" ]] || continue
        ref_resolved="$(resolve_checksum_ref_path "$sum_file" "$ref_raw")"
        ref_abs="$(python3 - "$ref_resolved" <<'PY'
import os, sys
print(os.path.abspath(sys.argv[1]))
PY
)"

        if [[ "$is_dir_rename" == "yes" ]]; then
            if python3 - "$old_abs" "$ref_abs" >/dev/null 2>&1 <<'PY'
import os, sys
old_abs = sys.argv[1]
ref_abs = sys.argv[2]
try:
    common = os.path.commonpath([old_abs, ref_abs])
    ok = (common == old_abs)
except ValueError:
    ok = False
raise SystemExit(0 if ok else 1)
PY
            then
                ref_new="$(python3 - "$old_abs" "$new_abs" "$ref_abs" <<'PY'
import os, sys
old_abs, new_abs, ref_abs = sys.argv[1:4]
rel = os.path.relpath(ref_abs, old_abs)
print(os.path.normpath(os.path.join(new_abs, rel)))
PY
)"
                ref_new_written="$(format_ref_for_checksum_file "$sum_file" "$ref_raw" "$ref_new")"
                CHECKSUM_UPDATE_OLD_REFS+=( "$ref_raw" )
                CHECKSUM_UPDATE_NEW_REFS+=( "$ref_new_written" )
                matched=0
            fi
        else
            if [[ "$ref_abs" == "$old_abs" ]]; then
                ref_new_written="$(format_ref_for_checksum_file "$sum_file" "$ref_raw" "$new_path")"
                CHECKSUM_UPDATE_OLD_REFS+=( "$ref_raw" )
                CHECKSUM_UPDATE_NEW_REFS+=( "$ref_new_written" )
                matched=0
            fi
        fi
    done < <(extract_checksum_entries "$sum_file")

    return $matched
}

verify_single_checksum_target() {
    local sum_file="$1"
    local target_ref="$2"
    local kind sum_dir sum_base target_norm

    kind="$(checksum_kind "$sum_file")"
    sum_dir="$(dirname -- "$sum_file")"
    sum_base="$(basename -- "$sum_file")"
    target_norm="$(strip_leading_dot_slash "$target_ref")"

    vlog "Running single-target $(checksum_cmd "$sum_file") check in '$sum_dir' for ref '$target_ref' from '$sum_base'"

    (
        cd "$sum_dir"
        case "$kind" in
            sha512)
                sed -E 's/\r$//' -- "$sum_base" | grep -E "[[:space:]]\*?$(sed_escape_regex "$target_norm")$" | sha512sum -c --quiet --status
                ;;
            md5)
                sed -E 's/\r$//' -- "$sum_base" | grep -E "[[:space:]]\*?$(sed_escape_regex "$target_norm")$" | md5sum -c --quiet --status
                ;;
        esac
    )
}

perform_plain_entry_rename() {
    local old="$1"
    local new="$2"
    local current_dir is_dir_rename
    local -a local_hash_files=()
    local -a changed_hash_files=()
    local -a changed_hash_refs=()
    local sum_file ref_old ref_new idx label

    current_dir="$(dirname -- "$old")"
    [[ -d "$old" ]] && is_dir_rename=yes || is_dir_rename=no

    if [[ -e "$new" ]]; then
        echo -e "${YELLOW}SKIP:${RESET} Target already exists: $new"
        ((++files_skipped))
        return 0
    fi

    list_local_checksum_files "$current_dir" local_hash_files

    for sum_file in "${local_hash_files[@]}"; do
        if collect_checksum_updates_for_path "$sum_file" "$old" "$new" "$is_dir_rename"; then
            continue
        fi

        changed_hash_files+=( "$sum_file" )
        if [[ "$is_dir_rename" == "yes" ]]; then
            changed_hash_refs+=( "<directory-update>" )
        else
            changed_hash_refs+=( "${CHECKSUM_UPDATE_NEW_REFS[0]}" )
        fi
    done

    if [[ "$mode" == "dry-run" ]]; then
        echo -e "${CYAN}[DRY-RUN] Would rename:${RESET} $old ${ARROW} $new"
        for idx in "${!changed_hash_files[@]}"; do
            sum_file="${changed_hash_files[$idx]}"
            echo -e "${CYAN}[DRY-RUN] Would update local checksum file:${RESET} $sum_file"
        done
        ((++files_affected))
        record_rename "$old" "$new"
        return 0
    fi

    mv -i -- "$old" "$new"
    ((++files_affected))
    record_rename "$old" "$new"

    for sum_file in "${local_hash_files[@]}"; do
        if collect_checksum_updates_for_path "$sum_file" "$old" "$new" "$is_dir_rename"; then
            continue
        fi

        ensure_checksum_file_unix_format "$sum_file"
        label="$(checksum_label "$sum_file")"

        for idx in "${!CHECKSUM_UPDATE_OLD_REFS[@]}"; do
            ref_old="${CHECKSUM_UPDATE_OLD_REFS[$idx]}"
            ref_new="${CHECKSUM_UPDATE_NEW_REFS[$idx]}"
            update_checksum_content_refs "$sum_file" "$ref_old" "$ref_new"
        done

        if [[ "$is_dir_rename" == "yes" ]]; then
            echo -e "${CYAN}${label} check (after directory rename) in progress...${RESET} $sum_file"
            if checksum_check "$sum_file"; then
                echo -e "${GREEN}${label} OK:${RESET} updated local references in '$sum_file' after directory rename."
            else
                stop_on_checksum_failure "$sum_file" "after directory rename"
            fi
        else
            ref_new="${CHECKSUM_UPDATE_NEW_REFS[0]}"
            echo -e "${CYAN}${label} check (after file rename) in progress for changed entry...${RESET} $sum_file -> $ref_new"
            if verify_single_checksum_target "$sum_file" "$ref_new"; then
                echo -e "${GREEN}${label} OK:${RESET} updated local reference in '$sum_file' for '$ref_new'."
            else
                stop_on_checksum_failure "$sum_file" "after file rename"
            fi
        fi
    done

    return 0
}

if [[ "$process_scope" == "current" ]]; then
    mapfile -d '' -t ordered_paths < <(
        find . -mindepth 1 -maxdepth 1 -depth -print0 |
        python3 -c '
import sys
items = sys.stdin.buffer.read().split(b"\0")
items = [x for x in items if x]
def depth(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return s.count("/")
items.sort(key=lambda p: (-depth(p), p))
sys.stdout.buffer.write(b"\0".join(items) + (b"\0" if items else b""))
'
    )
else
    mapfile -d '' -t ordered_paths < <(
        find . -depth -mindepth 1 -print0 |
        python3 -c '
import sys
items = sys.stdin.buffer.read().split(b"\0")
items = [x for x in items if x]
def depth(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return s.count("/")
items.sort(key=lambda p: (-depth(p), p))
sys.stdout.buffer.write(b"\0".join(items) + (b"\0" if items else b""))
'
    )
fi

vlog "Discovered entries to process: ${#ordered_paths[@]}"

main_index=0
for f in "${ordered_paths[@]}"; do
    ((++main_index))
    if (( VERBOSE == 1 && main_index % VERBOSE_MAIN_EVERY == 0 )); then
        vlog "Main loop progress: $main_index / ${#ordered_paths[@]} (current: '$f')"
    fi

    [[ -n "${processed[$f]+x}" ]] && continue
    ((++files_examined))

    if is_excluded_by_filter_file "$f"; then
        echo -e "${YELLOW}SKIP:${RESET} '$f' was ignored because part of its path matches a filter from $EXCLUDE_FILTERS_FILE."
        vlog "Excluded by filter file: '$f'"
        ((++files_skipped))
        processed["$f"]=1
        continue
    fi

    if is_excluded_path "$f"; then
        vlog "Skipping excluded path '$f'"
        ((++files_skipped))
        continue
    fi

    if [[ -f "$f" ]] && is_checksum_file "$f"; then
        sum_file="$f"
        label="$(checksum_label "$sum_file")"

        vlog "Processing checksum file '$sum_file'"

        if [[ "$mode" == "real" ]]; then
            ensure_checksum_file_unix_format "$sum_file"
        fi

        refs_raw=()
        refs=()
        expected_hashes=()

        while IFS=$'\t' read -r hash ref; do
            [[ -n "$ref" ]] || continue
            expected_hashes+=( "$hash" )
            refs_raw+=( "$ref" )
            refs+=( "$(resolve_checksum_ref_path "$sum_file" "$ref")" )
            vlog "Resolved ref '$ref' -> '${refs[-1]}'"
        done < <(extract_checksum_entries "$sum_file")

        if (( ${#refs[@]} == 0 )) || [[ -z "${refs[0]}" ]]; then
            vlog "Checksum file '$sum_file' has no valid refs"
            ((++files_skipped))
            processed["$sum_file"]=1
            continue
        fi

        declare -a recovered_old_refs=()
        declare -a recovered_new_real_refs=()
        declare -a recovered_new_written_refs=()
        checksum_content_modified=no

        for i in "${!refs[@]}"; do
            ref="${refs[$i]}"
            if [[ -e "$ref" ]]; then
                vlog "Ref exists already: '$ref'"
                continue
            fi

            vlog "Ref missing, trying recovery: '$ref'"
            found_ref="$(find_best_path_for_missing_ref "$ref" "${expected_hashes[$i]}" "$sum_file" || true)"
            if [[ -n "$found_ref" ]]; then
                replacement_ref="$(format_ref_for_checksum_file "$sum_file" "${refs_raw[$i]}" "$found_ref")"
                recovered_old_refs+=( "${refs_raw[$i]}" )
                recovered_new_real_refs+=( "$found_ref" )
                recovered_new_written_refs+=( "$replacement_ref" )
                refs_raw[$i]="$replacement_ref"
                refs[$i]="$found_ref"
                checksum_content_modified=yes
                vlog "Recovery success: '$ref' -> '$found_ref' (write as '$replacement_ref')"
                echo -e "${CYAN}${label} RECOVERY CANDIDATE VERIFIED:${RESET} '$found_ref' matches the stored ${label,,}."
            else
                vlog "Recovery failed for '$ref'"
            fi
        done

        if (( ${#recovered_old_refs[@]} > 0 )); then
            echo
            echo -e "${CYAN}${label} RECOVERY:${RESET} '$sum_file' references missing file(s), but replacement file(s) were found."
            for i in "${!recovered_old_refs[@]}"; do
                echo -e "  ${RED}OLD REF:${RESET} ${recovered_old_refs[$i]}"
                echo -e "  ${GREEN}FOUND:${RESET}   ${recovered_new_real_refs[$i]}"
                echo -e "  ${GREEN}WRITE:${RESET}   ${recovered_new_written_refs[$i]}"
            done

            if [[ "$mode" == "real" ]]; then
                ensure_checksum_file_unix_format "$sum_file"
                for i in "${!recovered_old_refs[@]}"; do
                    update_checksum_content_refs "$sum_file" "${recovered_old_refs[$i]}" "${recovered_new_written_refs[$i]}"
                done
                echo -e "${CYAN}${label} RECOVERY UPDATED:${RESET} '$sum_file' was updated to point to the found file(s)."
                echo -e "${CYAN}${label} RECOVERY NOTE:${RESET} full ${label,,} file verification will follow in normal processing."
            else
                echo -e "${CYAN}[DRY-RUN] Would update ${label,,} content to use the found file(s) above.${RESET}"
            fi
        fi

        missing=no
        declare -a missing_refs=()
        for ref in "${refs[@]}"; do
            if [[ ! -e "$ref" ]]; then
                missing=yes
                missing_refs+=( "$ref" )
            fi
        done

        if [[ "$missing" == "yes" ]]; then
            echo
            echo -e "${YELLOW}${label} SKIP:${RESET} '$sum_file' still references missing file(s)."
            for ref in "${missing_refs[@]}"; do
                echo -e "  ${YELLOW}MISSING:${RESET} $ref"
            done
            print_grouped_checksum_missing_warning "$sum_file" "${refs[@]}"
            ((++files_skipped))
            processed["$sum_file"]=1
            continue
        fi

        new_sum="$(transform_name "$sum_file")"
        declare -a new_refs=()
        refs_need_rename=no
        for ref in "${refs[@]}"; do
            new_ref="$(transform_name "$ref")"
            new_refs+=( "$new_ref" )
            [[ "$new_ref" != "$ref" ]] && refs_need_rename=yes
        done

        sum_file_needs_rename=no
        [[ "$new_sum" != "$sum_file" ]] && sum_file_needs_rename=yes

        action_needed=no
        [[ "$refs_need_rename" == "yes" ]] && action_needed=yes
        [[ "$sum_file_needs_rename" == "yes" ]] && action_needed=yes
        [[ "$checksum_content_modified" == "yes" ]] && action_needed=yes

        if [[ "$action_needed" == "no" ]]; then
            vlog "All referenced files exist and no rename/update is needed for '$sum_file' - skipping without checksum verification"
            ((++files_skipped))
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        if [[ "$mode" == "dry-run" ]]; then
            echo
            if [[ "$checksum_content_modified" == "yes" ]]; then
                echo -e "${CYAN}[DRY-RUN] Would check ${label} because checksum content would be modified:${RESET} $sum_file"
            else
                echo -e "${CYAN}[DRY-RUN] Would check ${label} because rename is needed:${RESET} $sum_file"
            fi
            echo -e "${RED}OLD ${label}:${RESET} $sum_file"
            echo -e "${GREEN}NEW ${label}:${RESET} $new_sum"
            for i in "${!refs[@]}"; do
                echo -e "${RED}OLD FILE:${RESET} ${refs[$i]}"
                echo -e "${GREEN}NEW FILE:${RESET} ${new_refs[$i]}"
            done
            echo -e "${CYAN}[DRY-RUN] Would update ${label,,} content references inside:${RESET} $sum_file"
            echo -e "${CYAN}[DRY-RUN] Would check ${label} after rename:${RESET} $new_sum"
            echo "----------------------------------------"

            ((++files_affected))
            record_rename "$sum_file" "$new_sum"
            for i in "${!refs[@]}"; do
                record_rename "${refs[$i]}" "${new_refs[$i]}"
            done

            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        local_line_count="$(count_checksum_entries "$sum_file")"
        if ! confirm_large_hash_check "$sum_file" "$label" "$local_line_count"; then
            rc=$?
            if [[ $rc -eq 2 ]]; then
                break
            fi
            echo -e "${YELLOW}SKIP:${RESET} User chose not to check large ${label,,} file '$sum_file'."
            ((++files_skipped))
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        ensure_checksum_file_unix_format "$sum_file"

        echo
        echo -e "${RED}OLD ${label}:${RESET} $sum_file"
        echo -e "${GREEN}NEW ${label}:${RESET} $new_sum"
        for i in "${!refs[@]}"; do
            echo -e "${RED}OLD FILE:${RESET} ${refs[$i]}"
            echo -e "${GREEN}NEW FILE:${RESET} ${new_refs[$i]}"
        done

        do_rename=no
        if [[ "$rename_all" == "yes" ]]; then
            do_rename=yes
        else
            echo -n "Rename this ${label,,} + referenced file(s)? [Y/n/a/q]: "
            flush_stdin
            read -t 300 -n 1 input || true
            echo

            case "$input" in
                q|Q)
                    stopped_by_user=yes
                    break
                    ;;
                n|N)
                    ((++files_skipped))
                    do_rename=no
                    ;;
                a|A)
                    echo
                    echo "⚠️  This will rename ALL remaining files/directories."
                    echo -n "Are you sure? [y/N]: "
                    flush_stdin
                    read -n 1 confirm || true
                    echo
                    if [[ "$confirm" =~ [Yy] ]]; then
                        rename_all=yes
                        do_rename=yes
                    else
                        ((++files_skipped))
                        do_rename=no
                    fi
                    ;;
                *)
                    do_rename=yes
                    ;;
            esac
        fi

        if [[ "$do_rename" != "yes" ]]; then
            vlog "User skipped checksum group '$sum_file'"
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        begin_current_operation "$label" "$sum_file" "$new_sum"

        echo -e "${CYAN}${label} check (before rename) in progress...${RESET} $sum_file"
        if ! checksum_check "$sum_file"; then
            echo -e "${YELLOW}${label} FAIL:${RESET} checksum mismatch for '$sum_file' (won't rename pair)"
            stop_on_checksum_failure "$sum_file" "before rename"
        fi
        echo -e "${CYAN}${label} VERIFIED (before rename):${RESET} $sum_file"

        collision=no
        [[ "$new_sum" != "$sum_file" && -e "$new_sum" ]] && collision=yes
        for i in "${!refs[@]}"; do
            [[ "${new_refs[$i]}" != "${refs[$i]}" && -e "${new_refs[$i]}" ]] && collision=yes
        done

        if [[ "$collision" == "yes" ]]; then
            echo -e "${YELLOW}SKIP:${RESET} Target file already exists."
            vlog "Collision detected in checksum group '$sum_file'"
            finish_current_operation
            ((++files_skipped))
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        for i in "${!refs[@]}"; do
            if [[ "${new_refs[$i]}" != "${refs[$i]}" ]]; then
                vlog "Renaming referenced file '${refs[$i]}' -> '${new_refs[$i]}'"
                mv -i -- "${refs[$i]}" "${new_refs[$i]}"
                register_current_file_rename "${refs[$i]}" "${new_refs[$i]}"
                ((++files_affected))
                record_rename "${refs[$i]}" "${new_refs[$i]}"
            else
                ((++files_skipped))
            fi
        done

        for i in "${!refs[@]}"; do
            old_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "${refs_raw[$i]}" "${refs[$i]}")"
            new_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "${refs_raw[$i]}" "${new_refs[$i]}")"
            if [[ "$old_ref_for_write" != "$new_ref_for_write" ]]; then
                update_checksum_content_refs "$sum_file" "$old_ref_for_write" "$new_ref_for_write"
            fi
        done

        final_sum="$sum_file"
        if [[ "$new_sum" != "$sum_file" ]]; then
            vlog "Renaming checksum file '$sum_file' -> '$new_sum'"
            mv -i -- "$sum_file" "$new_sum"
            mark_current_sum_renamed
            ((++files_affected))
            record_rename "$sum_file" "$new_sum"
            final_sum="$new_sum"
        else
            ((++files_skipped))
        fi

        echo -e "${CYAN}${label} check (after rename) in progress...${RESET} $final_sum"
        if checksum_check "$final_sum"; then
            echo -e "${CYAN}${label} VERIFIED (after rename):${RESET} $final_sum"
            echo -e "${GREEN}${label} OK:${RESET} referenced file name(s) were updated inside '$final_sum' and ${label,,} checksum(s) are correct."
        else
            echo -e "${YELLOW}${label} FAIL (after rename):${RESET} '$final_sum' does not validate."
            echo -e "${YELLOW}NOTE:${RESET} Files were renamed, but checksum verification after update failed."
            stop_on_checksum_failure "$final_sum" "after rename"
        fi

        finish_current_operation
        vlog "Finished checksum group '$sum_file'"

        processed["$sum_file"]=1
        processed["$final_sum"]=1
        for ref in "${refs[@]}"; do processed["$ref"]=1; done
        for ref in "${new_refs[@]}"; do processed["$ref"]=1; done

        continue
    fi

    if [[ -f "$f" ]]; then
        base="${f%.*}"
        if [[ -e "$base.sha512" || -e "$base.md5" ]]; then
            vlog "Skipping '$f' because sibling checksum file exists"
            ((++files_skipped))
            continue
        fi
    fi

    new="$(transform_name "$f")"
    [[ "$f" == "$new" ]] && {
        vlog "No rename needed for '$f'"
        ((++files_skipped))
        continue
    }

    if [[ "$rename_all" == "yes" ]]; then
        vlog "Renaming '$f' -> '$new' due to rename_all"
        perform_plain_entry_rename "$f" "$new" || break
        continue
    fi

    echo
    echo -e "${RED}OLD:${RESET} $f"
    echo -e "${GREEN}NEW:${RESET} $new"
    echo -n "Rename this entry? [Y/n/a/q]: "
    flush_stdin
    read -t 300 -n 1 input || true
    echo

    case "$input" in
        q|Q)
            stopped_by_user=yes
            break
            ;;
        n|N)
            ((++files_skipped))
            ;;
        a|A)
            echo
            echo "⚠️  This will rename ALL remaining files/directories."
            echo -n "Are you sure? [y/N]: "
            flush_stdin
            read -n 1 confirm || true
            echo

            if [[ "$confirm" =~ [Yy] ]]; then
                rename_all=yes
                vlog "rename_all enabled by user"
                perform_plain_entry_rename "$f" "$new" || break
            else
                ((++files_skipped))
            fi
            ;;
        *)
            vlog "Renaming '$f' -> '$new'"
            perform_plain_entry_rename "$f" "$new" || break
            ;;
    esac
done

echo
echo "========= SUMMARY ========="
echo "Mode:                  $mode"
echo "Colors enabled:        $use_colors"
echo "Verbose:               $VERBOSE"
echo "Scope:                 $process_scope"
echo "Entries examined:      $files_examined"
echo "Entries affected:      $files_affected"
echo "Entries skipped:       $files_skipped"
echo "Stopped by user:       $stopped_by_user"

if (( files_affected > 0 )); then
    echo
    echo "Affected entries:"
    for r in "${renamed_list[@]}"; do
        old=${r%%|*}
        new=${r#*|}
        printf "  %s %b%s%b %s\n" \
            "$old" \
            "$RED" "$ARROW" "$RESET" \
            "$new"
    done
fi
echo "==========================="
