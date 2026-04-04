#!/usr/bin/env bash
# 2026.04.03 - v. 8.7 - define MAX_LINE_LENGTH early so wrapped messages cannot fail with unbound variable
# 2026.04.03 - v. 8.6 - add --colors, --mode, and --scope command-line options to skip startup questions
# 2026.04.03 - v. 8.5 - cache checksum files with missing refs in DB and wrap long SKIP lines using MAX_LINE_LENGTH
# 2026.04.03 - v. 8.4 - print info when .htm/.html files are renamed together with companion _files/_pliki directories
# 2026.04.03 - v. 8.3 - wrap long single-target checksum verbose lines and remove _www.osiolek.com from filenames
# 2026.04.03 - v. 8.2 - rename DB file to _rename.sh-optional-db.sqlite3, migrate legacy DB automatically, and keep DB skip ahead of checksum parsing
# 2026.04.03 - v. 8.1 - suppress SQLite WAL startup output ('wal') during DB initialization
# 2026.04.03 - v. 8.0 - when a directory is renamed, update cached DB paths for files under that subtree
# 2026.04.03 - v. 7.9 - add robust checksum-file DB recognition using checksum-file signature
# 2026.04.03 - v. 7.8 - add optional --fast mode for path-only DB skips and update help/banner text
# 2026.04.03 - v. 7.7 - optimize --use-db with in-memory cache and batched SQLite writes
# 2026.04.03 - v. 7.2 - optional SQLite checked-file cache with --use-db and --force-recheck
# 2026.04.03 - v. 7.1 - treat _pliki companion directories the same as _files for .htm/.html pairs
# 2026.04.03 - v. 7.0 - add E option to append basename-based exclude entries into start-directory exclude file and print confirmation
# 2026.04.03 - v. 6.9 - add E option in per-entry rename prompt to append basename-based exclude entries
# 2026.04.03 - v. 6.8 - split long exclude-filter SKIP messages into two lines
# 2026.04.03 - v. 6.7 - show verbose main-loop progress in a dynamically sized two-line box
# 2026.04.03 - v. 6.6 - include exact hash file path directly in checksum-group prompt text
# 2026.04.03 - v. 6.5 - hide unchanged OLD/NEW pairs in checksum-group displays and prompts
# 2026.04.03 - v. 6.4 - do not rename checksum files whose basename starts with __
# 2026.04.03 - v. 6.3 - ask per .lnk file whether to remove it instead of using one global question
# 2026.04.03 - v. 6.2 - add extra mojibake fixes, remove rip.by.Crisp, prompt for .lnk removal, and pair .htm/.html with _files companion dirs
# 2026.04.03 - v. 6.1 - verify only changed references inside checksum groups instead of requiring whole hash file to be clean
# 2026.04.03 - v. 6.0 - make prompt input draining bounded and read a single key safely from repeated keypress bursts
# 2026.04.02 - v. 5.9 - skip plain entry renames when a local checksum file refers to them; let checksum branch handle the group
# 2026.04.02 - v. 5.8 - process checksum files before sibling plain entries to avoid stale local hash refs
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
SCRIPT_VERSION="2026.04.03 - v. 8.7"
LARGE_HASHFILE_LINE_THRESHOLD=20
START_DIR="$(pwd -P)"
EXCLUDE_FILTERS_FILE="$START_DIR/_exclude-rename.sh.txt"
USE_DB=0
FORCE_RECHECK=0
FAST_DB=0
DB_FILE="$START_DIR/_rename.sh-optional-db.sqlite3"
LEGACY_DB_FILE="$START_DIR/rename.sh-optional-db.sqlite3"

set -Eeuo pipefail
shopt -s nullglob

VERBOSE=0
VERBOSE_MAIN_EVERY=200
CLI_COLORS=""
CLI_MODE=""
CLI_SCOPE=""

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
Usage: rename.sh [-v|--verbose] [--use-db] [--fast] [--force-recheck] [--colors yes|no] [--mode dry-run|real] [--scope current|subdirs] [-h|--help]

Options:
  -v, --verbose          Show extra diagnostic output
  --use-db               Use SQLite cache in the start directory (_rename.sh-optional-db.sqlite3)
  --fast                 With --use-db, trust cached paths without checking current size/mtime
  --force-recheck        Ignore SQLite cache and recheck everything
  --colors yes|no        Skip the startup colors question
  --mode dry-run|real    Skip the startup mode question
  --scope current|subdirs
                         Skip the startup scope question
  -h, --help             Show this help
EOF
}

flush_stdin() {
    local discard
    local drained=0
    local max_drain=256

    while (( drained < max_drain )) && IFS= read -r -t 0.02 -n 1 discard; do
        ((++drained))
    done
}

read_single_key() {
    local __var_name="$1"
    local __timeout="$2"
    local __char=""

    IFS= read -r -t "$__timeout" -n 1 __char || true
    printf -v "$__var_name" '%s' "$__char"

    # Discard any extra buffered keypresses from the same burst so they do not
    # affect the next prompt or keep the pre-read drain loop busy.
    flush_stdin
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

exception_entry_for_path() {
    local p="$1"
    local base

    base="$(basename -- "$p")"
    if [[ -d "$p" ]]; then
        printf '/%s/' "$base"
    else
        printf '/%s' "$base"
    fi
}

append_path_to_exclude_filters_file() {
    local p="$1"
    local entry tmp_line found=0

    entry="$(exception_entry_for_path "$p")"

    if [[ ! -e "$EXCLUDE_FILTERS_FILE" ]]; then
        : > "$EXCLUDE_FILTERS_FILE"
    fi

    normalize_exclude_filters_file_if_needed

    while IFS= read -r tmp_line || [[ -n "$tmp_line" ]]; do
        tmp_line="${tmp_line%$'
'}"
        [[ -n "$tmp_line" ]] || continue
        [[ "$tmp_line" =~ ^# ]] && continue
        if [[ "$tmp_line" == "$entry" ]]; then
            found=1
            break
        fi
    done < "$EXCLUDE_FILTERS_FILE"

    if (( found == 0 )); then
        printf '%s
' "$entry" >> "$EXCLUDE_FILTERS_FILE"
        echo -e "${CYAN}EXCEPTION ADDED:${RESET} $entry ${CYAN}->${RESET} $EXCLUDE_FILTERS_FILE"
    else
        echo -e "${YELLOW}EXCEPTION EXISTS:${RESET} $entry ${CYAN}->${RESET} $EXCLUDE_FILTERS_FILE"
    fi

    load_exclude_filters
}

sql_escape() {
    printf "%s" "$1" | sed "s/'/''/g"
}

db_require_sqlite() {
    if ! command -v sqlite3 >/dev/null 2>&1; then
        echo "ERROR: --use-db was requested but sqlite3 is not installed." >&2
        exit 1
    fi
}

db_abs_path() {
    local p="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath -e -- "$p"
    elif command -v readlink >/dev/null 2>&1; then
        readlink -f -- "$p"
    else
        local dir base
        dir="$(dirname -- "$p")"
        base="$(basename -- "$p")"
        ( cd "$dir" && printf '%s/%s\n' "$(pwd -P)" "$base" )
    fi
}

db_get_size_mtime() {
    stat -Lc '%s|%Y' -- "$1"
}

db_compute_signature() {
    local path="$1"

    [[ -f "$path" ]] || return 1

    if command -v sha1sum >/dev/null 2>&1; then
        sha1sum -- "$path" | awk '{print $1}'
    elif command -v md5sum >/dev/null 2>&1; then
        md5sum -- "$path" | awk '{print $1}'
    else
        cksum -- "$path" | awk '{print $1 "-" $2}'
    fi
}

declare -A DB_CACHE_META=()
declare -A DB_CACHE_STATUS=()
declare -A DB_CACHE_SIG=()
declare -A DB_CACHE_SIG_STATUS=()
DB_PENDING_SQL_FILE=""
DB_PENDING_COUNT=0
DB_FLUSH_EVERY=500

db_flush_pending() {
    (( USE_DB == 1 )) || return 0
    [[ -n "$DB_PENDING_SQL_FILE" && -s "$DB_PENDING_SQL_FILE" ]] || return 0
    {
        printf 'BEGIN IMMEDIATE;\n'
        cat -- "$DB_PENDING_SQL_FILE"
        printf 'COMMIT;\n'
    } | sqlite3 "$DB_FILE" >/dev/null 2>&1 || true
    : > "$DB_PENDING_SQL_FILE"
    DB_PENDING_COUNT=0
}

cleanup_on_exit() {
    local rc=$?
    if (( USE_DB == 1 )); then
        db_flush_pending || true
        if [[ -n "$DB_PENDING_SQL_FILE" && -e "$DB_PENDING_SQL_FILE" ]]; then
            rm -f -- "$DB_PENDING_SQL_FILE"
        fi
    fi
    exit $rc
}
trap cleanup_on_exit EXIT

db_migrate_legacy_file() {
    if [[ -f "$LEGACY_DB_FILE" && ! -f "$DB_FILE" ]]; then
        mv -f -- "$LEGACY_DB_FILE" "$DB_FILE"
        [[ -f "${LEGACY_DB_FILE}-wal" ]] && mv -f -- "${LEGACY_DB_FILE}-wal" "${DB_FILE}-wal"
        [[ -f "${LEGACY_DB_FILE}-shm" ]] && mv -f -- "${LEGACY_DB_FILE}-shm" "${DB_FILE}-shm"
        echo "SQLite cache migrated: $LEGACY_DB_FILE -> $DB_FILE"
    fi
}

db_init() {
    db_migrate_legacy_file()
    (( USE_DB == 1 )) || return 0
    db_require_sqlite
    sqlite3 "$DB_FILE" >/dev/null 2>&1 <<'SQL'
PRAGMA journal_mode=WAL;
PRAGMA synchronous=NORMAL;
PRAGMA temp_store=MEMORY;
PRAGMA cache_size=-20000;
CREATE TABLE IF NOT EXISTS checked_paths (
    path TEXT PRIMARY KEY,
    kind TEXT NOT NULL,
    size INTEGER NOT NULL,
    mtime INTEGER NOT NULL,
    status TEXT NOT NULL,
    last_checked TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_checked_paths_kind ON checked_paths(kind);
SQL
    sqlite3 "$DB_FILE" 'ALTER TABLE checked_paths ADD COLUMN signature TEXT;' >/dev/null 2>&1 || true
    sqlite3 "$DB_FILE" 'CREATE INDEX IF NOT EXISTS idx_checked_paths_signature ON checked_paths(signature);' >/dev/null 2>&1 || true
    DB_PENDING_SQL_FILE="$(mktemp)"
    while IFS='|' read -r path size mtime status signature; do
        [[ -n "$path" ]] || continue
        DB_CACHE_META["$path"]="$size|$mtime"
        DB_CACHE_STATUS["$path"]="$status"
        if [[ -n "$signature" ]]; then
            DB_CACHE_SIG["$signature"]=1
            DB_CACHE_SIG_STATUS["$signature"]="$status"
        fi
    done < <(sqlite3 -separator '|' "$DB_FILE" 'SELECT path, size, mtime, COALESCE(status, ""), COALESCE(signature, "") FROM checked_paths;')
}

db_has_valid_entry() {
    local path="$1"
    local abs meta cached status size mtime sig sig_status

    (( USE_DB == 1 )) || return 1
    (( FORCE_RECHECK == 0 )) || return 1
    [[ -e "$path" ]] || return 1

    abs="$(db_abs_path "$path")"
    cached="${DB_CACHE_META[$abs]-}"
    status="${DB_CACHE_STATUS[$abs]-}"

    if [[ -n "$cached" ]]; then
        if (( FAST_DB == 1 )); then
            return 0
        fi

        meta="$(db_get_size_mtime "$path" 2>/dev/null || true)"
        [[ -n "$meta" ]] || return 1
        size="${meta%%|*}"
        mtime="${meta##*|}"

        if [[ "$cached" == "$size|$mtime" ]]; then
            return 0
        fi
    fi

    if is_checksum_file "$path"; then
        sig="$(db_compute_signature "$path" 2>/dev/null || true)"
        sig_status="${DB_CACHE_SIG_STATUS[$sig]-}"
        if [[ -n "$sig" && -n "${DB_CACHE_SIG[$sig]-}" ]]; then
            if (( FAST_DB == 1 )); then
                return 0
            fi
            meta="$(db_get_size_mtime "$path" 2>/dev/null || true)"
            [[ -n "$meta" ]] || return 1
            size="${meta%%|*}"
            mtime="${meta##*|}"
            if [[ -n "$cached" && "$cached" == "$size|$mtime" ]]; then
                return 0
            fi
            if [[ "$sig_status" == "missing_refs" || "$sig_status" == "checked" ]]; then
                return 0
            fi
        fi
    fi

    return 1
}

db_mark_checked() {
    local path="$1"
    local kind="$2"
    local status="$3"
    local abs meta size mtime sig sql sig_sql

    (( USE_DB == 1 )) || return 0
    [[ -e "$path" ]] || return 0

    meta="$(db_get_size_mtime "$path" 2>/dev/null || true)"
    [[ -n "$meta" ]] || return 0
    abs="$(db_abs_path "$path")"
    size="${meta%%|*}"
    mtime="${meta##*|}"
    sig=""

    if is_checksum_file "$path"; then
        sig="$(db_compute_signature "$path" 2>/dev/null || true)"
        if [[ -n "$sig" ]]; then
            DB_CACHE_SIG["$sig"]=1
            DB_CACHE_SIG_STATUS["$sig"]="$status"
        fi
    fi

    DB_CACHE_META["$abs"]="$size|$mtime"
    DB_CACHE_STATUS["$abs"]="$status"

    if [[ -n "$sig" ]]; then
        sig_sql="'$(sql_escape "$sig")'"
    else
        sig_sql="NULL"
    fi

    sql="INSERT INTO checked_paths(path, kind, size, mtime, status, last_checked, signature) VALUES ('$(sql_escape "$abs")', '$(sql_escape "$kind")', $size, $mtime, '$(sql_escape "$status")', CURRENT_TIMESTAMP, $sig_sql) ON CONFLICT(path) DO UPDATE SET kind=excluded.kind, size=excluded.size, mtime=excluded.mtime, status=excluded.status, signature=excluded.signature, last_checked=CURRENT_TIMESTAMP;"
    printf '%s\n' "$sql" >> "$DB_PENDING_SQL_FILE"
    (( ++DB_PENDING_COUNT ))
    if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
        db_flush_pending
    fi
}

db_mark_many_checked() {
    local kind="$1"
    local status="$2"
    shift 2
    local path
    for path in "$@"; do
        db_mark_checked "$path" "$kind" "$status"
    done
}

db_rewrite_subtree() {
    local old_path="$1"
    local new_path="$2"
    local old_abs new_abs old_prefix new_prefix old_db_path new_db_path suffix sql
    local -a matched_paths=()

    (( USE_DB == 1 )) || return 0
    [[ -e "$new_path" ]] || return 0

    old_abs="$(db_abs_path "$old_path" 2>/dev/null || true)"
    new_abs="$(db_abs_path "$new_path" 2>/dev/null || true)"
    [[ -n "$old_abs" && -n "$new_abs" ]] || return 0

    old_prefix="${old_abs%/}/"
    new_prefix="${new_abs%/}/"

    for old_db_path in "${!DB_CACHE_META[@]}"; do
        if [[ "$old_db_path" == "$old_abs" || "$old_db_path" == "$old_prefix"* ]]; then
            matched_paths+=( "$old_db_path" )
        fi
    done

    (( ${#matched_paths[@]} > 0 )) || return 0

    for old_db_path in "${matched_paths[@]}"; do
        if [[ "$old_db_path" == "$old_abs" ]]; then
            new_db_path="$new_abs"
        else
            suffix="${old_db_path#"$old_prefix"}"
            new_db_path="${new_prefix}${suffix}"
        fi

        DB_CACHE_META["$new_db_path"]="${DB_CACHE_META[$old_db_path]}"
        unset 'DB_CACHE_META[$old_db_path]'

        sql="INSERT INTO checked_paths(path, kind, size, mtime, status, last_checked, signature) SELECT '$(sql_escape "$new_db_path")', kind, size, mtime, status, last_checked, signature FROM checked_paths WHERE path='$(sql_escape "$old_db_path")' ON CONFLICT(path) DO UPDATE SET kind=excluded.kind, size=excluded.size, mtime=excluded.mtime, status=excluded.status, signature=excluded.signature, last_checked=excluded.last_checked; DELETE FROM checked_paths WHERE path='$(sql_escape "$old_db_path")';"
        printf '%s
' "$sql" >> "$DB_PENDING_SQL_FILE"
        (( ++DB_PENDING_COUNT ))
        if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
            db_flush_pending
        fi
    done
}
while (( $# > 0 )); do
    case "$1" in
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        --use-db)
            USE_DB=1
            shift
            ;;
        --force-recheck)
            FORCE_RECHECK=1
            shift
            ;;
        --fast)
            FAST_DB=1
            shift
            ;;
        --colors)
            [[ $# -ge 2 ]] || { echo "Missing value for --colors" >&2; usage >&2; exit 1; }
            case "$2" in
                yes|no) CLI_COLORS="$2" ;;
                *) echo "Invalid value for --colors: $2 (use yes or no)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --mode)
            [[ $# -ge 2 ]] || { echo "Missing value for --mode" >&2; usage >&2; exit 1; }
            case "$2" in
                dry-run|real) CLI_MODE="$2" ;;
                *) echo "Invalid value for --mode: $2 (use dry-run or real)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --scope)
            [[ $# -ge 2 ]] || { echo "Missing value for --scope" >&2; usage >&2; exit 1; }
            case "$2" in
                current|subdirs) CLI_SCOPE="$2" ;;
                *) echo "Invalid value for --scope: $2 (use current or subdirs)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
done

load_exclude_filters
db_init

echo
echo "============================================================"
echo "  rename.sh  •  safe media + checksum rename helper"
echo "  version: $SCRIPT_VERSION"
echo "============================================================"

if (( USE_DB == 1 )); then
    echo
    echo "SQLite cache enabled: $DB_FILE"
    if (( FAST_DB == 1 )); then
        echo "SQLite cache mode: FAST (path-only skips; size/mtime checks disabled)"
    else
        echo "SQLite cache mode: SAFE (path + size + mtime must still match)"
    fi
    if (( FORCE_RECHECK == 1 )); then
        echo "SQLite cache mode override: force recheck enabled"
    fi
fi

if [[ -f "$EXCLUDE_FILTERS_FILE" ]]; then
    echo
    echo "Exclude filter file detected: $EXCLUDE_FILTERS_FILE"
    echo "Loaded filters: ${#EXCLUDE_FILTERS[@]}"
fi

use_colors=yes
input=""

if [[ -n "$CLI_COLORS" ]]; then
    case "$CLI_COLORS" in
        yes) use_colors=yes ;;
        no)  use_colors=no ;;
    esac
else
    echo
    echo "Use colors?"
    echo "  [Y] Yes (default)"
    echo "  [N] No"
    echo "  [Q] Quit"
    echo -n "Choice [Y/n/q]: "

    flush_stdin
    read_single_key input 60
    echo

    if [[ "$input" =~ [Qq] ]]; then
        echo "Quitting."
        exit 0
    elif [[ "$input" =~ [Nn] ]]; then
        use_colors=no
    fi
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

print_wrapped_two_path_verbose() {
    local prefix="$1"
    local first_path="$2"
    local suffix="$3"

    local line="${prefix}${first_path}${suffix}"
    local indent="          "

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "[VERBOSE] $line" >&2
    else
        echo "[VERBOSE] ${prefix}${first_path} " >&2
        echo "${indent}${suffix}" >&2
    fi
}

print_skip_path_reason() {
    local path="$1"
    local reason="$2"
    local line="SKIP: '$path' $reason"

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo -e "${YELLOW}SKIP:${RESET} '$path' $reason"
    else
        echo -e "${YELLOW}SKIP:${RESET} '$path'"
        echo "      $reason"
    fi
}

vlog() {
    (( VERBOSE == 1 )) || return 0
    echo -e "${CYAN}[VERBOSE]${RESET} $*" >&2
}

print_progress_box() {
    local progress="$1"
    local current="$2"
    local label1="Progress"
    local label2="Current"
    local label_width line1 line2 inner_width border_width border

    label_width=${#label1}
    (( ${#label2} > label_width )) && label_width=${#label2}

    printf -v line1 "%-*s | %s" "$label_width" "$label1" "$progress"
    printf -v line2 "%-*s | %s" "$label_width" "$label2" "$current"

    inner_width=${#line1}
    (( ${#line2} > inner_width )) && inner_width=${#line2}

    border_width=$((inner_width + 2))
    printf -v border '%*s' "$border_width" ''
    border=${border// /─}

    printf '┌%s┐
' "$border" >&2
    printf '│ %-*s │
' "$inner_width" "$line1" >&2
    printf '│ %-*s │
' "$inner_width" "$line2" >&2
    printf '└%s┘
' "$border" >&2
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

mode="dry-run"
input=""

if [[ -n "$CLI_MODE" ]]; then
    mode="$CLI_MODE"
else
    echo
    echo "Select mode:"
    echo "  [D] Dry-run (default)"
    echo "  [R] Real rename (interactive)"
    echo "  [Q] Quit"
    echo -n "Choice [D/r/q]: "

    flush_stdin
    read_single_key input 60
    echo

    if [[ "$input" =~ [Qq] ]]; then
        echo "Quitting."
        exit 0
    elif [[ "$input" =~ [Rr] ]]; then
        mode="real"
    fi
fi

echo -e "Mode selected: ${CYAN}$mode${RESET}"

process_scope="current"
input=""

if [[ -n "$CLI_SCOPE" ]]; then
    process_scope="$CLI_SCOPE"
else
    echo
    echo "What should be processed?"
    echo "  [C] Current directory only (default)"
    echo "  [S] Also subdirectories"
    echo "  [Q] Quit"
    echo -n "Choice [C/s/q]: "

    flush_stdin
    read_single_key input 60
    echo

    if [[ "$input" =~ [Qq] ]]; then
        echo "Quitting."
        exit 0
    elif [[ "$input" =~ [Ss] ]]; then
        process_scope="subdirs"
    fi
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

is_protected_checksum_name() {
    local p="$1"
    local base
    base="$(basename -- "$p")"
    is_checksum_file "$p" || return 1
    [[ "$base" == __* ]]
}

is_html_file() {
    local p="$1"
    local lower="${p,,}"
    [[ "$lower" == *.htm || "$lower" == *.html ]]
}

html_companion_dir_path_with_suffix() {
    local html_file="$1"
    local suffix="$2"
    local dir base stem
    dir="$(dirname -- "$html_file")"
    base="$(basename -- "$html_file")"
    stem="${base%.*}"
    printf '%s/%s%s' "$dir" "$stem" "$suffix"
}

find_html_companion_dir() {
    local html_file="$1"
    local candidate

    candidate="$(html_companion_dir_path_with_suffix "$html_file" "_files")"
    if [[ -d "$candidate" ]]; then
        printf '%s' "$candidate"
        return 0
    fi

    candidate="$(html_companion_dir_path_with_suffix "$html_file" "_pliki")"
    if [[ -d "$candidate" ]]; then
        printf '%s' "$candidate"
        return 0
    fi

    return 1
}

update_html_companion_reference() {
    local html_file="$1"
    local old_dir_name="$2"
    local new_dir_name="$3"
    local old_re new_re

    [[ -f "$html_file" ]] || return 0
    old_re="$(sed_escape_regex "$old_dir_name")"
    new_re="$(sed_escape_repl "$new_dir_name")"

    vlog "Updating HTML companion directory reference in '$html_file': '$old_dir_name' -> '$new_dir_name'"
    preserve_timestamps_inplace "$html_file"         sed -i -E "s|${old_re}|${new_re}|g" -- "$html_file"
}

update_checksum_hash_for_ref() {
    local sum_file="$1"
    local target_ref="$2"
    local actual_file="$3"
    local kind new_hash

    kind="$(checksum_kind "$sum_file")"
    new_hash="$(checksum_of_file "$kind" "$actual_file")"

    vlog "Updating stored checksum hash in '$sum_file' for ref '$target_ref'"

    preserve_timestamps_inplace "$sum_file"         python3 - "$sum_file" "$target_ref" "$new_hash" <<'PY'
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
target = sys.argv[2]
new_hash = sys.argv[3]

lines = path.read_text(encoding="utf-8", errors="surrogateescape").splitlines(True)
out = []
updated = False

for line in lines:
    m = re.match(r'^([0-9A-Fa-f]+)(\s+)(\*?)(.*?)(\r?\n?)$', line)
    if m and m.group(4) == target and not updated:
        out.append(new_hash + m.group(2) + m.group(3) + m.group(4) + m.group(5))
        updated = True
    else:
        out.append(line)

path.write_text(''.join(out), encoding="utf-8", errors="surrogateescape")
PY
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
    new="${new//Ĺ»/Z}"
    new="${new//Ĺš/S}"
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
    new="${new//rip.by.Crisp/}"

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

verify_single_checksum_target() {
    local sum_file="$1"
    local target_ref="$2"
    local kind sum_dir sum_base target_norm target_re matched_line

    kind="$(checksum_kind "$sum_file")"
    sum_dir="$(dirname -- "$sum_file")"
    sum_base="$(basename -- "$sum_file")"
    target_norm="$(strip_leading_dot_slash "$target_ref")"
    target_re="$(sed_escape_regex "$target_norm")"

    print_wrapped_two_path_verbose "Running single-target $(checksum_cmd "$sum_file") check in directory '"$sum_dir"'" " for ref '"$target_ref"' from file '"$sum_base"'"

    matched_line="$(
        sed -E 's/\r$//' -- "$sum_file" | grep -E "^[0-9a-fA-F]+[[:space:]]+\*?${target_re}$" | tail -n 1 || true
    )"

    [[ -n "$matched_line" ]] || return 1

    (
        cd "$sum_dir"
        case "$kind" in
            sha512) printf '%s\n' "$matched_line" | sha512sum -c --quiet --status ;;
            md5)    printf '%s\n' "$matched_line" | md5sum    -c --quiet --status ;;
        esac
    )
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
            -e "s|([[:space:]]\*?)${old_re1}\$|\1${new_re1}|g" \
            -e "s|([[:space:]]\*?)${old_re2}\$|\1${new_re2}|g" \
            -- "$sum_file"
}

declare -a LOCAL_UPDATE_SUM_FILES=()
declare -a LOCAL_UPDATE_OLD_REFS=()
declare -a LOCAL_UPDATE_NEW_REFS=()
declare -a LOCAL_UPDATE_VERIFY_FILES=()

collect_local_checksum_ref_updates() {
    local target_old="$1"
    local target_new="$2"
    local target_kind="$3"

    local current_dir sum_file hash ref resolved suffix new_actual old_ref_for_write new_ref_for_write
    local -A seen_sum_files=()

    LOCAL_UPDATE_SUM_FILES=()
    LOCAL_UPDATE_OLD_REFS=()
    LOCAL_UPDATE_NEW_REFS=()
    LOCAL_UPDATE_VERIFY_FILES=()

    current_dir="$(dirname -- "$target_old")"

    for sum_file in "$current_dir"/*.sha512 "$current_dir"/*.md5; do
        [[ -f "$sum_file" ]] || continue
        is_checksum_file "$sum_file" || continue

        while IFS=$'	' read -r hash ref; do
            [[ -n "$ref" ]] || continue
            resolved="$(resolve_checksum_ref_path "$sum_file" "$ref")"

            case "$target_kind" in
                file)
                    [[ "$resolved" == "$target_old" ]] || continue
                    new_actual="$target_new"
                    ;;
                directory)
                    if [[ "$resolved" == "$target_old" ]]; then
                        new_actual="$target_new"
                    elif [[ "$resolved" == "$target_old/"* ]]; then
                        suffix="${resolved#"$target_old"}"
                        new_actual="${target_new}${suffix}"
                    else
                        continue
                    fi
                    ;;
                *)
                    continue
                    ;;
            esac

            old_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "$ref" "$resolved")"
            new_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "$ref" "$new_actual")"

            [[ "$old_ref_for_write" == "$new_ref_for_write" ]] && continue

            LOCAL_UPDATE_SUM_FILES+=( "$sum_file" )
            LOCAL_UPDATE_OLD_REFS+=( "$old_ref_for_write" )
            LOCAL_UPDATE_NEW_REFS+=( "$new_ref_for_write" )

            if [[ -z "${seen_sum_files[$sum_file]+x}" ]]; then
                seen_sum_files["$sum_file"]=1
                LOCAL_UPDATE_VERIFY_FILES+=( "$sum_file" )
            fi
        done < <(extract_checksum_entries "$sum_file")
    done
}

declare -a PLAIN_REF_SUM_FILES=()

collect_local_checksum_ref_summaries() {
    local target_old="$1"
    local target_kind="$2"

    local current_dir sum_file hash ref resolved
    local -A seen=()

    PLAIN_REF_SUM_FILES=()
    current_dir="$(dirname -- "$target_old")"

    for sum_file in "$current_dir"/*.sha512 "$current_dir"/*.md5; do
        [[ -f "$sum_file" ]] || continue
        is_checksum_file "$sum_file" || continue

        while IFS=$'	' read -r hash ref; do
            [[ -n "$ref" ]] || continue
            resolved="$(resolve_checksum_ref_path "$sum_file" "$ref")"

            case "$target_kind" in
                file)
                    [[ "$resolved" == "$target_old" ]] || continue
                    ;;
                directory)
                    [[ "$resolved" == "$target_old" || "$resolved" == "$target_old/"* ]] || continue
                    ;;
                *)
                    continue
                    ;;
            esac

            if [[ -z "${seen[$sum_file]+x}" ]]; then
                seen["$sum_file"]=1
                PLAIN_REF_SUM_FILES+=( "$sum_file" )
            fi
        done < <(extract_checksum_entries "$sum_file")
    done
}

perform_plain_entry_rename() {
    local old="$1"
    local new="$2"
    local old_companion_dir="" new_companion_dir="" old_companion_name="" new_companion_name=""

    if [[ -e "$new" ]]; then
        echo -e "${YELLOW}SKIP:${RESET} Target file already exists."
        vlog "Collision detected for plain rename '$old' -> '$new'"
        ((++files_skipped))
        return 0
    fi

    if is_html_file "$old"; then
        old_companion_dir="$(find_html_companion_dir "$old" || true)"
        if [[ -z "$old_companion_dir" ]]; then
            new_companion_dir=""
        else
            old_companion_name="$(basename -- "$old_companion_dir")"
            old_html_stem="$(basename -- "${old%.*}")"
            companion_suffix="${old_companion_name#${old_html_stem}}"
            new_companion_dir="$(html_companion_dir_path_with_suffix "$new" "$companion_suffix")"
        fi

        if [[ -n "$old_companion_dir" && "$old_companion_dir" != "$new_companion_dir" && -e "$new_companion_dir" ]]; then
            echo -e "${YELLOW}SKIP:${RESET} Target companion directory already exists: $new_companion_dir"
            vlog "Collision detected for companion directory '$old_companion_dir' -> '$new_companion_dir'"
            ((++files_skipped))
            return 0
        fi
    fi

    if [[ "$mode" == "dry-run" ]]; then
        echo -e "${CYAN}[DRY-RUN] Would rename:${RESET} $old ${ARROW} $new"
        if [[ -n "$old_companion_dir" && "$old_companion_dir" != "$new_companion_dir" ]]; then
            echo -e "${CYAN}[DRY-RUN] Would rename companion directory:${RESET} $old_companion_dir ${ARROW} $new_companion_dir"
            echo -e "${CYAN}[DRY-RUN] Would update HTML reference inside:${RESET} $new"
        fi
        ((++files_affected))
        record_rename "$old" "$new"
        if [[ -n "$old_companion_dir" && "$old_companion_dir" != "$new_companion_dir" ]]; then
            record_rename "$old_companion_dir" "$new_companion_dir"
        fi
        return 0
    fi

    old_was_dir=no
    [[ -d "$old" ]] && old_was_dir=yes

    mv -i -- "$old" "$new"
    ((++files_affected))
    record_rename "$old" "$new"
    if [[ "$old_was_dir" == "yes" ]]; then
        db_rewrite_subtree "$old" "$new"
    fi
    db_mark_checked "$new" "plain" "checked"

    if [[ -n "$old_companion_dir" && "$old_companion_dir" != "$new_companion_dir" ]]; then
        if mv -i -- "$old_companion_dir" "$new_companion_dir"; then
            ((++files_affected))
            record_rename "$old_companion_dir" "$new_companion_dir"
            db_rewrite_subtree "$old_companion_dir" "$new_companion_dir"
            old_companion_name="$(basename -- "$old_companion_dir")"
            new_companion_name="$(basename -- "$new_companion_dir")"
            update_html_companion_reference "$new" "$old_companion_name" "$new_companion_name"
            db_mark_checked "$new_companion_dir" "html_companion" "checked"
        else
            mv -f -- "$new" "$old"
            ((++files_skipped))
            return 0
        fi
    fi

    return 0
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

handle_lnk_file() {
    local f="$1"
    local answer=""

    echo
    echo -e "${YELLOW}LNK FILE:${RESET} $f"
    echo -n "Remove this .lnk file? [y/N/q]: "

    flush_stdin
    read_single_key answer 300
    echo

    case "$answer" in
        q|Q)
            stopped_by_user=yes
            return 1
            ;;
        y|Y)
            if [[ "$mode" == "dry-run" ]]; then
                echo -e "${CYAN}[DRY-RUN] Would remove:${RESET} $f"
            else
                echo -e "${CYAN}REMOVE:${RESET} $f"
                rm -f -- "$f"
            fi
            ((++files_affected))
            return 0
            ;;
        *)
            ((++files_skipped))
            db_mark_checked "$f" "lnk" "kept"
            return 0
            ;;
    esac
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

print_checksum_group_preview() {
    local label="$1"
    local sum_old="$2"
    local sum_new="$3"
    shift 3
    local refs_name="$1"
    shift
    local new_refs_name="$1"

    local -n _refs="$refs_name"
    local -n _new_refs="$new_refs_name"
    local i shown=0

    echo

    if [[ "$sum_old" != "$sum_new" ]]; then
        echo -e "${RED}OLD ${label}:${RESET} $sum_old"
        echo -e "${GREEN}NEW ${label}:${RESET} $sum_new"
        shown=1
    fi

    for i in "${!_refs[@]}"; do
        [[ "${_new_refs[$i]}" != "${_refs[$i]}" ]] || continue
        echo -e "${RED}OLD FILE:${RESET} ${_refs[$i]}"
        echo -e "${GREEN}NEW FILE:${RESET} ${_new_refs[$i]}"
        shown=1
    done

    if (( shown == 0 )); then
        echo -e "${CYAN}NO VISIBLE RENAME CHANGES:${RESET} checksum content update only for $sum_old"
    fi
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
def is_checksum(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return 0 if (s.endswith(".sha512") or s.endswith(".md5")) else 1
items.sort(key=lambda p: (-depth(p), is_checksum(p), p))
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
def is_checksum(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return 0 if (s.endswith(".sha512") or s.endswith(".md5")) else 1
items.sort(key=lambda p: (-depth(p), is_checksum(p), p))
sys.stdout.buffer.write(b"\0".join(items) + (b"\0" if items else b""))
'
    )
fi

vlog "Discovered entries to process: ${#ordered_paths[@]}"

main_index=0
for f in "${ordered_paths[@]}"; do
    ((++main_index))
    if (( VERBOSE == 1 && main_index % VERBOSE_MAIN_EVERY == 0 )); then
        print_progress_box "$main_index / ${#ordered_paths[@]}" "$f"
    fi

    [[ -n "${processed[$f]+x}" ]] && continue
    ((++files_examined))

    if is_excluded_by_filter_file "$f"; then
        print_skip_path_reason "$f" "was ignored because part of its path matches a filter from $EXCLUDE_FILTERS_FILE."
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

    if [[ -f "$f" && "$f" == *.lnk ]]; then
        if ! handle_lnk_file "$f"; then
            break
        fi
        processed["$f"]=1
        continue
    fi

    if db_has_valid_entry "$f"; then
        echo -e "${CYAN}DB SKIP:${RESET} '$f'"
        ((++files_skipped))
        processed["$f"]=1
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
            db_mark_checked "$sum_file" "checksum_group" "missing_refs"
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
        if [[ "$new_sum" != "$sum_file" ]]; then
            if is_protected_checksum_name "$sum_file"; then
                vlog "Protected checksum name starts with double underscores, keeping checksum filename unchanged: '$sum_file'"
                new_sum="$sum_file"
            else
                sum_file_needs_rename=yes
            fi
        fi

        action_needed=no
        [[ "$refs_need_rename" == "yes" ]] && action_needed=yes
        [[ "$sum_file_needs_rename" == "yes" ]] && action_needed=yes
        [[ "$checksum_content_modified" == "yes" ]] && action_needed=yes

        if [[ "$action_needed" == "no" ]]; then
            vlog "All referenced files exist and no rename/update is needed for '$sum_file' - skipping without checksum verification"
            ((++files_skipped))
            db_mark_checked "$sum_file" "checksum_group" "checked"
            db_mark_many_checked "checksum_ref" "checked" "${refs[@]}"
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        if [[ "$mode" == "dry-run" ]]; then
            if [[ "$checksum_content_modified" == "yes" ]]; then
                echo -e "${CYAN}[DRY-RUN] Would check ${label} because checksum content would be modified:${RESET} $sum_file"
            else
                echo -e "${CYAN}[DRY-RUN] Would check ${label} because rename is needed:${RESET} $sum_file"
            fi
            print_checksum_group_preview "$label" "$sum_file" "$new_sum" refs new_refs
            echo -e "${CYAN}[DRY-RUN] Would update ${label,,} content references inside:${RESET} $sum_file"
            echo -e "${CYAN}[DRY-RUN] Would check changed ${label} reference(s) after rename:${RESET} $new_sum"
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

        print_checksum_group_preview "$label" "$sum_file" "$new_sum" refs new_refs

        do_rename=no
        if [[ "$rename_all" == "yes" ]]; then
            do_rename=yes
        else
            echo -n "Rename this ${label,,} group (hash file: $sum_file)? [Y/n/a/q]: "
            flush_stdin
            read_single_key input 300
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
                    read_single_key confirm 300
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

        changed_count=0
        for i in "${!refs[@]}"; do
            [[ "${new_refs[$i]}" != "${refs[$i]}" ]] && ((++changed_count))
        done

        if (( changed_count > 0 )); then
            echo -e "${CYAN}${label} check (before rename) in progress for changed reference(s)...${RESET} $sum_file"
            for i in "${!refs[@]}"; do
                [[ "${new_refs[$i]}" != "${refs[$i]}" ]] || continue
                if ! verify_single_checksum_target "$sum_file" "${refs_raw[$i]}"; then
                    echo -e "${YELLOW}${label} FAIL:${RESET} checksum mismatch for reference '${refs_raw[$i]}' in '$sum_file' (won't rename pair)"
                    stop_on_checksum_failure "$sum_file" "before rename"
                fi
            done
            echo -e "${CYAN}${label} VERIFIED (before rename):${RESET} changed reference(s) in $sum_file"
        fi

        declare -a html_companion_old_dirs=()
        declare -a html_companion_new_dirs=()
        declare -a html_companion_old_names=()
        declare -a html_companion_new_names=()
        declare -a html_companion_apply=()
        declare -a html_hash_needs_refresh=()

        collision=no
        [[ "$new_sum" != "$sum_file" && -e "$new_sum" ]] && collision=yes

        for i in "${!refs[@]}"; do
            html_companion_old_dirs+=( "" )
            html_companion_new_dirs+=( "" )
            html_companion_old_names+=( "" )
            html_companion_new_names+=( "" )
            html_companion_apply+=( "no" )
            html_hash_needs_refresh+=( "no" )

            [[ "${new_refs[$i]}" != "${refs[$i]}" ]] || continue
            [[ -e "${new_refs[$i]}" ]] && collision=yes

            if is_html_file "${refs[$i]}"; then
                old_companion_dir="$(find_html_companion_dir "${refs[$i]}" || true)"
                if [[ -n "$old_companion_dir" ]]; then
                    old_companion_name="$(basename -- "$old_companion_dir")"
                    old_html_stem="$(basename -- "${refs[$i]%.*}")"
                    companion_suffix="${old_companion_name#${old_html_stem}}"
                    new_companion_dir="$(html_companion_dir_path_with_suffix "${new_refs[$i]}" "$companion_suffix")"
                else
                    new_companion_dir=""
                fi

                if [[ -n "$old_companion_dir" && "$old_companion_dir" != "$new_companion_dir" ]]; then
                    companion_conflict=no
                    for j in "${!refs[@]}"; do
                        if [[ "${refs[$j]}" == "$old_companion_dir" || "${refs[$j]}" == "$old_companion_dir/"* ]]; then
                            companion_conflict=yes
                            break
                        fi
                    done

                    if [[ "$companion_conflict" == "no" ]]; then
                        [[ -e "$new_companion_dir" ]] && collision=yes
                        html_companion_old_dirs[$i]="$old_companion_dir"
                        html_companion_new_dirs[$i]="$new_companion_dir"
                        html_companion_old_names[$i]="$(basename -- "$old_companion_dir")"
                        html_companion_new_names[$i]="$(basename -- "$new_companion_dir")"
                        html_companion_apply[$i]="yes"
                    fi
                fi
            fi
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
                ref_was_dir=no
                [[ -d "${refs[$i]}" ]] && ref_was_dir=yes
                vlog "Renaming referenced file '${refs[$i]}' -> '${new_refs[$i]}'"
                mv -i -- "${refs[$i]}" "${new_refs[$i]}"
                if [[ "$ref_was_dir" == "yes" ]]; then
                    db_rewrite_subtree "${refs[$i]}" "${new_refs[$i]}"
                fi
                register_current_file_rename "${refs[$i]}" "${new_refs[$i]}"
                ((++files_affected))
                record_rename "${refs[$i]}" "${new_refs[$i]}"

                if [[ "${html_companion_apply[$i]}" == "yes" ]]; then
                    echo -e "${CYAN}HTML PAIR RENAME:${RESET} HTML file and companion directory are being updated together."
                    echo -e "  ${RED}OLD HTML:${RESET} ${refs[$i]}"
                    echo -e "  ${GREEN}NEW HTML:${RESET} ${new_refs[$i]}"
                    echo -e "  ${RED}OLD DIR:${RESET}  ${html_companion_old_dirs[$i]}"
                    echo -e "  ${GREEN}NEW DIR:${RESET}  ${html_companion_new_dirs[$i]}"
                    vlog "Renaming HTML companion directory '${html_companion_old_dirs[$i]}' -> '${html_companion_new_dirs[$i]}'"
                    mv -i -- "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"
                    db_rewrite_subtree "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"
                    register_current_file_rename "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"
                    ((++files_affected))
                    record_rename "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"
                    update_html_companion_reference "${new_refs[$i]}" "${html_companion_old_names[$i]}" "${html_companion_new_names[$i]}"
                    echo -e "${CYAN}HTML PAIR UPDATED:${RESET} companion reference inside HTML file was updated from '${html_companion_old_names[$i]}' to '${html_companion_new_names[$i]}'."
                    html_hash_needs_refresh[$i]="yes"
                fi
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

            if [[ "${html_hash_needs_refresh[$i]}" == "yes" ]]; then
                update_checksum_hash_for_ref "$sum_file" "$new_ref_for_write" "${new_refs[$i]}"
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

        if (( changed_count > 0 )); then
            echo -e "${CYAN}${label} check (after rename) in progress for changed reference(s)...${RESET} $final_sum"
            for i in "${!refs[@]}"; do
                [[ "${new_refs[$i]}" != "${refs[$i]}" ]] || continue
                new_ref_for_verify="$(format_ref_for_checksum_file "$final_sum" "${refs_raw[$i]}" "${new_refs[$i]}")"
                if ! verify_single_checksum_target "$final_sum" "$new_ref_for_verify"; then
                    echo -e "${YELLOW}${label} FAIL (after rename):${RESET} reference '$new_ref_for_verify' in '$final_sum' does not validate."
                    echo -e "${YELLOW}NOTE:${RESET} Files were renamed, but checksum verification after update failed."
                    stop_on_checksum_failure "$final_sum" "after rename"
                fi
            done
            echo -e "${CYAN}${label} VERIFIED (after rename):${RESET} changed reference(s) in $final_sum"
            echo -e "${GREEN}${label} OK:${RESET} changed reference(s) were updated inside '$final_sum' and ${label,,} checksum(s) are correct."
        fi

        finish_current_operation
        vlog "Finished checksum group '$sum_file'"

        db_mark_checked "$final_sum" "checksum_group" "checked"
        db_mark_many_checked "checksum_ref" "checked" "${new_refs[@]}"
        for i in "${!html_companion_new_dirs[@]}"; do
            if [[ "${html_companion_apply[$i]}" == "yes" ]]; then
                db_mark_checked "${html_companion_new_dirs[$i]}" "html_companion" "checked"
            fi
        done

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
        db_mark_checked "$f" "plain" "checked"
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
    echo -n "Rename this entry? [Y/n/a/E/q]: "
    flush_stdin
    read_single_key input 300
    echo

    case "$input" in
        q|Q)
            stopped_by_user=yes
            break
            ;;
        n|N)
            ((++files_skipped))
            ;;
        E)
            append_path_to_exclude_filters_file "$f"
            ((++files_skipped))
            processed["$f"]=1
            ;;
        a|A)
            echo
            echo "⚠️  This will rename ALL remaining files/directories."
            echo -n "Are you sure? [y/N]: "
            flush_stdin
            read_single_key confirm 300
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

