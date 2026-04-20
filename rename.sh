#!/usr/bin/env bash
# 2026.04.20 - v. 18.40 - add explicit delete-phase progress for DB maintenance missing-row cleanup
# 2026.04.20 - v. 18.39 - print DB maintenance crosscheck percent and absolute counters together in one progress line
# 2026.04.20 - v. 18.38 - increase DB maintenance crosscheck progress cadence to every 5% and every 500 checked paths
# 2026.04.20 - v. 18.37 - add DB maintenance crosscheck progress updates every 10% and every 1000 checked paths
# 2026.04.20 - v. 18.36 - wrap verbose DB-maintenance missing-file removal messages into clean two-line output
# 2026.04.20 - v. 18.35 - in verbose DB maintenance, state that missing filesystem files are removed from DB entries
# 2026.04.20 - v. 18.34 - in DB maintenance, verify cached paths exist on disk, remove missing rows, and print prune stats
# 2026.04.20 - v. 18.33 - remove .WnA. marker fragments from filenames during normalization
# 2026.04.20 - v. 18.32 - prompt before replacing existing DB hash values (Y/n/q) and log skip decisions explicitly
# 2026.04.20 - v. 18.31 - make DB hash verbose messages distinguish backfilled hashes from updated existing hashes
# 2026.04.20 - v. 18.30 - fix manual rename-by-editing output stream so prompt text is not captured as destination path
# 2026.04.19 - v. 18.29 - add manual "rename by editing" option with readline editing keys in plain rename prompt
# 2026.04.19 - v. 18.28 - remove periodic main-loop heartbeat verbose lines while keeping startup and resume progress logs
# 2026.04.19 - v. 18.27 - add startup transfer-to-shell progress after sorting so large handoff phase is visible
# 2026.04.19 - v. 18.26 - add verbose checkpoint-restore progress and periodic main-loop heartbeat to show activity
# 2026.04.19 - v. 18.25 - add richer verbose startup progress (buffered size + elapsed time) for long discovery/sort phase
# 2026.04.19 - v. 18.24 - wrap checksum-group referenced-file rename verbose lines using MAX_LINE_LENGTH helper
# 2026.04.19 - v. 18.23 - include timestamps in startup tags as [STARTUP YYYY-MM-DD HH:MM:SS]
# 2026.04.19 - v. 18.22 - show startup discovery/sort progress with verbose dots so long scans do not look stuck
# 2026.04.19 - v. 18.21 - show verbose timestamps on actual question lines (not after choice prompt)
# 2026.04.19 - v. 18.20 - print verbose timestamp before every interactive read_single_key prompt
# 2026.04.19 - v. 18.19 - make --run-db-maintenance imply DB mode and exit cleanly when DB file is missing
# 2026.04.19 - v. 18.18 - make DB maintenance manual-only via --run-db-maintenance and show verbose command steps
# 2026.04.19 - v. 18.17 - add SQLite maintenance modes (auto/off/full) with periodic optimize/checkpoint metadata
# 2026.04.19 - v. 18.16 - make early resume prompt quit option exit immediately
# 2026.04.19 - v. 18.15 - add quit option [q] to resume prompt flow
# 2026.04.19 - v. 18.14 - make ask-mode resume prompt default to resume ([Y/n]) to match default resume behavior
# 2026.04.19 - v. 18.13 - show resume first in --resume-state help values
# 2026.04.19 - v. 18.12 - make resume-state default to automatic resume and reflect it in help text
# 2026.04.19 - v. 18.11 - ask for resume immediately after CLI parsing and before startup preparation
# 2026.04.19 - v. 18.10 - mark default values in help option choices with [ ]
# 2026.04.19 - v. 18.9 - add interrupt checkpoint resume support with --resume-state mode
# 2026.04.19 - v. 18.8 - wrap long checksum verbose lines using MAX_LINE_LENGTH without splitting filenames
# 2026.04.19 - v. 18.7 - speed up DB hash cache lookups and avoid repeated subtree find scans during missing-ref recovery
# 2026.04.19 - v. 18.6 - bump script version
# 2026.04.19 - v. 18.5 - in verbose mode print a boxed startup summary of effective options with explanations
# 2026.04.19 - v. 18.3 - add a help example line and reorder displayed --mode/--scope option choices
# 2026.04.19 - v. 18.2 - derive SCRIPT_VERSION automatically from the first history line instead of hardcoding it
# 2026.04.18 - v. 18.1 - add exact path exceptions so a directory can be protected from rename while its subtree is still checked
# 2026.04.18 - v. 18.0 - broaden transform_name timestamp-style media renames to common audio extensions
# 2026.04.18 - v. 17.9 - rename Sprache_YYMMDD_HHMMSS_suffix and Voice_YYMMDD_HHMMSS_suffix media files to timestamped sprache/voice names
# 2026.04.18 - v. 17.8 - generalize Screen_Recording_YYYYMMDD_HHMMSS_suffix media renaming to timestamped screen_recording-<suffix> names
# 2026.04.18 - v. 17.7 - rename Screen_Recording_YYYYMMDD_HHMMSS_Signal media files to timestamped screen_recording-signal names
# 2026.04.15 - v. 17.6 - treat M3U helper exit code 3 as no-change under set -e and do not abort in wrapper/caller paths
# 2026.04.15 - v. 17.5 - treat no-change Python M3U helper exits as normal results under set -e and avoid aborting on no-update playlist checks
# 2026.04.15 - v. 17.2 - simplify no-op M3U messages to checked/no update needed and avoid OLD/NEW noise for effectively matching playlist entries
# 2026.04.14 - v. 16.8 - suppress no-op M3U UPDATED lines in both direct and subtree playlist rewrites, and skip identical replacement entries cleanly
# 2026.04.14 - v. 16.6 - fix fake no-op M3U UPDATED logs, make M3U key normalization safe for broken playlist bytes, and normalize apostrophes in playlist matching
# 2026.04.14 - v. 16.9 - fix broken quote normalization in M3U candidate matching and keep binary-safe playlist key output
# 2026.04.14 - v. 17.0 - show the startup banner before usage when -h or --help is used
# 2026.04.13 - v. 16.0 - skip slash-only M3U rewrites, persist per-kind hashes in DB, and remove stale DB rows missing on disk
# 2026.04.13 - v. 15.7 - add --wait-seconds prompt timeout control and print current interactive wait behavior
# 2026.04.13 - v. 15.6 - show SQLite warmup percentages together with row counts during startup
# 2026.04.13 - v. 15.5 - restore a nice startup banner before startup progress lines and keep downloadable filename aligned with script version
# 2026.04.13 - v. 15.4 - show explicit startup progress for exclude loading and SQLite cache warmup, and keep downloadable filename aligned with script version
# 2026.04.13 - v. 15.3 - fix CRLF-sensitive M3U entry replacement so prepared updates actually get written
# 2026.04.13 - v. 15.2 - fix protected internal files, make M3U single-entry replacement more robust, and count DB row operations in summary
# 2026.04.11 - v. 15.1 - skip immediately when an exception already exists and fix the E prompt text
# 2026.04.11 - v. 15.0 - fix .m3u CRLF updates, handle backslash paths in subtree matching, and avoid UnicodeEncodeError when printing odd playlist entries
# 2026.04.11 - v. 14.9 - skip final .m3u checks/fixes when interrupted with Ctrl-C and exit immediately after summary
# 2026.04.11 - v. 14.8 - make .m3u skip messages explicit: distinguish no match, identical replacement, and write failure
# 2026.04.11 - v. 14.7 - do not prompt to rename .par2 files whose basename starts with an underscore
# 2026.04.11 - v. 14.6 - treat both e and E as 'add exception' in the plain-entry prompt
# 2026.04.11 - v. 14.5 - preserve _-_ separators in transformed names and replace fragile sed-based m3u key normalization with a python implementation
# 2026.04.11 - v. 14.4 - search .m3u missing entries in the playlist subtree by similar name and show OLD/NEW before updating playlist references
# 2026.04.11 - v. 14.3 - add per-file choices for @ and Ŕ, add €->c and si@->sie, and lowercase extensions only for actual files
# 2026.04.11 - v. 14.1 - fix per-file ŕ/® choice prompts so only the selected mapping goes to stdout and prompt text no longer pollutes filenames
# 2026.04.11 - v. 14.0 - remove leftover startup mapping prompts so ŕ and ® choices are only asked per file
# 2026.04.11 - v. 13.9 - move ŕ and ® mapping choices from startup to per-file prompts so they can be chosen case by case
# 2026.04.11 - v. 13.8 - show ŕ and ® mapping choices reliably during startup before any file processing begins
# 2026.04.11 - v. 13.7 - make ŕ and ® mappings selectable at startup and keep si`/Ä/% and media-only @ normalization rules
# 2026.04.11 - v. 13.6 - lowercase file extensions and add more filename normalization rules including media-only @ -> a
# 2026.04.11 - v. 13.5 - undo backtick replacement and change ŕ mapping to 's ' instead of 'c '
# 2026.04.11 - v. 13.4 - add more mojibake fixes, zero-pad numeric media basenames, update/check .m3u playlists, limit affected list to last 100, and remove more ebook markers
# 2026.04.11 - v. 13.3 - strip leading underscores from final media basenames and update/add DB rows for renamed files so DB summary reflects renames
# 2026.04.11 - v. 13.2 - move summary after affected entries, remove leading underscores from media basenames, and support wildcard exclude masks like *.cpp and *.h
# 2026.04.11 - v. 13.1 - reuse cached DB file hashes instead of recalculating them unless --force-recheck is used
# 2026.04.11 - v. 13.0 - add start/finish timestamps and processed/hashed counters to summary, and always print summary on Ctrl-C
# 2026.04.11 - v. 12.9 - clean up checksum-group prompt layout and use rich collision dialog for checksum-group file collisions too
# 2026.04.11 - v. 12.8 - make recovery outcome explicit and add DB hash/cache accounting in logs and summary
# 2026.04.11 - v. 12.7 - store computed file MD5/SHA512 values in SQLite and use them first for subtree recovery lookups
# 2026.04.11 - v. 12.6 - add support for filenames starting with YYYY-MM-DD_HH-MM-SS...
# 2026.04.11 - v. 12.5 - add date normalization rules for YYMMDD_HHMMSS_-_* and YYYYMMDD-HHMMSS_-_* filenames
# 2026.04.11 - v. 12.4 - fix collision prompt so it displays immediately instead of being swallowed by command substitution
# 2026.04.11 - v. 12.3 - enrich plain-file collision dialog with size/timestamps and add rename-with-_OTHER option
# 2026.04.11 - v. 12.2 - on plain-file collision, compare MD5 of source and destination and ask what to do instead of auto-skipping
# 2026.04.11 - v. 12.1 - normalize IMG_/PXL_/received_ media filenames using embedded timestamps or older of creation/modification time
# 2026.04.11 - v. 12.0 - restore -v/--verbose as verbose mode and keep --version for version/help output
# 2026.04.11 - v. 11.9 - include DB filename and exclude file path in --version / -v output
# 2026.04.11 - v. 11.8 - make --version and -v print version plus usage/help and exit immediately
# 2026.04.11 - v. 11.7 - add support for signal-YYYY-MM-DD-HHMMSS.ext filenames without an extra suffix
# 2026.04.11 - v. 11.6 - collapse double dashes in basenames to a single dash
# 2026.04.11 - v. 11.5 - add support for signal-YYYY-MM-DD-HHMMSS_... filenames
# 2026.04.11 - v. 11.4 - rename filenames starting with YYYY-MM-DD-HH-MM-SS-... to YYYYMMDD_HHMMSS-...
# 2026.04.11 - v. 11.3 - generalize signal filename renaming so any suffix after the timestamp becomes YYYYMMDD_HHMMSS-signal-<suffix>
# 2026.04.11 - v. 11.2 - support signal filenames with extra numeric suffixes like signal-YYYY-MM-DD-HH-MM-SS-823-2.jpg
# 2026.04.11 - v. 11.1 - timestamp video*.mp4 from the older of file creation time and modification time
# 2026.04.11 - v. 11.0 - timestamp image*.jpg from the older of file creation time and modification time
# 2026.04.11 - v. 10.9 - prefix image*.jpg files with YYYYMMDD_HHMMSS_
# 2026.04.11 - v. 10.8 - rename .jpeg extensions to .jpg and keep header history updated with the current date
# 2026.04.07 - v. 10.7 - only initialize or migrate SQLite when --use-db is explicitly enabled
# 2026.04.09 - v. 10.6 - fix checksum-update/recovery verbose formatting and add extra basename cleanup/removal rules
# 2026.04.07 - v. 10.5 - on plain-file rename collision, allow overwrite when source and destination MD5 checksums are identical
# 2026.04.07 - v. 10.4 - remove leading exclamation marks from basenames and strip [Audiobook PL] from names
# 2026.04.07 - v. 10.3 - wrap long verbose rename lines, including the per-directory auto-yes variant, into two lines
# 2026.04.07 - v. 10.2 - add per-directory auto-yes option (d) for rename prompts and replace one-line prompt text with explained multi-line menus
# 2026.04.07 - v. 10.1 - keep wrapped checksum-update verbose messages as two-liners after the missing-ref helper fix
# 2026.04.07 - v. 10.0 - fix unbound $3 in wrapped checksum-update verbose helper during missing-ref recovery
# 2026.04.07 - v. 9.9 - add checksum-based subtree fallback for missing hash references after directory and filename renames
# 2026.04.07 - v. 9.8 - fix remaining wrapped verbose helper functions that still bypassed the VERBOSE flag
# 2026.04.07 - v. 9.7 - fix remaining wrapped 'no rename/update is needed' messages so they only print in verbose mode
# 2026.04.07 - v. 9.6 - fix wrapped verbose helper functions so they respect VERBOSE=0 unless -v/--verbose is used
# 2026.04.07 - v. 9.5 - wrap long protected-checksum, no-action checksum, and missing-ref verbose lines into cleaner two-line output
# 2026.04.07 - v. 9.4 - fix syntax error in handle_lnk_file() function header; preserve full script history
# 2026.04.03 - v. 9.3 - add more filename cleanups and search missing checksum refs in the hash-file directory subtree
# 2026.04.03 - v. 9.2 - wrap long verbose resolved-ref lines into two lines using MAX_LINE_LENGTH
# 2026.04.03 - v. 9.1 - add Å¼->z, remove ._osloskop.net, collapse double dots, and wrap long checksum-update verbose lines
# 2026.04.03 - v. 9.0 - fix long single-target checksum verbose lines by formatting directory, ref, and hash file separately
# 2026.04.03 - v. 8.9 - fix wrapped single-target verbose line split and make plain HTML+companion directory rename a single visible prompt/action
# 2026.04.03 - v. 8.8 - define MAX_LINE_LENGTH early so wrapped output helpers never hit an unbound variable
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
# 2026.04.15 - v. 17.3 - escape control characters in logged paths and warn explicitly about filenames containing them
SCRIPT_VERSION="$(LC_ALL=C grep -m1 '^# [0-9]' "$0" | sed -E 's/^# ([0-9]{4}\.[0-9]{2}\.[0-9]{2} - v\. [0-9]+\.[0-9]+) - .*/\1/')"
LARGE_HASHFILE_LINE_THRESHOLD=20
MAX_LINE_LENGTH=200
START_DIR="$(pwd -P)"
EXCLUDE_FILTERS_FILE="$START_DIR/_exclude-rename.sh.txt"
USE_DB=0
FORCE_RECHECK=0
FAST_DB=0
DB_FILE="$START_DIR/_rename.sh-optional-db.sqlite3"
LEGACY_DB_FILE="$START_DIR/rename.sh-optional-db.sqlite3"
DB_HASHES_ADDED=0
DB_ROWS_NEW=0
DB_ROWS_UPDATED=0
DB_ROWS_REMOVED=0
DB_HASH_LOOKUP_HITS=0
DB_HASH_LOOKUP_MISSES=0
DB_HASH_RECORD_STATUS=""
DB_RECOVERY_RESULT=""
DB_STALE_ROWS_REMOVED=0
DB_MAINT_ROWS_CHECKED=0
DB_MAINT_ROWS_MISSING=0
DB_MAINT_ROWS_REMOVED=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd -P)"
DEBUG_LOG_PATH="${DEBUG_LOG_PATH:-$WORKSPACE_ROOT/debug-8439cd.log}"
DEBUG_SESSION_ID="8439cd"
DEBUG_RUN_ID="${DEBUG_RUN_ID:-pre-fix}"

set -Eeuo pipefail
shopt -s nullglob

VERBOSE=0
VERBOSE_MAIN_EVERY=200
CLI_COLORS=""
CLI_MODE=""
CLI_SCOPE=""
CLI_RESUME_STATE="resume"
CLI_DB_MAINTENANCE="full"
RUN_DB_MAINTENANCE=0
PROMPT_WAIT_SECONDS=0
MAP_R_ACUTE="c"
MAP_REGISTERED="z"
MAP_AT_SIGN="a"
MAP_R_GRAVE="c"

CURRENT_OP_ACTIVE=0
CURRENT_OP_LABEL=""
CURRENT_OP_SUM_OLD=""
CURRENT_OP_SUM_NEW=""
CURRENT_OP_SUM_RENAMED=0
CURRENT_OP_CONTENT_FILE=""
CURRENT_OP_CONTENT_BACKUP=""
COLLISION_OTHER_PATH=""
COLLISION_RENAMED_TARGET=""
SCRIPT_START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
SCRIPT_FINISH_TIME=""
SUMMARY_PRINTED=0
FILES_HASHED=0
RESUME_STATE_FILE="$START_DIR/_rename.sh.resume-state.json"
RESUME_STATE_WAS_LOADED=0
EARLY_RESUME_DECISION=""
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

debug_log() {
    local hypothesis_id="$1"
    local location="$2"
    local message="$3"
    local data="$4"
    local timestamp
    local log_id
    timestamp="$(date +%s%3N 2>/dev/null || printf '%s000' "$(date +%s)")"
    log_id="log_${timestamp}_$$"
    printf '{"sessionId":"%s","id":"%s","timestamp":%s,"location":"%s","message":"%s","data":%s,"runId":"%s","hypothesisId":"%s"}\n' \
        "$DEBUG_SESSION_ID" "$log_id" "$timestamp" "$location" "$message" "$data" "$DEBUG_RUN_ID" "$hypothesis_id" >> "$DEBUG_LOG_PATH"
}

usage() {
    cat <<'EOF'
Usage: rename.sh [-v|--verbose] [--use-db] [--fast] [--force-recheck] [--run-db-maintenance] [--db-maintenance auto|[full]] [--colors [yes]|no] [--mode real|[dry-run]] [--scope subdirs|[current]] [--resume-state [resume]|ask|fresh] [--wait-seconds [0]|N] [--version] [-h|--help]

Options:
  -v, --verbose          Show extra diagnostic output
  --version              Print version plus this usage/help and exit
  --use-db               Use SQLite cache in the start directory (_rename.sh-optional-db.sqlite3)
  --fast                 With --use-db, trust cached paths without checking current size/mtime
  --force-recheck        Ignore SQLite cache and recheck everything
  --run-db-maintenance   Run DB maintenance and exit (manual invocation; implies --use-db)
  --db-maintenance auto|[full]
                         auto: lightweight optimize/checkpoint profile
                         [full]: optimize + analyze + reindex + WAL truncate profile
  --colors [yes]|no      Skip the startup colors question
  --mode real|[dry-run]  Skip the startup mode question
  --scope subdirs|[current]
                         Skip the startup scope question
  --resume-state [resume]|ask|fresh
                         [resume]: automatically resume from checkpoint if it exists (default)
                         ask: if checkpoint exists, ask to resume or restart
                         fresh: always start from beginning
  --wait-seconds [0]|N   Wait N seconds for each interactive answer; 0 means wait forever
  -h, --help             Show this help

Example:
  rename.sh -v --use-db --colors yes --mode real --scope subdirs
  rename.sh -v --use-db --fast --colors yes --mode real --scope subdirs
  rename.sh --run-db-maintenance --db-maintenance full
  rename.sh --resume-state ask --use-db --mode real --scope subdirs
EOF
}

print_prompt_wait_description() {
    if (( PROMPT_WAIT_SECONDS == 0 )); then
        printf '%s' 'infinite (wait until user enters a response)'
    else
        printf '%s' "${PROMPT_WAIT_SECONDS} second(s)"
    fi
}

print_startup_banner() {
    local width=60
    local line1="rename.sh"
    local line2="safe media + checksum rename helper"
    local line3="Version     : $SCRIPT_VERSION"
    local line4="Start dir   : $START_DIR"
    local line5="Prompt wait : $(print_prompt_wait_description)"
    local charmap

    charmap="$(locale charmap 2>/dev/null || printf 'unknown')"
    #region agent log
    debug_log "H1" "rename.sh:print_startup_banner" "About to print banner characters" "{\"charmap\":\"${charmap}\",\"lang\":\"${LANG:-unset}\",\"lc_all\":\"${LC_ALL:-unset}\",\"term\":\"${TERM:-unset}\"}"
    #endregion

    printf '┌%*s┐
' "$width" '' | tr ' ' '─'
    printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line1"
    printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line2"
    printf '├%*s┤
' "$width" '' | tr ' ' '─'
    printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line3"
    printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line4"
    printf '│ %-*.*s │
' $((width - 2)) $((width - 2)) "$line5"
    printf '└%*s┘
' "$width" '' | tr ' ' '─'
}

startup_progress() {
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[STARTUP ${ts}] $*"
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

    if [[ "$__timeout" =~ ^[0-9]+$ ]] && (( __timeout == 0 )); then
        IFS= read -r -n 1 __char || true
    else
        IFS= read -r -t "$__timeout" -n 1 __char || true
    fi
    printf -v "$__var_name" '%s' "$__char"

    # Discard any extra buffered keypresses from the same burst so they do not
    # affect the next prompt or keep the pre-read drain loop busy.
    flush_stdin
}

read_line_editable() {
    local __var_name="$1"
    local __timeout="$2"
    local __initial="${3-}"
    local __line=""

    if [[ "$__timeout" =~ ^[0-9]+$ ]] && (( __timeout == 0 )); then
        IFS= read -r -e -i "$__initial" __line || true
    else
        IFS= read -r -e -t "$__timeout" -i "$__initial" __line || true
    fi
    printf -v "$__var_name" '%s' "$__line"
}

verbose_question_timestamp() {
    (( VERBOSE == 1 )) || return 0
    local question="$1"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[VERBOSE] [${ts}] ${question}" >&2
}

verbose_status_timestamp() {
    (( VERBOSE == 1 )) || return 0
    local msg="$1"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[VERBOSE] [${ts}] ${msg}" >&2
}

confirm_db_hash_update_for_existing_entry() {
    local path="$1"
    local hash_kind="$2"
    local old_hash="$3"
    local new_hash="$4"
    local answer=""

    echo
    verbose_question_timestamp "Stored ${hash_kind} hash differs for this entry. Replace it?"
    echo "DB hash differs for existing entry:"
    echo "  path:     $path"
    echo "  kind:     $hash_kind"
    echo "  stored:   $old_hash"
    echo "  computed: $new_hash"
    echo "Replace stored hash with computed value?"
    echo "  [Y] Yes (default)"
    echo "  [N] No (keep existing DB hash)"
    echo "  [Q] Quit"
    echo -n "Choice [Y/n/q]: "
    flush_stdin
    read_single_key answer "$PROMPT_WAIT_SECONDS"
    echo

    case "$answer" in
        q|Q) return 2 ;;
        n|N) return 1 ;;
        *) return 0 ;;
    esac
}

prompt_resume_choice_early() {
    local answer=""

    [[ "$CLI_RESUME_STATE" == "ask" ]] || return 0
    [[ -f "$RESUME_STATE_FILE" ]] || return 0

    echo
    echo "Checkpoint found from an interrupted run: $RESUME_STATE_FILE"
    verbose_question_timestamp "Resume from checkpoint?"
    echo "Resume from checkpoint?"
    echo "  [Y] Resume (default)"
    echo "  [N] Start from the beginning"
    echo "  [Q] Quit"
    echo -n "Choice [Y/n/q]: "
    flush_stdin
    read_single_key answer "$PROMPT_WAIT_SECONDS"
    echo

    if [[ "$answer" =~ [Qq] ]]; then
        echo "Quitting."
        exit 0
    elif [[ "$answer" =~ [Nn] ]]; then
        EARLY_RESUME_DECISION="fresh"
    else
        EARLY_RESUME_DECISION="resume"
    fi
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

get_file_oldest_timestamp_yyyymmdd_hhmmss() {
    local file="$1"
    local mtime epoch btime

    mtime="$(stat -c %Y -- "$file" 2>/dev/null || echo 0)"
    btime="$(stat -c %W -- "$file" 2>/dev/null || echo 0)"

    epoch="$mtime"
    if [[ "$btime" =~ ^[0-9]+$ ]] && (( btime > 0 )) && (( btime < epoch )); then
        epoch="$btime"
    fi

    date -d "@$epoch" +%Y%m%d_%H%M%S
}

get_file_oldest_timestamp_compact() {
    local file="$1"
    local ts
    ts="$(get_file_oldest_timestamp_yyyymmdd_hhmmss "$file")"
    printf '%s' "${ts:0:8}_${ts:9:6}"
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
    local base
    local exact_target

    base="$(basename -- "$p")"

    for filter in "${EXCLUDE_FILTERS[@]}"; do
        if [[ "$filter" == =* ]]; then
            exact_target="${filter#=}" 
            if [[ "$p" == "$exact_target" ]]; then
                return 0
            fi
            continue
        fi

        if [[ "$filter" == *'*'* || "$filter" == *'?'* || "$filter" == *'['* ]]; then
            if [[ "$base" == $filter || "$p" == $filter ]]; then
                return 0
            fi
        else
            if [[ "$p" == *"$filter"* ]]; then
                return 0
            fi
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

exact_exception_entry_for_path() {
    local p="$1"
    printf '=%s' "$p"
}

exception_exists_for_path() {
    local path="$1"
    local entry=""
    local exact_entry=""
    local existing

    entry="$(path_to_exclude_entry "$path")"
    exact_entry="$(exact_exception_entry_for_path "$path")"
    [[ -n "$entry" || -n "$exact_entry" ]] || return 1

    for existing in "${EXCLUDE_FILTERS[@]}"; do
        [[ -n "$entry" && "$existing" == "$entry" ]] && return 0
        [[ -n "$exact_entry" && "$existing" == "$exact_entry" ]] && return 0
    done
    return 1
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

append_exact_path_to_exclude_filters_file() {
    local p="$1"
    local entry tmp_line found=0

    entry="$(exact_exception_entry_for_path "$p")"

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
        echo -e "${CYAN}EXACT EXCEPTION ADDED:${RESET} $entry ${CYAN}->${RESET} $EXCLUDE_FILTERS_FILE"
    else
        echo -e "${YELLOW}EXACT EXCEPTION EXISTS:${RESET} $entry ${CYAN}->${RESET} $EXCLUDE_FILTERS_FILE"
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
declare -A DB_CACHE_HASH_MD5=()
declare -A DB_CACHE_HASH_SHA512=()
declare -A DB_CACHE_ROW_EXISTS=()
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

db_run_maintenance() {
    local mode="$1"

    (( USE_DB == 1 )) || return 0
    case "$mode" in
        auto|full) ;;
        *) return 0 ;;
    esac

    if [[ "$mode" == "auto" ]]; then
        startup_progress "SQLite maintenance: running AUTO profile..."
        (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: PRAGMA optimize;" >&2
        (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: PRAGMA wal_checkpoint(PASSIVE);" >&2
        sqlite3 "$DB_FILE" >/dev/null 2>&1 <<'SQL'
PRAGMA optimize;
PRAGMA wal_checkpoint(PASSIVE);
SQL
        db_prune_missing_paths
        startup_progress "SQLite maintenance: AUTO profile finished"
        return 0
    fi

    startup_progress "SQLite maintenance: running FULL profile..."
    (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: PRAGMA optimize;" >&2
    (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: ANALYZE;" >&2
    (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: REINDEX checked_paths;" >&2
    (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: PRAGMA wal_checkpoint(TRUNCATE);" >&2
    sqlite3 "$DB_FILE" >/dev/null 2>&1 <<'SQL'
PRAGMA optimize;
ANALYZE;
REINDEX checked_paths;
PRAGMA wal_checkpoint(TRUNCATE);
SQL
    db_prune_missing_paths
    startup_progress "SQLite maintenance: FULL profile finished"
}

db_prune_missing_paths() {
    local path escaped_path
    local total_db_rows=0
    local progress_pct=0
    local next_progress_pct=5
    local next_progress_count=500
    local delete_total=0
    local delete_processed=0
    local delete_progress_pct=0
    local delete_next_progress_pct=5
    local delete_next_progress_count=500
    local delete_chunk_size=500
    local start_idx=0
    local end_idx=0
    local i=0
    local -a missing_paths=()

    DB_MAINT_ROWS_CHECKED=0
    DB_MAINT_ROWS_MISSING=0
    DB_MAINT_ROWS_REMOVED=0

    startup_progress "SQLite maintenance: checking DB paths against filesystem..."
    total_db_rows="$(sqlite3 "$DB_FILE" 'SELECT COUNT(*) FROM checked_paths;' 2>/dev/null || echo 0)"
    [[ "$total_db_rows" =~ ^[0-9]+$ ]] || total_db_rows=0

    if (( total_db_rows > 0 )); then
        startup_progress "SQLite maintenance: crosscheck progress 0% (0 / $total_db_rows checked, 0 missing)..."
    fi

    while IFS= read -r path; do
        [[ -n "$path" ]] || continue
        (( ++DB_MAINT_ROWS_CHECKED ))
        if [[ ! -e "$path" ]]; then
            (( ++DB_MAINT_ROWS_MISSING ))
            missing_paths+=("$path")
            print_db_maintenance_missing_verbose "$path"
        fi

        if (( total_db_rows > 0 )); then
            progress_pct=$(( DB_MAINT_ROWS_CHECKED * 100 / total_db_rows ))
            if (( DB_MAINT_ROWS_CHECKED >= next_progress_count )); then
                startup_progress "SQLite maintenance: crosscheck progress ${progress_pct}% ($DB_MAINT_ROWS_CHECKED / $total_db_rows checked, $DB_MAINT_ROWS_MISSING missing)..."
                next_progress_count=$((next_progress_count + 500))
            fi
            while (( progress_pct >= next_progress_pct )) && (( next_progress_pct <= 100 )); do
                startup_progress "SQLite maintenance: crosscheck progress ${next_progress_pct}% ($DB_MAINT_ROWS_CHECKED / $total_db_rows checked, $DB_MAINT_ROWS_MISSING missing)..."
                next_progress_pct=$((next_progress_pct + 5))
            done
        elif (( DB_MAINT_ROWS_CHECKED >= next_progress_count )); then
            startup_progress "SQLite maintenance: crosscheck progress ($DB_MAINT_ROWS_CHECKED checked, $DB_MAINT_ROWS_MISSING missing)..."
            next_progress_count=$((next_progress_count + 500))
        fi
    done < <(sqlite3 "$DB_FILE" 'SELECT path FROM checked_paths;')

    if (( DB_MAINT_ROWS_MISSING > 0 )); then
        (( VERBOSE == 1 )) && echo "[VERBOSE] SQLite maintenance command: delete rows for missing filesystem paths" >&2
        delete_total="${#missing_paths[@]}"
        startup_progress "SQLite maintenance: delete progress 0% (0 / $delete_total removed from DB)..."
        for (( start_idx=0; start_idx<delete_total; start_idx+=delete_chunk_size )); do
            end_idx=$((start_idx + delete_chunk_size))
            if (( end_idx > delete_total )); then
                end_idx=$delete_total
            fi

            {
                printf 'BEGIN IMMEDIATE;\n'
                for (( i=start_idx; i<end_idx; i++ )); do
                    path="${missing_paths[$i]}"
                    escaped_path="$(sql_escape "$path")"
                    printf "DELETE FROM checked_paths WHERE path='%s';\n" "$escaped_path"
                done
                printf 'COMMIT;\n'
            } | sqlite3 "$DB_FILE" >/dev/null 2>&1

            delete_processed=$end_idx
            delete_progress_pct=$(( delete_processed * 100 / delete_total ))
            if (( delete_processed >= delete_next_progress_count )); then
                startup_progress "SQLite maintenance: delete progress ${delete_progress_pct}% ($delete_processed / $delete_total removed from DB)..."
                delete_next_progress_count=$((delete_next_progress_count + 500))
            fi
            while (( delete_progress_pct >= delete_next_progress_pct )) && (( delete_next_progress_pct <= 100 )); do
                startup_progress "SQLite maintenance: delete progress ${delete_next_progress_pct}% ($delete_processed / $delete_total removed from DB)..."
                delete_next_progress_pct=$((delete_next_progress_pct + 5))
            done
        done
        DB_MAINT_ROWS_REMOVED="$delete_processed"
    fi

    startup_progress "SQLite maintenance: filesystem check finished (checked: $DB_MAINT_ROWS_CHECKED, missing: $DB_MAINT_ROWS_MISSING, removed: $DB_MAINT_ROWS_REMOVED)"
}

print_db_maintenance_missing_verbose() {
    (( VERBOSE == 1 )) || return 0
    local path="$1"
    local line="[VERBOSE] SQLite maintenance: DB entry exists for '$path' but file is missing in filesystem; removing row from DB."

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] SQLite maintenance: DB entry exists for '$path'" >&2
        echo "          but file is missing in filesystem; removing row from DB." >&2
    fi
}

db_init() {
    local warmed_rows=0
    local md5_hash sha512_hash file_hash_kind file_hash

    db_migrate_legacy_file()
    (( USE_DB == 1 )) || return 0
    startup_progress "Preparing SQLite cache: $DB_FILE"
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
    sqlite3 "$DB_FILE" 'ALTER TABLE checked_paths ADD COLUMN file_hash_kind TEXT;' >/dev/null 2>&1 || true
    sqlite3 "$DB_FILE" 'ALTER TABLE checked_paths ADD COLUMN file_hash TEXT;' >/dev/null 2>&1 || true
    sqlite3 "$DB_FILE" 'ALTER TABLE checked_paths ADD COLUMN file_md5 TEXT;' >/dev/null 2>&1 || true
    sqlite3 "$DB_FILE" 'ALTER TABLE checked_paths ADD COLUMN file_sha512 TEXT;' >/dev/null 2>&1 || true
    sqlite3 "$DB_FILE" 'CREATE INDEX IF NOT EXISTS idx_checked_paths_signature ON checked_paths(signature);' >/dev/null 2>&1 || true
    sqlite3 "$DB_FILE" 'CREATE INDEX IF NOT EXISTS idx_checked_paths_file_hash ON checked_paths(file_hash_kind, file_hash);' >/dev/null 2>&1 || true
    sqlite3 "$DB_FILE" 'CREATE INDEX IF NOT EXISTS idx_checked_paths_file_md5 ON checked_paths(file_md5);' >/dev/null 2>&1 || true
    sqlite3 "$DB_FILE" 'CREATE INDEX IF NOT EXISTS idx_checked_paths_file_sha512 ON checked_paths(file_sha512);' >/dev/null 2>&1 || true
    DB_PENDING_SQL_FILE="$(mktemp)"

    local total_cached_rows=0
    local progress_pct=0
    local next_progress_pct=10

    total_cached_rows="$(sqlite3 "$DB_FILE" 'SELECT COUNT(*) FROM checked_paths;' 2>/dev/null || echo 0)"
    [[ "$total_cached_rows" =~ ^[0-9]+$ ]] || total_cached_rows=0

    if (( total_cached_rows > 0 )); then
        startup_progress "Loading cached rows from SQLite into memory: 0% (0 / $total_cached_rows rows loaded)..."
    else
        startup_progress "Loading cached rows from SQLite into memory..."
    fi

    while IFS='|' read -r path size mtime status signature md5_hash sha512_hash file_hash_kind file_hash; do
        [[ -n "$path" ]] || continue
        DB_CACHE_META["$path"]="$size|$mtime"
        DB_CACHE_STATUS["$path"]="$status"
        DB_CACHE_ROW_EXISTS["$path"]=1
        if [[ -n "$signature" ]]; then
            DB_CACHE_SIG["$signature"]=1
            DB_CACHE_SIG_STATUS["$signature"]="$status"
        fi
        if [[ -z "$md5_hash" && "$file_hash_kind" == "md5" ]]; then
            md5_hash="$file_hash"
        fi
        if [[ -z "$sha512_hash" && "$file_hash_kind" == "sha512" ]]; then
            sha512_hash="$file_hash"
        fi
        if [[ -n "$md5_hash" ]]; then
            DB_CACHE_HASH_MD5["$path"]="$md5_hash"
        fi
        if [[ -n "$sha512_hash" ]]; then
            DB_CACHE_HASH_SHA512["$path"]="$sha512_hash"
        fi
        ((++warmed_rows))
        if (( total_cached_rows > 0 )); then
            progress_pct=$(( warmed_rows * 100 / total_cached_rows ))
            while (( next_progress_pct <= 100 && progress_pct >= next_progress_pct )); do
                startup_progress "SQLite warmup progress: ${next_progress_pct}% ($warmed_rows / $total_cached_rows rows loaded)..."
                (( next_progress_pct += 10 ))
            done
        elif (( warmed_rows % 50000 == 0 )); then
            startup_progress "SQLite warmup progress: $warmed_rows rows loaded..."
        fi
    done < <(sqlite3 -separator '|' "$DB_FILE" 'SELECT path, size, mtime, COALESCE(status, ""), COALESCE(signature, ""), COALESCE(file_md5, ""), COALESCE(file_sha512, ""), COALESCE(file_hash_kind, ""), COALESCE(file_hash, "") FROM checked_paths;')

    if (( total_cached_rows > 0 )); then
        startup_progress "SQLite cache warmup done: 100% ($warmed_rows / $total_cached_rows rows loaded)"
    else
        startup_progress "SQLite cache warmup done: $warmed_rows rows loaded"
    fi
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

db_record_file_hash() {
    local path="$1"
    local hash_kind="$2"
    local hash_value="$3"
    local abs sql specific_sql existing_hash="" write_hash_record=1 confirm_rc=0

    (( USE_DB == 1 )) || return 0
    [[ -e "$path" && -n "$hash_kind" && -n "$hash_value" ]] || return 0

    abs="$(db_abs_path "$path" 2>/dev/null || true)"
    [[ -n "$abs" ]] || return 0

    case "$hash_kind" in
        md5) existing_hash="${DB_CACHE_HASH_MD5[$abs]-}" ;;
        sha512) existing_hash="${DB_CACHE_HASH_SHA512[$abs]-}" ;;
        *) existing_hash="" ;;
    esac

    if [[ -n "${DB_CACHE_ROW_EXISTS[$abs]-}" ]]; then
        if [[ -z "$existing_hash" ]]; then
            DB_HASH_RECORD_STATUS="added_missing"
        elif [[ "$existing_hash" == "$hash_value" ]]; then
            DB_HASH_RECORD_STATUS="unchanged"
        else
            confirm_db_hash_update_for_existing_entry "$path" "$hash_kind" "$existing_hash" "$hash_value"
            confirm_rc=$?
            case "$confirm_rc" in
                0)
                    DB_HASH_RECORD_STATUS="updated"
                    ;;
                1)
                    DB_HASH_RECORD_STATUS="kept_existing"
                    write_hash_record=0
                    ;;
                2)
                    echo "Quitting."
                    exit 0
                    ;;
            esac
        fi
    else
        DB_HASH_RECORD_STATUS="new"
    fi
    if (( write_hash_record == 1 )); then
        if [[ -n "${DB_CACHE_ROW_EXISTS[$abs]-}" ]]; then
            ((++DB_ROWS_UPDATED))
        else
            ((++DB_ROWS_NEW))
        fi
        ((++DB_HASHES_ADDED))
    fi

    case "$hash_kind" in
        md5) specific_sql="file_md5='$(sql_escape "$hash_value")'" ;;
        sha512) specific_sql="file_sha512='$(sql_escape "$hash_value")'" ;;
        *) specific_sql="" ;;
    esac

    if (( write_hash_record == 1 )); then
        sql="INSERT INTO checked_paths(path, kind, size, mtime, status, last_checked, file_hash_kind, file_hash, file_md5, file_sha512) VALUES ('$(sql_escape "$abs")', 'file_hash_only', 0, 0, 'hashed', CURRENT_TIMESTAMP, '$(sql_escape "$hash_kind")', '$(sql_escape "$hash_value")', $( [[ "$hash_kind" == "md5" ]] && printf "'%s'" "$(sql_escape "$hash_value")" || printf "NULL" ), $( [[ "$hash_kind" == "sha512" ]] && printf "'%s'" "$(sql_escape "$hash_value")" || printf "NULL" )) ON CONFLICT(path) DO UPDATE SET file_hash_kind=excluded.file_hash_kind, file_hash=excluded.file_hash, last_checked=CURRENT_TIMESTAMP${specific_sql:+, $specific_sql};"
        printf '%s\n' "$sql" >> "$DB_PENDING_SQL_FILE"
        DB_CACHE_ROW_EXISTS["$abs"]=1
        if [[ "$hash_kind" == "md5" ]]; then
            DB_CACHE_HASH_MD5["$abs"]="$hash_value"
        elif [[ "$hash_kind" == "sha512" ]]; then
            DB_CACHE_HASH_SHA512["$abs"]="$hash_value"
        fi
        (( ++DB_PENDING_COUNT ))
        if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
            db_flush_pending
        fi
    fi

    print_db_hash_record_verbose "$path" "$hash_kind" "$DB_HASH_RECORD_STATUS"
}

db_find_path_by_file_hash_in_subtree() {
    local search_root="$1"
    local hash_kind="$2"
    local hash_value="$3"
    local search_abs row_path query

    (( USE_DB == 1 )) || return 1
    db_flush_pending >/dev/null 2>&1 || true

    search_abs="$(db_abs_path "$search_root" 2>/dev/null || true)"
    [[ -n "$search_abs" ]] || return 1

    case "$hash_kind" in
        md5) query="SELECT path FROM checked_paths WHERE ((file_md5='$(sql_escape "$hash_value")') OR (file_hash_kind='md5' AND file_hash='$(sql_escape "$hash_value")')) AND path LIKE '$(sql_escape "${search_abs%/}")/%' ORDER BY LENGTH(path) LIMIT 1;" ;;
        sha512) query="SELECT path FROM checked_paths WHERE ((file_sha512='$(sql_escape "$hash_value")') OR (file_hash_kind='sha512' AND file_hash='$(sql_escape "$hash_value")')) AND path LIKE '$(sql_escape "${search_abs%/}")/%' ORDER BY LENGTH(path) LIMIT 1;" ;;
        *) return 1 ;;
    esac

    row_path="$(sqlite3 -separator $'\t' "$DB_FILE" "$query" 2>/dev/null | head -n 1)"
    if [[ -n "$row_path" ]]; then
        if [[ -e "$row_path" ]]; then
            ((++DB_HASH_LOOKUP_HITS))
            print_db_hash_lookup_verbose "hit" "$search_root" "$hash_kind" "$hash_value" "$row_path"
            printf '%s' "$row_path"
            return 0
        fi

        printf "DELETE FROM checked_paths WHERE path='%s';\n" "$(sql_escape "$row_path")" >> "$DB_PENDING_SQL_FILE"
        unset 'DB_CACHE_META[$row_path]'
        unset 'DB_CACHE_STATUS[$row_path]'
        unset 'DB_CACHE_HASH_MD5[$row_path]'
        unset 'DB_CACHE_HASH_SHA512[$row_path]'
        unset 'DB_CACHE_ROW_EXISTS[$row_path]'
        (( ++DB_PENDING_COUNT ))
        (( ++DB_ROWS_REMOVED ))
        (( ++DB_STALE_ROWS_REMOVED ))
        if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
            db_flush_pending
        fi
    fi

    ((++DB_HASH_LOOKUP_MISSES))
    print_db_hash_lookup_verbose "miss" "$search_root" "$hash_kind" "$hash_value"
    return 1
}

db_get_cached_file_hash() {
    local path="$1"
    local hash_kind="$2"
    local abs cached

    (( USE_DB == 1 )) || return 1
    (( FORCE_RECHECK == 0 )) || return 1
    [[ -e "$path" ]] || return 1

    abs="$(db_abs_path "$path" 2>/dev/null || true)"
    [[ -n "$abs" ]] || return 1

    [[ -n "${DB_CACHE_ROW_EXISTS[$abs]-}" ]] || return 1

    case "$hash_kind" in
        md5) cached="${DB_CACHE_HASH_MD5[$abs]-}" ;;
        sha512) cached="${DB_CACHE_HASH_SHA512[$abs]-}" ;;
        *) cached="" ;;
    esac
    [[ -n "$cached" ]] || return 1

    printf '%s' "$cached"
}


db_backfill_missing_hashes_for_existing_file() {
    local path="$1"
    local abs md5_hash sha512_hash sql

    (( USE_DB == 1 )) || return 0
    [[ -f "$path" ]] || return 0
    is_checksum_file "$path" && return 0

    abs="$(db_abs_path "$path" 2>/dev/null || true)"
    [[ -n "$abs" ]] || return 0

    [[ -n "${DB_CACHE_ROW_EXISTS[$abs]-}" ]] || return 0
    md5_hash="${DB_CACHE_HASH_MD5[$abs]-}"
    sha512_hash="${DB_CACHE_HASH_SHA512[$abs]-}"

    # Performance rule: when a file is skipped because the DB entry is already
    # valid, do not recompute hashes if at least one cached hash is already
    # present. Only backfill when both hashes are missing.
    if [[ -n "$md5_hash" || -n "$sha512_hash" ]]; then
        return 0
    fi

    md5_hash="$(md5_of_file "$path")"
    sha512_hash="$(checksum_of_file sha512 "$path")"
    DB_CACHE_HASH_MD5["$abs"]="$md5_hash"
    DB_CACHE_HASH_SHA512["$abs"]="$sha512_hash"

    sql="UPDATE checked_paths SET file_md5='$(sql_escape "$md5_hash")', file_sha512='$(sql_escape "$sha512_hash")', last_checked=CURRENT_TIMESTAMP WHERE path='$(sql_escape "$abs")';"
    printf '%s
' "$sql" >> "$DB_PENDING_SQL_FILE"
    (( ++DB_PENDING_COUNT ))
    (( ++DB_ROWS_UPDATED ))
    if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
        db_flush_pending
    fi
}


db_mark_checked() {
    local path="$1"
    local kind="$2"
    local status="$3"
    local abs meta size mtime sig sql sig_sql existing_row=0

    (( USE_DB == 1 )) || return 0
    [[ -e "$path" ]] || return 0

    meta="$(db_get_size_mtime "$path" 2>/dev/null || true)"
    [[ -n "$meta" ]] || return 0
    abs="$(db_abs_path "$path")"
    size="${meta%%|*}"
    mtime="${meta##*|}"
    sig=""

    if [[ -n "${DB_CACHE_ROW_EXISTS[$abs]-}" || -n "${DB_CACHE_META[$abs]-}" || -n "${DB_CACHE_STATUS[$abs]-}" ]]; then
        existing_row=1
    fi

    if is_checksum_file "$path"; then
        sig="$(db_compute_signature "$path" 2>/dev/null || true)"
        if [[ -n "$sig" ]]; then
            DB_CACHE_SIG["$sig"]=1
            DB_CACHE_SIG_STATUS["$sig"]="$status"
        fi
    fi

    DB_CACHE_META["$abs"]="$size|$mtime"
    DB_CACHE_STATUS["$abs"]="$status"
    DB_CACHE_ROW_EXISTS["$abs"]=1

    if (( existing_row == 1 )); then
        ((++DB_ROWS_UPDATED))
    else
        ((++DB_ROWS_NEW))
    fi

    if [[ -n "$sig" ]]; then
        sig_sql="'$(sql_escape "$sig")'"
    else
        sig_sql="NULL"
    fi

    sql="INSERT INTO checked_paths(path, kind, size, mtime, status, last_checked, signature) VALUES ('$(sql_escape "$abs")', '$(sql_escape "$kind")', $size, $mtime, '$(sql_escape "$status")', CURRENT_TIMESTAMP, $sig_sql) ON CONFLICT(path) DO UPDATE SET kind=excluded.kind, size=excluded.size, mtime=excluded.mtime, status=excluded.status, signature=excluded.signature, last_checked=CURRENT_TIMESTAMP, file_hash_kind=COALESCE(file_hash_kind, excluded.file_hash_kind), file_hash=COALESCE(file_hash, excluded.file_hash);"
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
        if [[ -n "${DB_CACHE_STATUS[$old_db_path]-}" ]]; then
            DB_CACHE_STATUS["$new_db_path"]="${DB_CACHE_STATUS[$old_db_path]}"
            unset 'DB_CACHE_STATUS[$old_db_path]'
        fi
        if [[ -n "${DB_CACHE_HASH_MD5[$old_db_path]-}" ]]; then
            DB_CACHE_HASH_MD5["$new_db_path"]="${DB_CACHE_HASH_MD5[$old_db_path]}"
            unset 'DB_CACHE_HASH_MD5[$old_db_path]'
        fi
        if [[ -n "${DB_CACHE_HASH_SHA512[$old_db_path]-}" ]]; then
            DB_CACHE_HASH_SHA512["$new_db_path"]="${DB_CACHE_HASH_SHA512[$old_db_path]}"
            unset 'DB_CACHE_HASH_SHA512[$old_db_path]'
        fi
        if [[ -n "${DB_CACHE_ROW_EXISTS[$old_db_path]-}" ]]; then
            DB_CACHE_ROW_EXISTS["$new_db_path"]=1
            unset 'DB_CACHE_ROW_EXISTS[$old_db_path]'
        fi

        ((++DB_ROWS_NEW))
        ((++DB_ROWS_REMOVED))

        sql="INSERT INTO checked_paths(path, kind, size, mtime, status, last_checked, signature) SELECT '$(sql_escape "$new_db_path")', kind, size, mtime, status, last_checked, signature FROM checked_paths WHERE path='$(sql_escape "$old_db_path")' ON CONFLICT(path) DO UPDATE SET kind=excluded.kind, size=excluded.size, mtime=excluded.mtime, status=excluded.status, signature=excluded.signature, last_checked=excluded.last_checked; DELETE FROM checked_paths WHERE path='$(sql_escape "$old_db_path")';"
        printf '%s\n' "$sql" >> "$DB_PENDING_SQL_FILE"
        (( ++DB_PENDING_COUNT ))
        if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
            db_flush_pending
        fi
    done
}

db_rewrite_single_path() {
    local old_path="$1"
    local new_path="$2"
    local old_abs new_abs sql

    (( USE_DB == 1 )) || return 0

    old_abs="$(db_abs_path "$old_path" 2>/dev/null || true)"
    new_abs="$(db_abs_path "$new_path" 2>/dev/null || true)"
    [[ -n "$old_abs" && -n "$new_abs" ]] || return 0

    sql="UPDATE checked_paths SET path='$(sql_escape "$new_abs")', last_checked=CURRENT_TIMESTAMP WHERE path='$(sql_escape "$old_abs")';"
    printf '%s\n' "$sql" >> "$DB_PENDING_SQL_FILE"
    (( ++DB_PENDING_COUNT ))
    if (( DB_PENDING_COUNT >= DB_FLUSH_EVERY )); then
        db_flush_pending
    fi

    # Best-effort cache move for already loaded metadata/status
    if [[ -n "${DB_CACHE_META[$old_abs]-}" ]]; then
        DB_CACHE_META["$new_abs"]="${DB_CACHE_META[$old_abs]}"
        unset 'DB_CACHE_META[$old_abs]'
        ((++DB_ROWS_UPDATED))
    fi
    if [[ -n "${DB_CACHE_STATUS[$old_abs]-}" ]]; then
        DB_CACHE_STATUS["$new_abs"]="${DB_CACHE_STATUS[$old_abs]}"
        unset 'DB_CACHE_STATUS[$old_abs]'
    fi
    if [[ -n "${DB_CACHE_HASH_MD5[$old_abs]-}" ]]; then
        DB_CACHE_HASH_MD5["$new_abs"]="${DB_CACHE_HASH_MD5[$old_abs]}"
        unset 'DB_CACHE_HASH_MD5[$old_abs]'
    fi
    if [[ -n "${DB_CACHE_HASH_SHA512[$old_abs]-}" ]]; then
        DB_CACHE_HASH_SHA512["$new_abs"]="${DB_CACHE_HASH_SHA512[$old_abs]}"
        unset 'DB_CACHE_HASH_SHA512[$old_abs]'
    fi
    if [[ -n "${DB_CACHE_ROW_EXISTS[$old_abs]-}" ]]; then
        DB_CACHE_ROW_EXISTS["$new_abs"]=1
        unset 'DB_CACHE_ROW_EXISTS[$old_abs]'
    fi
}

db_mark_renamed_path_checked() {
    local path="$1"
    local kind="$2"
    (( USE_DB == 1 )) || return 0
    [[ -e "$path" ]] || return 0
    db_mark_checked "$path" "$kind" "checked"
}
while (( $# > 0 )); do
    #region agent log
    debug_log "H4" "rename.sh:arg_parse" "Parsing CLI argument token" "{\"token\":\"$1\",\"remaining\":$#}"
    #endregion
    case "$1" in
        --version)
            echo "rename.sh"
            echo "version: $SCRIPT_VERSION"
            echo "db file (if used): $DB_FILE"
            echo "exclude file: $EXCLUDE_FILTERS_FILE"
            echo "prompt wait: $(print_prompt_wait_description)"
            echo
            usage
            exit 0
            ;;
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
        --run-db-maintenance)
            RUN_DB_MAINTENANCE=1
            USE_DB=1
            shift
            ;;
        --db-maintenance)
            [[ $# -ge 2 ]] || { echo "Missing value for --db-maintenance" >&2; usage >&2; exit 1; }
            case "$2" in
                auto|full) CLI_DB_MAINTENANCE="$2" ;;
                *) echo "Invalid value for --db-maintenance: $2 (use auto or full)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
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
                *) echo "Invalid value for --mode: $2 (use real or dry-run)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --scope)
            [[ $# -ge 2 ]] || { echo "Missing value for --scope" >&2; usage >&2; exit 1; }
            case "$2" in
                current|subdirs) CLI_SCOPE="$2" ;;
                *) echo "Invalid value for --scope: $2 (use subdirs or current)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --resume-state)
            [[ $# -ge 2 ]] || { echo "Missing value for --resume-state" >&2; usage >&2; exit 1; }
            case "$2" in
                fresh|ask|resume) CLI_RESUME_STATE="$2" ;;
                *) echo "Invalid value for --resume-state: $2 (use fresh, ask, or resume)" >&2; usage >&2; exit 1 ;;
            esac
            shift 2
            ;;
        --wait-seconds)
            [[ $# -ge 2 ]] || { echo "Missing value for --wait-seconds" >&2; usage >&2; exit 1; }
            [[ "$2" =~ ^[0-9]+$ ]] || { echo "Invalid value for --wait-seconds: $2 (use 0 or a positive integer)" >&2; usage >&2; exit 1; }
            PROMPT_WAIT_SECONDS="$2"
            shift 2
            ;;
        -h|--help)
            #region agent log
            debug_log "H2" "rename.sh:arg_parse_help" "Help option selected; will print banner and usage" "{\"token\":\"$1\"}"
            #endregion
            print_startup_banner
            echo
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

if (( RUN_DB_MAINTENANCE == 0 )); then
    prompt_resume_choice_early
fi

print_startup_banner
startup_progress "Scanning startup directory: $START_DIR"
startup_progress "Loading exclude filters from: $EXCLUDE_FILTERS_FILE"
load_exclude_filters
startup_progress "Exclude filters loaded: ${#EXCLUDE_FILTERS[@]}"
if (( USE_DB == 1 )); then
    if (( RUN_DB_MAINTENANCE == 1 )); then
        startup_progress "Preparing SQLite maintenance support..."
        db_require_sqlite
        db_migrate_legacy_file
        if [[ ! -f "$DB_FILE" ]]; then
            echo "SQLite maintenance skipped: DB file not found: $DB_FILE"
            exit 0
        fi
        startup_progress "Running manual SQLite maintenance profile: $CLI_DB_MAINTENANCE"
        db_run_maintenance "$CLI_DB_MAINTENANCE"
        echo "SQLite maintenance filesystem check:"
        echo "  DB rows checked: $DB_MAINT_ROWS_CHECKED"
        echo "  DB rows missing in filesystem: $DB_MAINT_ROWS_MISSING"
        echo "  DB rows removed from DB: $DB_MAINT_ROWS_REMOVED"
        echo "SQLite maintenance finished: $DB_FILE"
        exit 0
    fi

    startup_progress "Initializing SQLite support..."
    db_init
fi
startup_progress "Startup preparation finished"
startup_progress "Interactive prompt wait: $(print_prompt_wait_description)"


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
    case "$CLI_DB_MAINTENANCE" in
        auto) echo "SQLite maintenance profile: AUTO (optimize/checkpoint) [manual with --run-db-maintenance]" ;;
        full) echo "SQLite maintenance profile: FULL (optimize + analyze + reindex + WAL truncate) [manual with --run-db-maintenance]" ;;
    esac
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
    verbose_question_timestamp "Use colors?"
    echo "Use colors?"
    echo "  [Y] Yes (default)"
    echo "  [N] No"
    echo "  [Q] Quit"
    echo -n "Choice [Y/n/q]: "

    flush_stdin
    read_single_key input "$PROMPT_WAIT_SECONDS"
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

print_verbose_options_box() {
    (( VERBOSE == 1 )) || return 0

    local -a lines=()
    local box_width=0
    local line db_mode scope_text color_text prompt_text db_maintenance_text

    if (( USE_DB == 1 )); then
        if (( FAST_DB == 1 )); then
            db_mode="enabled, FAST - trust cached paths without current size/mtime checks"
        else
            db_mode="enabled, SAFE - require cached path, size, and mtime to still match"
        fi
        if (( FORCE_RECHECK == 1 )); then
            db_mode="${db_mode}; force recheck active"
        fi
        case "$CLI_DB_MAINTENANCE" in
            auto) db_maintenance_text="auto - lightweight optimize/checkpoint profile for --run-db-maintenance" ;;
            full) db_maintenance_text="full - optimize + analyze + reindex + WAL truncate profile for --run-db-maintenance" ;;
            *)    db_maintenance_text="$CLI_DB_MAINTENANCE" ;;
        esac
    else
        db_mode="disabled - always inspect files directly"
        db_maintenance_text="$CLI_DB_MAINTENANCE (available when --use-db is enabled)"
    fi

    if [[ "$use_colors" == "yes" ]]; then
        color_text="yes - colored output is enabled"
    else
        color_text="no - plain output without ANSI colors"
    fi

    if [[ "$process_scope" == "subdirs" ]]; then
        scope_text="subdirs - process the current directory and all subdirectories"
    else
        scope_text="current - process only the current directory"
    fi

    if (( PROMPT_WAIT_SECONDS == 0 )); then
        prompt_text="0 - wait forever for each interactive answer"
    else
        prompt_text="${PROMPT_WAIT_SECONDS} - timeout for each interactive answer in seconds"
    fi

    lines+=("Verbose        : on - print extra diagnostic information")
    lines+=("Colors         : ${color_text}")
    lines+=("Mode           : ${mode} - $( [[ "$mode" == "real" ]] && printf '%s' 'perform interactive real renames' || printf '%s' 'show planned changes only' )")
    lines+=("Scope          : ${scope_text}")
    lines+=("SQLite cache   : ${db_mode}")
    lines+=("DB maintenance : ${db_maintenance_text}")
    lines+=("Resume state   : ${CLI_RESUME_STATE} - checkpoint behavior after Ctrl-C")
    lines+=("Prompt wait    : ${prompt_text}")
    lines+=("Start dir      : ${START_DIR} - root path used for this run")
    lines+=("Exclude file   : ${EXCLUDE_FILTERS_FILE} - local exception/filter definitions")

    for line in "${lines[@]}"; do
        (( ${#line} > box_width )) && box_width=${#line}
    done

    printf '┌%*s┐\n' $((box_width + 2)) '' | tr ' ' '─'
    printf '│ %-*s │\n' "$box_width" "Effective options (verbose mode)"
    printf '├%*s┤\n' $((box_width + 2)) '' | tr ' ' '─'
    for line in "${lines[@]}"; do
        printf '│ %-*s │\n' "$box_width" "$line"
    done
    printf '└%*s┘\n' $((box_width + 2)) '' | tr ' ' '─'
}

print_wrapped_two_path_verbose() {
    (( VERBOSE == 1 )) || return 0
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

print_single_target_check_verbose() {
    (( VERBOSE == 1 )) || return 0
    local tool_name="$1"
    local sum_dir="$2"
    local target_ref="$3"
    local sum_base="$4"

    local line1="Running single-target ${tool_name} check in directory '${sum_dir}'"
    local line2="          for ref '${target_ref}' from file '${sum_base}'"

    if (( ${#line1} + 11 <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    else
        echo "[VERBOSE] ${line1}" >&2
        echo "          for ref '${target_ref}'" >&2
        echo "          from file '${sum_base}'" >&2
    fi
}

print_resolved_ref_verbose() {
    (( VERBOSE == 1 )) || return 0
    local ref="$1"
    local resolved="$2"

    local line="[VERBOSE] Resolved ref '${ref}' -> '${resolved}'"
    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] Resolved ref '${ref}'" >&2
        echo "          -> '${resolved}'" >&2
    fi
}

print_checksum_update_verbose() {
    (( VERBOSE == 1 )) || return 0

    if (( $# == 3 )); then
        local sum_file="$1"
        local old_name="$2"
        local new_name="$3"
        local line1="[VERBOSE] Updating checksum content in '${sum_file}': '${old_name}'"
        local line2="          -> '${new_name}'"

        if (( ${#line1} <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
            echo "$line1" >&2
            echo "$line2" >&2
        else
            echo "[VERBOSE] Updating checksum content in '${sum_file}':" >&2
            echo "          '${old_name}'" >&2
            echo "$line2" >&2
        fi
        return 0
    fi

    local first_part="$1"
    local second_part="$2"
    local line="[VERBOSE] ${first_part}${second_part}"

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] ${first_part}" >&2
        echo "          ${second_part}" >&2
    fi
}

print_checksum_file_rename_verbose() {
    (( VERBOSE == 1 )) || return 0
    local old_sum="$1"
    local new_sum="$2"
    local line="[VERBOSE] Renaming checksum file '${old_sum}' -> '${new_sum}'"

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] Renaming checksum file '${old_sum}'" >&2
        echo "          -> '${new_sum}'" >&2
    fi
}




print_protected_checksum_verbose() {
    (( VERBOSE == 1 )) || return 0
    local sum_file="$1"
    local line1="Protected checksum name starts with double underscores"
    local line2="          keeping checksum filename unchanged: '${sum_file}'"

    if (( ${#line1} + 11 <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    else
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    fi
}

print_checksum_no_action_verbose() {
    (( VERBOSE == 1 )) || return 0
    local sum_file="$1"
    local line1="All referenced files exist and no rename/update is needed"
    local line2="          for '${sum_file}' - skipping without checksum verification"

    if (( ${#line1} + 11 <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    else
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    fi
}

print_try_recover_missing_ref_verbose() {
    (( VERBOSE == 1 )) || return 0
    local missing_ref="$1"
    local expected_hash="$2"

    local line1="Trying to recover missing ref '${missing_ref}'"
    local line2="          (expected hash: ${expected_hash:-none})"

    if (( ${#line1} + 11 <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    else
        echo "[VERBOSE] ${line1}" >&2
        echo "${line2}" >&2
    fi
}

print_recovery_success_verbose() {
    (( VERBOSE == 1 )) || return 0
    local old_ref="$1"
    local found_ref="$2"
    local write_ref="$3"

    local line1="[VERBOSE] Recovery success: '${old_ref}' -> '${found_ref}'"
    local line2="          (write as '${write_ref}')"

    if (( ${#line1} <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "$line1" >&2
        echo "$line2" >&2
    else
        echo "$line1" >&2
        echo "$line2" >&2
    fi
}

print_scan_by_checksum_verbose() {
    (( VERBOSE == 1 )) || return 0
    local search_root="$1"
    local expected_hash="$2"

    local line1="[VERBOSE] Name-based subtree recovery failed under '${search_root}'"
    local line2="          scanning all files below by checksum (expected hash: ${expected_hash})"

    if (( ${#line1} <= MAX_LINE_LENGTH )) && (( ${#line2} <= MAX_LINE_LENGTH )); then
        echo "$line1" >&2
        echo "$line2" >&2
    else
        echo "$line1" >&2
        echo "$line2" >&2
    fi
}


print_recovery_final_status_verbose() {
    (( VERBOSE == 1 )) || return 0
    local missing_ref="$1"
    local status="$2"

    if [[ "$status" == "success" ]]; then
        echo "[VERBOSE] Recovery FINAL STATUS: SUCCESS for '${missing_ref}'" >&2
    else
        echo "[VERBOSE] Recovery FINAL STATUS: FAILED for '${missing_ref}'" >&2
    fi
}

print_db_hash_record_verbose() {
    (( VERBOSE == 1 )) || return 0
    local path="$1"
    local hash_kind="$2"
    local status="$3"

    case "$status" in
        new)
            echo "[VERBOSE] DB hash stored for NEW file entry: '${path}' (${hash_kind})" >&2
            ;;
        added_missing)
            echo "[VERBOSE] DB hash added for EXISTING file entry (missing before): '${path}' (${hash_kind})" >&2
            ;;
        unchanged)
            echo "[VERBOSE] DB hash verified for EXISTING file entry (already present): '${path}' (${hash_kind})" >&2
            ;;
        updated)
            echo "[VERBOSE] DB hash updated for EXISTING file entry: '${path}' (${hash_kind})" >&2
            ;;
        kept_existing)
            echo "[VERBOSE] DB hash kept for EXISTING file entry (user chose not to replace): '${path}' (${hash_kind})" >&2
            ;;
        *)
            echo "[VERBOSE] DB hash recorded for file entry: '${path}' (${hash_kind})" >&2
            ;;
    esac
}

print_db_hash_lookup_verbose() {
    (( VERBOSE == 1 )) || return 0
    local status="$1"
    local search_root="$2"
    local hash_kind="$3"
    local expected_hash="$4"
    local found_path="${5-}"

    if [[ "$status" == "hit" ]]; then
        echo "[VERBOSE] DB hash lookup HIT under '${search_root}' for ${hash_kind}=${expected_hash}" >&2
        echo "          matched path: '${found_path}'" >&2
    else
        echo "[VERBOSE] DB hash lookup MISS under '${search_root}' for ${hash_kind}=${expected_hash}" >&2
    fi
}


path_has_control_chars() {
    local s="$1"
    [[ "$s" == *$'\n'* || "$s" == *$'\r'* || "$s" == *$'\t'* ]] && return 0
    LC_ALL=C printf '%s' "$s" | grep -q '[[:cntrl:]]'
}

format_path_for_log() {
    local s="$1"
    s=${s//$'\\'/\\\\}
    s=${s//$'\n'/\\n}
    s=${s//$'\r'/\\r}
    s=${s//$'\t'/\\t}
    printf '%s' "$s"
}

sanitize_basename_control_chars() {
    local s="$1"
    printf '%s' "$s" | LC_ALL=C tr -d '\000-\037\177'
}

print_control_char_warning() {
    local path="$1"
    local shown
    shown="$(format_path_for_log "$path")"
    echo -e "${YELLOW}WARNING:${RESET} path contains control character(s): '$shown'"
}

print_skip_path_reason() {
    (( VERBOSE == 1 )) || return 0
    local path="$1"
    local reason="$2"
    local shown
    shown="$(format_path_for_log "$path")"
    local line="SKIP: '$shown' $reason"

    if path_has_control_chars "$path"; then
        print_control_char_warning "$path"
    fi

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo -e "${YELLOW}SKIP:${RESET} '$shown' $reason"
    else
        echo -e "${YELLOW}SKIP:${RESET} '$shown'"
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
    verbose_question_timestamp "Select mode:"
    echo "Select mode:"
    echo "  [D] Dry-run (default)"
    echo "  [R] Real rename (interactive)"
    echo "  [Q] Quit"
    echo -n "Choice [D/r/q]: "

    flush_stdin
    read_single_key input "$PROMPT_WAIT_SECONDS"
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
    verbose_question_timestamp "What should be processed?"
    echo "What should be processed?"
    echo "  [C] Current directory only (default)"
    echo "  [S] Also subdirectories"
    echo "  [Q] Quit"
    echo -n "Choice [C/s/q]: "

    flush_stdin
    read_single_key input "$PROMPT_WAIT_SECONDS"
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
print_verbose_options_box

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

is_media_file() {
    local p="$1"
    local lower="${p,,}"
    [[ "$lower" == *.mp3 || "$lower" == *.flac || "$lower" == *.wav || "$lower" == *.m4a || "$lower" == *.aac || "$lower" == *.ogg || "$lower" == *.wma || "$lower" == *.mp4 || "$lower" == *.mkv || "$lower" == *.avi || "$lower" == *.mov || "$lower" == *.wmv || "$lower" == *.mpeg || "$lower" == *.mpg || "$lower" == *.m4v || "$lower" == *.webm || "$lower" == *.ts ]]
}

is_m3u_file() {
    local p="$1"
    local lower="${p,,}"
    [[ "$lower" == *.m3u ]]
}

is_protected_par2_name() {
    local p="$1"
    local base lower
    base="$(basename -- "$p")"
    lower="${base,,}"
    [[ "$base" == _* && "$lower" == *.par2 ]]
}

path_to_exclude_entry() {
    exception_entry_for_path "$1"
}

is_internal_protected_path() {
    local p="$1"
    local abs start_abs

    [[ -n "$p" ]] || return 1

    abs="$(db_abs_path "$p" 2>/dev/null || true)"
    start_abs="$(db_abs_path "$START_DIR" 2>/dev/null || true)"

    [[ -n "$abs" && -n "$start_abs" ]] || return 1

    if [[ "$abs" == "$start_abs/_exclude-rename.sh.txt" ]]; then
        return 0
    fi
    if [[ "$abs" == "$start_abs/_rename.sh-optional-db.sqlite3" ]]; then
        return 0
    fi
    if [[ "$abs" == "$start_abs/rename.sh-optional-db.sqlite3" ]]; then
        return 0
    fi
    if [[ "$abs" == "$start_abs/_rename.sh-optional-db.sqlite3-wal" || "$abs" == "$start_abs/_rename.sh-optional-db.sqlite3-shm" ]]; then
        return 0
    fi
    if [[ "$abs" == "$start_abs/rename.sh-optional-db.sqlite3-wal" || "$abs" == "$start_abs/rename.sh-optional-db.sqlite3-shm" ]]; then
        return 0
    fi

    return 1
}

update_m3u_references_in_file() {
    local m3u_file="$1"
    local old_path="$2"
    local new_path="$3"
    local tmp old_base new_base old_norm new_norm old_base_norm new_base_norm

    [[ -f "$m3u_file" ]] || return 0
    old_base="$(basename -- "$old_path")"
    new_base="$(basename -- "$new_path")"
    old_norm="$(normalize_m3u_entry_for_compare "$old_path")"
    new_norm="$(normalize_m3u_entry_for_compare "$new_path")"
    old_base_norm="$(normalize_m3u_entry_for_compare "$old_base")"
    new_base_norm="$(normalize_m3u_entry_for_compare "$new_base")"

    if [[ "$old_norm" == "$new_norm" && "$old_base_norm" == "$new_base_norm" ]]; then
        return 1
    fi

    tmp="$(mktemp)"

    if python3 - "$m3u_file" "$tmp" "$old_path" "$new_path" "$old_base" "$new_base" <<'PY'
import sys

src, dst, old_path, new_path, old_base, new_base = sys.argv[1:]

with open(src, 'r', encoding='utf-8', errors='surrogateescape', newline='') as f:
    lines = f.readlines()

basename_change_needed = (old_base != new_base)

out = []
changed = False

for line in lines:
    nl = line
    if line.endswith('\r\n'):
        eol = '\r\n'
    elif line.endswith('\n'):
        eol = '\n'
    elif line.endswith('\r'):
        eol = '\r'
    else:
        eol = ''

    stripped = line.rstrip('\r\n')

    if stripped == old_path and old_path != new_path:
        nl = new_path + eol
        changed = True
    elif basename_change_needed and stripped == old_base:
        nl = new_base + eol
        changed = True

    out.append(nl)

with open(dst, 'w', encoding='utf-8', errors='surrogateescape', newline='') as f:
    f.writelines(out)

sys.exit(0 if changed else 3)
PY
    then
        rc=0
    else
        rc=$?
    fi
    if [[ $rc -eq 0 ]]; then
        mv -- "$tmp" "$m3u_file"
        echo -e "${CYAN}M3U UPDATED:${RESET} $m3u_file"
    else
        rm -f -- "$tmp"
    fi
}

update_all_m3u_files_for_rename() {
    local old_path="$1"
    local new_path="$2"
    local start="${START_DIR:-.}"
    while IFS= read -r -d '' m3u; do
        update_m3u_references_in_file "$m3u" "$old_path" "$new_path"
    done < <(find "$start" -type f -iname '*.m3u' -print0 2>/dev/null)
}

normalize_m3u_candidate_key() {
    local s="$1"
    python3 - "$s" <<'PY'
import os, re, sys

s = sys.argv[1]
s = s.replace('\\', '/')
s = os.path.basename(s).lower()
s = re.sub(r'\.[^.]+$', '', s)
s = s.replace('&', 'and')
quote_chars = "'`\"´’‘"
remove_chars = " _.,;:()[]{}+-!\t\r\n" + quote_chars
translate_map = {ord(ch): None for ch in remove_chars}
s = s.translate(translate_map)

sys.stdout.buffer.write(s.encode('utf-8', 'surrogateescape'))
PY
}


find_best_m3u_subtree_match() {
    local m3u_file="$1"
    local missing_entry="$2"
    local playlist_dir candidate wanted_key candidate_key best=""
    playlist_dir="$(dirname -- "$m3u_file")"
    wanted_key="$(normalize_m3u_candidate_key "$missing_entry")"
    [[ -n "$wanted_key" ]] || return 1

    while IFS= read -r -d '' candidate; do
        candidate_key="$(normalize_m3u_candidate_key "$candidate")"
        if [[ "$candidate_key" == "$wanted_key" ]]; then
            best="$candidate"
            break
        fi
        if [[ -z "$best" && -n "$candidate_key" && ( "$candidate_key" == *"$wanted_key"* || "$wanted_key" == *"$candidate_key"* ) ]]; then
            best="$candidate"
        fi
    done < <(find "$playlist_dir" -type f -print0 2>/dev/null)

    [[ -n "$best" ]] || return 1
    printf '%s' "$best"
}



normalize_m3u_entry_for_compare() {
    local s="$1"
    s="${s%$'
'}"
    s="${s%$'
'}"
    s="${s//\//}"
    while [[ "$s" == ./* ]]; do
        s="${s#./}"
    done
    printf '%s' "$s"
}

replace_single_m3u_entry() {
    local m3u_file="$1"
    local old_entry="$2"
    local new_entry="$3"
    local tmp rc m3u_dir

    old_entry="${old_entry%$'\r'}"
    old_entry="${old_entry%$'\n'}"
    new_entry="${new_entry%$'\r'}"
    new_entry="${new_entry%$'\n'}"

    m3u_dir="$(dirname -- "$m3u_file")"
    tmp="$(mktemp --tmpdir="$m3u_dir" .m3u-update.XXXXXX)"
    if python3 - "$m3u_file" "$tmp" "$old_entry" "$new_entry" <<'PY'
import sys

src, dst, old_entry, new_entry = sys.argv[1:]

old_entry = old_entry.rstrip('\r\n')
new_entry = new_entry.rstrip('\r\n')

def norm(value: str) -> str:
    value = value.rstrip('\r\n')
    value = value.replace('\\', '/')
    while value.startswith('./'):
        value = value[2:]
    return value

with open(src, 'r', encoding='utf-8', errors='surrogateescape', newline='') as f:
    lines = f.readlines()

old_norm = norm(old_entry)
new_norm = norm(new_entry)
out = []
changed = False

for line in lines:
    if line.endswith('\r\n'):
        nl = '\r\n'
    elif line.endswith('\n'):
        nl = '\n'
    elif line.endswith('\r'):
        nl = '\r'
    else:
        nl = ''

    stripped = line.rstrip('\r\n')
    stripped_norm = norm(stripped)

    exact_match = (stripped == old_entry)
    normalized_match = (stripped_norm == old_norm)

    if exact_match or normalized_match:
        if stripped == new_entry or stripped_norm == new_norm:
            out.append(line)
        else:
            out.append(new_entry + nl)
            changed = True
    else:
        out.append(line)

with open(dst, 'w', encoding='utf-8', errors='surrogateescape', newline='') as f:
    f.writelines(out)

sys.exit(0 if changed else 3)
PY
    then
        rc=0
    else
        rc=$?
    fi
    if [[ $rc -eq 0 ]]; then
        if mv -- "$tmp" "$m3u_file"; then
            return 0
        fi
        rm -f -- "$tmp"
        return 1
    fi
    rm -f -- "$tmp"
    if [[ $rc -eq 3 ]]; then
        return 3
    fi
    return 1
}

print_m3u_no_update_needed() {
    local m3u_file="$1"
    printf '%s\n' "M3U CHECK: no update needed: $m3u_file"
}

check_m3u_targets() {
    local m3u_file="$1"
    local dir line target found replacement display_entry rc
    dir="$(dirname -- "$m3u_file")"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" || "$line" == \#* ]] && continue
        display_entry="$line"
        if [[ "$line" = /* ]]; then
            target="$line"
        else
            target="$dir/${line//\//}"
        fi
        if [[ ! -e "$target" ]]; then
            found="$(find_best_m3u_subtree_match "$m3u_file" "$line" || true)"
            if [[ -n "$found" ]]; then
                replacement="${found#$dir/}"
                [[ "$replacement" == "$found" ]] && replacement="$(basename -- "$found")"

                if [[ "$(normalize_m3u_entry_for_compare "$replacement")" == "$(normalize_m3u_entry_for_compare "$line")" ]]; then
                    print_m3u_no_update_needed "$m3u_file"
                    continue
                fi

                if replace_single_m3u_entry "$m3u_file" "$line" "$replacement"; then
                    rc=0
                else
                    rc=$?
                fi
                if [[ $rc -eq 0 ]]; then
                    echo
                    printf '%s
' "OLD: $display_entry"
                    printf '%s
' "NEW: $replacement"
                    echo -e "${CYAN}M3U UPDATED:${RESET} $m3u_file"
                elif [[ $rc -eq 3 ]]; then
                    print_m3u_no_update_needed "$m3u_file"
                else
                    echo
                    printf '%s
' "OLD: $display_entry"
                    printf '%s
' "NEW: $replacement"
                    printf '%s
' "M3U SKIP: replacement was prepared but updating the playlist file failed."
                    printf '%s
' "  FILE:         $m3u_file"
                    printf '%s
' "  ENTRY:        $display_entry"
                    printf '%s
' "  REPLACEMENT:  $replacement"
                fi
            else
                printf '%s
' "M3U SKIP: no similar file was found in the playlist subtree."
                printf '%s
' "  FILE:         $m3u_file"
                printf '%s
' "  ENTRY:        $display_entry"
                printf '%s
' "  TARGET PATH:  $target"
            fi
        fi
    done < "$m3u_file"
}


check_all_m3u_files() {
    local start="${START_DIR:-.}"
    while IFS= read -r -d '' m3u; do
        check_m3u_targets "$m3u"
    done < <(find "$start" -type f -iname '*.m3u' -print0 2>/dev/null)
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

choose_r_acute_mapping_for_file() {
    local path="$1"
    local answer=""
    echo >&2
    echo "Filename contains ŕ:" >&2
    echo "  $path" >&2
    verbose_question_timestamp "Choose mapping for ŕ in this file:"
    echo "Choose mapping for ŕ in this file:" >&2
    echo "  [1] c (default)" >&2
    echo "  [2] s" >&2
    echo "  [3] c and space" >&2
    echo "  [4] s and space" >&2
    echo -n "Choice [1/2/3/4]: " >&2
    flush_stdin
    read_single_key answer "$PROMPT_WAIT_SECONDS"
    echo >&2
    case "$answer" in
        2) printf '%s' "s" ;;
        3) printf '%s' "c " ;;
        4) printf '%s' "s " ;;
        *) printf '%s' "c" ;;
    esac
}

choose_registered_mapping_for_file() {
    local path="$1"
    local answer=""
    echo >&2
    echo "Filename contains ®:" >&2
    echo "  $path" >&2
    verbose_question_timestamp "Choose mapping for ® in this file:"
    echo "Choose mapping for ® in this file:" >&2
    echo "  [1] z (default)" >&2
    echo "  [2] l" >&2
    echo -n "Choice [1/2]: " >&2
    flush_stdin
    read_single_key answer "$PROMPT_WAIT_SECONDS"
    echo >&2
    case "$answer" in
        2) printf '%s' "l" ;;
        *) printf '%s' "z" ;;
    esac
}

choose_at_sign_mapping_for_file() {
    local path="$1"
    local answer=""
    echo >&2
    echo "Filename contains @ (media file):" >&2
    echo "  $path" >&2
    verbose_question_timestamp "Choose mapping for @ in this file:"
    echo "Choose mapping for @ in this file:" >&2
    echo "  [1] a (default)" >&2
    echo "  [2] e" >&2
    echo -n "Choice [1/2]: " >&2
    flush_stdin
    read_single_key answer "$PROMPT_WAIT_SECONDS"
    echo >&2
    case "$answer" in
        2) printf '%s' "e" ;;
        *) printf '%s' "a" ;;
    esac
}

choose_r_grave_mapping_for_file() {
    local path="$1"
    local answer=""
    echo >&2
    echo "Filename contains Ŕ:" >&2
    echo "  $path" >&2
    verbose_question_timestamp "Choose mapping for Ŕ in this file:"
    echo "Choose mapping for Ŕ in this file:" >&2
    echo "  [1] c (default)" >&2
    echo "  [2] s" >&2
    echo -n "Choice [1/2]: " >&2
    flush_stdin
    read_single_key answer "$PROMPT_WAIT_SECONDS"
    echo >&2
    case "$answer" in
        2) printf '%s' "s" ;;
        *) printf '%s' "c" ;;
    esac
}

transform_basename() {
    local new="$1"
    local original_path="${2-}"
    local local_r_acute local_registered local_at_sign local_r_grave

    local_r_acute="${MAP_R_ACUTE:-c}"
    local_registered="${MAP_REGISTERED:-z}"
    local_at_sign="${MAP_AT_SIGN:-a}"
    local_r_grave="${MAP_R_GRAVE:-c}"

    if [[ -n "$original_path" && "$new" == *"ŕ"* ]]; then
        local_r_acute="$(choose_r_acute_mapping_for_file "$original_path")"
    fi
    if [[ -n "$original_path" && "$new" == *"®"* ]]; then
        local_registered="$(choose_registered_mapping_for_file "$original_path")"
    fi
    if [[ -n "$original_path" && "$new" == *"Ŕ"* ]]; then
        local_r_grave="$(choose_r_grave_mapping_for_file "$original_path")"
    fi
    if [[ -n "$original_path" && "$new" == *"@"* ]]; then
        if is_media_file "$original_path"; then
            local_at_sign="$(choose_at_sign_mapping_for_file "$original_path")"
        fi
    fi

    while [[ "$new" == '!'* ]]; do
        new="${new#!}"
    done

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
    new="${new//Å¼/z}"
    new="${new//ê/l}"
    new="${new//Ñ/a}"
    new="${new//¥/z}"
    new="${new//®/$local_registered}"
    new="${new//Ŕ/$local_r_grave}"
    new="${new//ŕ/$local_r_acute}"
    new="${new//ă/sc}"
    new="${new//si\`/sie_}"
    new="${new//si@/sie}"
    new="${new//Ä/s}"
    new="${new//€/c}"
    new="${new//%/ze}"
    if [[ -n "$original_path" ]]; then
        if is_media_file "$original_path"; then
            new="${new//@/$local_at_sign}"
        fi
    fi
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
    new="${new//ź/z}"
    new="${new//ż/z}"
    new="${new//Ą/A}"
    new="${new//Ć/C}"
    new="${new//Ę/E}"
    new="${new//Ł/L}"
    new="${new//Ń/N}"
    new="${new//Ó/O}"
    new="${new//Ś/S}"
    new="${new//Ź/Z}"
    new="${new//Ż/Z}"

    new="${new//•/-}"

    if [[ "$new" =~ \.jpeg$ ]]; then
        new="${new%.jpeg}.jpg"
    elif [[ "$new" =~ \.JPEG$ ]]; then
        new="${new%.JPEG}.jpg"
    fi

    new="${new//_OSiOLEK.com/}"
    new="${new//LEK.PL/}"
    new="${new//rip.by.Crisp/}"
    new="${new//._osloskop.net/}"
    new="${new//_eBook.PL/}"
    new="${new//eBook.PL/}"
    new="${new//_www.osiolek.com/}"
    new="${new//www.osiolek.com/}"
    new="${new//.WnA./.}"
    new="${new//_M_and_T_Books/}"
    new="${new//_Audiobook_PL/}"
    new="${new//\[Audiobook_PL\]/}"
    new="${new//\[Audiobook PL\]/}"
    new="${new//_audiobook_pl/}"
    new="${new//audiobook pl/}"
    new="${new//\[eksiążki PL\]/}"
    new="${new//\[eksiazki PL\]/}"
    new="${new//_eksiazki PL_/}"
    new="${new//_eksiazki_PL_/}"

    if [[ "$new" =~ ^([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})_-_(.+)(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[6]}"
        return
    fi

    if [[ "$new" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})_([0-9]{2})-([0-9]{2})-([0-9]{2})(.+)(\.[^.]+)$ ]]; then
        printf '%s%s%s_%s%s%s%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" \
            "${BASH_REMATCH[7]}" \
            "${BASH_REMATCH[8]}"
        return
    fi

    if [[ "$new" =~ ^([0-9]{8})-([0-9]{6})_-_(.+)(\.[^.]+)$ ]]; then
        printf '%s_%s_-_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" \
            "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}"
        return
    fi

    if [[ "$new" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-(.+)(\.[^.]+)$ ]]; then
        printf '%s%s%s_%s%s%s-%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" \
            "${BASH_REMATCH[7]}" \
            "${BASH_REMATCH[8]}"
        return
    fi

    if [[ "$new" =~ ^signal-([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{6})(\.[^.]+)$ ]]; then
        printf '%s%s%s_%s-signal%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}"
        return
    fi

    if [[ "$new" =~ ^signal-([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{6})_(.+)(\.[^.]+)$ ]]; then
        printf '%s%s%s_%s-signal-%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[6]}"
        return
    fi

    if [[ "$new" =~ ^signal-([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-(.+)(\.[^.]+)$ ]]; then
        printf '%s%s%s_%s%s%s-signal-%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" \
            "${BASH_REMATCH[7]}" \
            "${BASH_REMATCH[8]}"
        return
    fi

    if [[ "$new" =~ ^Screenshot_([0-9]{8}_[0-9]{6}_.+)(\.[^.]+)$ ]]; then
        printf '%s-screenshot%s' \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[2]}"
        return
    fi

    new=$(printf '%s' "$new" | sed -E '
        s/--+/-/g;
        s/  +/ /g;
        s/^ +//;
        s/ +$//;
        s/\.\.+/./g;
        s/__+/_/g;
        s/_\././g;
        s/_$//;
        s/\.$//;
    ')

    if [[ "$new" == *.* ]]; then
        local stem ext
        stem="${new%.*}"
        ext=".${new##*.}"
        stem=$(printf '%s' "$stem" | sed -E '
            s/[[:space:]]+/_/g;
            s/,+/_/g;
            s/;+/_/g;
            s/:+/_/g;
            s/\(+/_/g;
            s/\)+/_/g;
            s/\[+/_/g;
            s/\]+/_/g;
            s/\{+/_/g;
            s/\}+/_/g;
            s/"|'\''/_/g;
            s/_+/_/g;
            s/^_+//;
            s/_+$//;
        ')
        printf '%s%s' "$stem" "$ext"
    else
        printf '%s' "$(printf '%s' "$new" | sed -E '
            s/[[:space:]]+/_/g;
            s/,+/_/g;
            s/;+/_/g;
            s/:+/_/g;
            s/\(+/_/g;
            s/\)+/_/g;
            s/\[+/_/g;
            s/\]+/_/g;
            s/\{+/_/g;
            s/\}+/_/g;
            s/"|'\''/_/g;
            s/_+/_/g;
            s/^_+//;
            s/_+$//;
        ')"
    fi
}

transform_name() {
    local f="$1"
    local dir base newbase ts stem ext media_suffix media_date media_time media_kind yy
    local audio_ext_re common_media_ext_re

    dir="$(dirname -- "$f")"
    base="$(basename -- "$f")"
    audio_ext_re='(mp3|aac|m4a|flac|ogg|oga|opus|wav|wma|alac|aiff|ape|mka|mp2|mp1|ac3)'
    common_media_ext_re='(mp3|aac|m4a|flac|ogg|oga|opus|wav|wma|alac|aiff|ape|mka|mp2|mp1|ac3|mp4|m4v|mov|mkv|webm|avi)'

    if path_has_control_chars "$base"; then
        base="$(sanitize_basename_control_chars "$base")"
    fi

    if is_media_file "$base"; then
        while [[ "$base" == _* ]]; do
            base="${base#_}"
        done
    fi

    newbase="$(transform_basename "$base" "$f")"

    if [[ -e "$f" ]]; then
        if [[ "$newbase" =~ ^image.*\.jpg$ ]] && [[ ! "$newbase" =~ ^[0-9]{8}_[0-9]{6}_image.*\.jpg$ ]]; then
            ts="$(get_file_oldest_timestamp_yyyymmdd_hhmmss "$f")"
            newbase="${ts}_${newbase}"
        fi

        if [[ "$newbase" =~ ^video.*\.mp4$ ]] && [[ ! "$newbase" =~ ^[0-9]{8}_[0-9]{6}_video.*\.mp4$ ]]; then
            ts="$(get_file_oldest_timestamp_yyyymmdd_hhmmss "$f")"
            newbase="${ts}_${newbase}"
        fi

        if [[ "$newbase" =~ ^IMG_([0-9]{8})_([0-9]{6})(\..+)$ ]]; then
            newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-img${BASH_REMATCH[3]}"
        elif [[ "$newbase" =~ ^PXL_([0-9]{8})_([0-9]{6})[0-9]*(\..+)$ ]]; then
            newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-pxl${BASH_REMATCH[3]}"
        elif [[ "$newbase" =~ ^received_[0-9]+(\..+)$ ]]; then
            ts="$(get_file_oldest_timestamp_compact "$f")"
            newbase="${ts}-received${BASH_REMATCH[1]}"
        elif [[ "$newbase" =~ ^IMG_[0-9]+(\..+)$ ]]; then
            ts="$(get_file_oldest_timestamp_compact "$f")"
            newbase="${ts}-img${BASH_REMATCH[1]}"
        elif [[ "$newbase" =~ ^Screen_Recording_([0-9]{8})_([0-9]{6})_(.+)(\..+)$ ]]; then
            local screen_suffix
            screen_suffix="${BASH_REMATCH[3]}"
            screen_suffix=$(printf '%s' "$screen_suffix" | tr '[:upper:]' '[:lower:]')
            screen_suffix=$(printf '%s' "$screen_suffix" | sed -E 's/[^[:alnum:]]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
            if [[ -n "$screen_suffix" ]]; then
                newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-screen_recording-${screen_suffix}${BASH_REMATCH[4]}"
            else
                newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-screen_recording${BASH_REMATCH[4]}"
            fi
        elif [[ "$newbase" =~ ^(Sprache|Voice)_([0-9]{6})_([0-9]{6})_(.+)(\..+)$ ]]; then
            media_kind="${BASH_REMATCH[1]}"
            media_date="20${BASH_REMATCH[2]}"
            media_time="${BASH_REMATCH[3]}"
            media_suffix="${BASH_REMATCH[4]}"
            media_kind=$(printf '%s' "$media_kind" | tr '[:upper:]' '[:lower:]')
            media_suffix=$(printf '%s' "$media_suffix" | tr '[:upper:]' '[:lower:]')
            media_suffix=$(printf '%s' "$media_suffix" | sed -E 's/[^[:alnum:]]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
            if [[ -n "$media_suffix" ]]; then
                newbase="${media_date}_${media_time}-${media_kind}-${media_suffix}${BASH_REMATCH[5]}"
            else
                newbase="${media_date}_${media_time}-${media_kind}${BASH_REMATCH[5]}"
            fi
        elif [[ "$newbase" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})_([0-9]{2})-([0-9]{2})-([0-9]{2})(\.${audio_ext_re})$ ]]; then
            newbase="${BASH_REMATCH[1]}${BASH_REMATCH[2]}${BASH_REMATCH[3]}_${BASH_REMATCH[4]}${BASH_REMATCH[5]}${BASH_REMATCH[6]}${BASH_REMATCH[7]}"
        elif [[ "$newbase" =~ ^([0-9]{8})-([0-9]{6})_(.+)(\.${common_media_ext_re})$ ]]; then
            media_suffix="${BASH_REMATCH[3]}"
            media_suffix=$(printf '%s' "$media_suffix" | tr '[:upper:]' '[:lower:]')
            media_suffix=$(printf '%s' "$media_suffix" | sed -E 's/[^[:alnum:]]+/-/g; s/^-+//; s/-+$//; s/-+/-/g')
            if [[ -n "$media_suffix" ]]; then
                newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}-${media_suffix}${BASH_REMATCH[4]}"
            else
                newbase="${BASH_REMATCH[1]}_${BASH_REMATCH[2]}${BASH_REMATCH[4]}"
            fi
        fi
    fi

    if is_media_file "$newbase"; then
        while [[ "$newbase" == _* ]]; do
            newbase="${newbase#_}"
        done
        if [[ "$newbase" =~ ^([0-9])\.(mp3|aac|m4a|flac|ogg|oga|opus|wav|wma|alac|aiff|ape|mka|mp2|mp1|ac3|mp4|m4v|mov|mkv|webm|avi)$ ]]; then
            newbase="0${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        fi
    fi

    if [[ ! -d "$f" && "$newbase" == *.* ]]; then
        stem="${newbase%.*}"
        ext="${newbase##*.}"
        if [[ "$ext" != "${ext,,}" ]]; then
            newbase="${stem}.${ext,,}"
        fi
    fi

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

    print_single_target_check_verbose "$(checksum_cmd "$sum_file")" "$sum_dir" "$target_ref" "$sum_base"

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
    local out cached

    cached="$(db_get_cached_file_hash "$file" "$kind" || true)"
    if [[ -n "$cached" ]]; then
        printf '%s\n' "$cached"
        return 0
    fi

    case "$kind" in
        sha512) out="$(sha512sum -- "$file" | awk '{print tolower($1)}')" ;;
        md5)    out="$(md5sum    -- "$file" | awk '{print tolower($1)}')" ;;
        *) return 1 ;;
    esac

    ((++FILES_HASHED))
    db_record_file_hash "$file" "$kind" "$out"
    printf '%s\n' "$out"
}

md5_of_file() {
    local file="$1"
    local out cached

    cached="$(db_get_cached_file_hash "$file" "md5" || true)"
    if [[ -n "$cached" ]]; then
        printf '%s\n' "$cached"
        return 0
    fi

    out="$(md5sum -- "$file" | awk '{print tolower($1)}')"
    ((++FILES_HASHED))
    db_record_file_hash "$file" "md5" "$out"
    printf '%s\n' "$out"
}

format_bytes_human() {
    local bytes="$1"
    awk -v b="$bytes" 'BEGIN {
        kb = b / 1024.0;
        mb = b / 1048576.0;
        printf "%d bytes | %.2f kB | %.2f MB", b, kb, mb
    }'
}

get_file_birth_epoch() {
    local file="$1"
    stat -c %W -- "$file" 2>/dev/null || echo 0
}

get_file_mtime_epoch() {
    local file="$1"
    stat -c %Y -- "$file" 2>/dev/null || echo 0
}

get_file_size_bytes() {
    local file="$1"
    stat -c %s -- "$file" 2>/dev/null || echo 0
}

format_epoch_human() {
    local epoch="$1"
    if [[ "$epoch" =~ ^[0-9]+$ ]] && (( epoch > 0 )); then
        date -d "@$epoch" "+%Y-%m-%d %H:%M:%S"
    else
        printf '%s' "unavailable"
    fi
}

make_other_suffix_path() {
    local path="$1"
    local dir base stem ext candidate
    dir="$(dirname -- "$path")"
    base="$(basename -- "$path")"

    if [[ "$base" == *.* ]]; then
        stem="${base%.*}"
        ext=".${base##*.}"
    else
        stem="$base"
        ext=""
    fi

    candidate="${dir}/${stem}_OTHER${ext}"
    while [[ -e "$candidate" ]]; do
        candidate="${dir}/${stem}_OTHER${ext}"
        stem="${stem}_OTHER"
    done
    printf '%s' "$candidate"
}

handle_existing_target_collision() {
    local old="$1"
    local new="$2"

    COLLISION_RENAMED_TARGET=""

    if [[ "$mode" == "dry-run" ]]; then
        echo -e "${YELLOW}COLLISION:${RESET} Target file already exists."
        echo -e "${CYAN}[DRY-RUN] Would compare MD5, size, and timestamps of source/destination and ask what to do:${RESET} $old ${ARROW} $new"
        return 1
    fi

    can_overwrite_collision_with_identical_md5 "$old" "$new"
    collision_decision_rc=$?

    if [[ $collision_decision_rc -eq 0 ]]; then
        echo -e "${CYAN}OVERWRITE:${RESET} removing destination and continuing rename: $new"
        rm -f -- "$new"
        return 0
    elif [[ $collision_decision_rc -eq 2 ]]; then
        return 2
    elif [[ $collision_decision_rc -eq 3 ]]; then
        echo -e "${CYAN}RENAME WITH _OTHER:${RESET} source will be renamed to: $COLLISION_OTHER_PATH"
        COLLISION_RENAMED_TARGET="$COLLISION_OTHER_PATH"
        return 3
    else
        return 1
    fi
}

can_overwrite_collision_with_identical_md5() {
    local old="$1"
    local new="$2"
    local old_md5 new_md5 answer=""
    local old_size new_size old_btime new_btime old_mtime new_mtime
    local old_other_path

    COLLISION_OTHER_PATH=""
    [[ -f "$old" && -f "$new" ]] || return 1

    old_md5="$(md5_of_file "$old")"
    new_md5="$(md5_of_file "$new")"
    old_size="$(get_file_size_bytes "$old")"
    new_size="$(get_file_size_bytes "$new")"
    old_btime="$(get_file_birth_epoch "$old")"
    new_btime="$(get_file_birth_epoch "$new")"
    old_mtime="$(get_file_mtime_epoch "$old")"
    new_mtime="$(get_file_mtime_epoch "$new")"

    echo
    echo -e "${YELLOW}COLLISION:${RESET} target file already exists."
    echo -e "  ${RED}SOURCE:${RESET}      $old"
    echo -e "    size:       $(format_bytes_human "$old_size")"
    echo -e "    created:    $(format_epoch_human "$old_btime")"
    echo -e "    modified:   $(format_epoch_human "$old_mtime")"
    echo -e "    md5:        $old_md5"
    echo -e "  ${GREEN}DESTINATION:${RESET} $new"
    echo -e "    size:       $(format_bytes_human "$new_size")"
    echo -e "    created:    $(format_epoch_human "$new_btime")"
    echo -e "    modified:   $(format_epoch_human "$new_mtime")"
    echo -e "    md5:        $new_md5"

    if [[ "$old_md5" == "$new_md5" ]]; then
        echo "Files are identical."
    else
        echo "Files are different."
    fi

    old_other_path="$(make_other_suffix_path "$new")"
    verbose_question_timestamp "What should be done?"
    echo "What should be done?"
    echo "  [O] Overwrite destination and continue rename"
    echo "  [R] Rename source with suffix _OTHER -> $(basename -- "$old_other_path")"
    echo "  [S] Skip (default)"
    echo "  [Q] Quit"
    echo -n "Choice [o/r/S/q]: "

    flush_stdin
    read_single_key answer "$PROMPT_WAIT_SECONDS"
    echo

    case "$answer" in
        q|Q)
            stopped_by_user=yes
            return 2
            ;;
        o|O)
            return 0
            ;;
        r|R)
            COLLISION_OTHER_PATH="$old_other_path"
            return 3
            ;;
        *)
            return 1
            ;;
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

    if (( VERBOSE == 1 )); then
        print_checksum_update_verbose "$sum_file" "$old_name" "$new_name"
    fi

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
        handle_existing_target_collision "$old" "$new"
        collision_decision_rc=$?

        if [[ $collision_decision_rc -eq 0 ]]; then
            :
        elif [[ $collision_decision_rc -eq 2 ]]; then
            return 1
        elif [[ $collision_decision_rc -eq 3 ]]; then
            new="$COLLISION_RENAMED_TARGET"
        else
            echo -e "${YELLOW}SKIP:${RESET} Target file already exists."
            vlog "Collision detected for plain rename '$old' -> '$new'"
            ((++files_skipped))
            return 0
        fi
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
        echo -e "${CYAN}HTML PAIR RENAME:${RESET} HTML file and companion directory are being updated together."
        echo -e "  ${RED}OLD HTML:${RESET} $old"
        echo -e "  ${GREEN}NEW HTML:${RESET} $new"
        echo -e "  ${RED}OLD DIR:${RESET}  $old_companion_dir"
        echo -e "  ${GREEN}NEW DIR:${RESET}  $new_companion_dir"
        if mv -i -- "$old_companion_dir" "$new_companion_dir"; then
            ((++files_affected))
            record_rename "$old_companion_dir" "$new_companion_dir"
            db_rewrite_subtree "$old_companion_dir" "$new_companion_dir"
            old_companion_name="$(basename -- "$old_companion_dir")"
            new_companion_name="$(basename -- "$new_companion_dir")"
            update_html_companion_reference "$new" "$old_companion_name" "$new_companion_name"
            echo -e "${CYAN}HTML PAIR UPDATED:${RESET} companion reference inside HTML file was updated from '$old_companion_name' to '$new_companion_name'."
            db_mark_checked "$new_companion_dir" "html_companion" "checked"
            processed["$old_companion_dir"]=1
            processed["$new_companion_dir"]=1
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

declare -A RECOVERY_INDEX_READY=()
declare -A RECOVERY_INDEX_BY_BASENAME=()
declare -A RECOVERY_INDEX_ALL_FILES=()

build_recovery_file_index() {
    local search_root="$1"
    local candidate base key

    [[ -n "${RECOVERY_INDEX_READY[$search_root]-}" ]] && return 0

    while IFS= read -r -d '' candidate; do
        base="$(basename -- "$candidate")"
        key="${search_root}"$'\x1f'"${base}"
        if [[ -n "${RECOVERY_INDEX_BY_BASENAME[$key]-}" ]]; then
            RECOVERY_INDEX_BY_BASENAME["$key"]+=$'\n'"$candidate"
        else
            RECOVERY_INDEX_BY_BASENAME["$key"]="$candidate"
        fi
        if [[ -n "${RECOVERY_INDEX_ALL_FILES[$search_root]-}" ]]; then
            RECOVERY_INDEX_ALL_FILES["$search_root"]+=$'\n'"$candidate"
        else
            RECOVERY_INDEX_ALL_FILES["$search_root"]="$candidate"
        fi
    done < <(find "$search_root" -type f -print0 2>/dev/null)

    RECOVERY_INDEX_READY["$search_root"]=1
}

find_best_path_for_missing_ref() {
    local missing_ref="$1"
    local expected_hash="$2"
    local sum_file="$3"

    local kind wanted_base wanted_norm missing_dir search_root
    local fast_base fast_path fast_hash
    local candidate candidate_hash candidate_name indexed_candidates index_key all_candidates
    local -a candidate_names=()

    kind="$(checksum_kind "$sum_file")"
    wanted_base="$(basename -- "$missing_ref")"
    wanted_norm="$(transform_basename "$wanted_base")"
    missing_dir="$(dirname -- "$missing_ref")"
    search_root="$(dirname -- "$sum_file")"

    print_try_recover_missing_ref_verbose "$missing_ref" "${expected_hash:-none}"

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

    if [[ "$wanted_base" == "$wanted_norm" ]]; then
        candidate_names=( "$wanted_base" )
    else
        candidate_names=( "$wanted_norm" "$wanted_base" )
    fi

    build_recovery_file_index "$search_root"

    for candidate_name in "${candidate_names[@]}"; do
        index_key="${search_root}"$'\x1f'"${candidate_name}"
        indexed_candidates="${RECOVERY_INDEX_BY_BASENAME[$index_key]-}"
        [[ -n "$indexed_candidates" ]] || continue
        while IFS= read -r candidate; do
            [[ -n "$candidate" ]] || continue
            vlog "Subtree recovery candidate by name: '$candidate'"
            if [[ -n "$expected_hash" ]]; then
                candidate_hash="$(checksum_of_file "$kind" "$candidate")"
                vlog "Subtree recovery candidate by name has $kind=$candidate_hash"
                if [[ "${candidate_hash,,}" == "${expected_hash,,}" ]]; then
                    vlog "Subtree recovery candidate by name checksum matches"
                    printf '%s' "$candidate"
                    return 0
                fi
            else
                vlog "Subtree recovery candidate by name accepted (no expected hash available)"
                printf '%s' "$candidate"
                return 0
            fi
        done <<< "$indexed_candidates"
    done

    if [[ -n "$expected_hash" ]]; then
        candidate="$(db_find_path_by_file_hash_in_subtree "$search_root" "$kind" "$expected_hash" || true)"
        if [[ -n "$candidate" ]]; then
            vlog "Subtree recovery candidate by DB hash matches: '$candidate'"
            printf '%s' "$candidate"
            return 0
        fi

        print_scan_by_checksum_verbose "$search_root" "$expected_hash"
        all_candidates="${RECOVERY_INDEX_ALL_FILES[$search_root]-}"
        while IFS= read -r candidate; do
            [[ -n "$candidate" ]] || continue
            candidate_hash="$(checksum_of_file "$kind" "$candidate")"
            if [[ "${candidate_hash,,}" == "${expected_hash,,}" ]]; then
                vlog "Subtree recovery candidate by checksum matches: '$candidate'"
                printf '%s' "$candidate"
                return 0
            fi
        done <<< "$all_candidates"
    fi

    vlog "Subtree recovery failed for '$missing_ref' under '$search_root'"
    return 1
}


handle_lnk_file() {
    local f="$1"
    local answer=""

    echo
    echo -e "${YELLOW}LNK FILE:${RESET} $f"
    verbose_question_timestamp "Remove this .lnk file? [y/N/q]:"
    echo -n "Remove this .lnk file? [y/N/q]: "

    flush_stdin
    read_single_key answer "$PROMPT_WAIT_SECONDS"
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
AUTO_RENAME_DIR=""

declare -a renamed_list=()
declare -A recorded
declare -A processed

clear_resume_state_file() {
    [[ -f "$RESUME_STATE_FILE" ]] || return 0
    rm -f -- "$RESUME_STATE_FILE"
}

save_resume_checkpoint() {
    local tmp_processed tmp_renamed
    local p r

    if ! command -v python3 >/dev/null 2>&1; then
        return 0
    fi

    tmp_processed="$(mktemp)"
    tmp_renamed="$(mktemp)"

    for p in "${!processed[@]}"; do
        printf '%s\0' "$p" >> "$tmp_processed"
    done
    for r in "${renamed_list[@]}"; do
        printf '%s\0' "$r" >> "$tmp_renamed"
    done

    if ! python3 - "$RESUME_STATE_FILE" "$tmp_processed" "$tmp_renamed" \
        "$SCRIPT_VERSION" "$START_DIR" "$mode" "$process_scope" \
        "$USE_DB" "$FAST_DB" "$FORCE_RECHECK" "$PROMPT_WAIT_SECONDS" \
        "$files_examined" "$files_affected" "$files_skipped" "$FILES_HASHED" \
        "$SCRIPT_START_TIME" <<'PY'
import json
import pathlib
import sys

state_path = pathlib.Path(sys.argv[1])
processed_path = pathlib.Path(sys.argv[2])
renamed_path = pathlib.Path(sys.argv[3])

def read_null_file(path: pathlib.Path):
    data = path.read_bytes()
    if not data:
        return []
    return [x.decode("utf-8", "surrogateescape") for x in data.split(b"\0") if x]

payload = {
    "scriptVersion": sys.argv[4],
    "startDir": sys.argv[5],
    "mode": sys.argv[6],
    "scope": sys.argv[7],
    "useDb": int(sys.argv[8]),
    "fastDb": int(sys.argv[9]),
    "forceRecheck": int(sys.argv[10]),
    "promptWaitSeconds": int(sys.argv[11]),
    "filesExamined": int(sys.argv[12]),
    "filesAffected": int(sys.argv[13]),
    "filesSkipped": int(sys.argv[14]),
    "filesHashed": int(sys.argv[15]),
    "scriptStartTime": sys.argv[16],
    "processed": read_null_file(processed_path),
    "renamedList": read_null_file(renamed_path),
}

state_path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
PY
    then
        rm -f -- "$tmp_processed" "$tmp_renamed"
        return 0
    fi

    rm -f -- "$tmp_processed" "$tmp_renamed"
}

load_resume_checkpoint() {
    local tmp_processed tmp_renamed meta
    local prev_processed_count=0
    local prev_renamed_count=0
    local path entry

    [[ -f "$RESUME_STATE_FILE" ]] || return 1
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Resume checkpoint found but python3 is unavailable; starting from scratch."
        return 1
    fi

    tmp_processed="$(mktemp)"
    tmp_renamed="$(mktemp)"
    verbose_status_timestamp "Loading resume checkpoint metadata from: $RESUME_STATE_FILE"
    if ! meta="$(python3 - "$RESUME_STATE_FILE" "$tmp_processed" "$tmp_renamed" "$START_DIR" "$mode" "$process_scope" "$USE_DB" "$FAST_DB" "$FORCE_RECHECK" "$PROMPT_WAIT_SECONDS" <<'PY'
import json
import pathlib
import sys

state_path = pathlib.Path(sys.argv[1])
processed_out = pathlib.Path(sys.argv[2])
renamed_out = pathlib.Path(sys.argv[3])

data = json.loads(state_path.read_text(encoding="utf-8"))

checks = [
    ("startDir", sys.argv[4]),
    ("mode", sys.argv[5]),
    ("scope", sys.argv[6]),
]
for key, expected in checks:
    if str(data.get(key, "")) != expected:
        print(f"mismatch:{key}")
        sys.exit(2)

numeric_checks = [
    ("useDb", int(sys.argv[7])),
    ("fastDb", int(sys.argv[8])),
    ("forceRecheck", int(sys.argv[9])),
    ("promptWaitSeconds", int(sys.argv[10])),
]
for key, expected in numeric_checks:
    if int(data.get(key, -1)) != expected:
        print(f"mismatch:{key}")
        sys.exit(2)

processed = data.get("processed", [])
renamed = data.get("renamedList", [])
if not isinstance(processed, list) or not isinstance(renamed, list):
    print("invalid:lists")
    sys.exit(3)

processed_out.write_bytes(b"\0".join(s.encode("utf-8", "surrogateescape") for s in processed) + (b"\0" if processed else b""))
renamed_out.write_bytes(b"\0".join(s.encode("utf-8", "surrogateescape") for s in renamed) + (b"\0" if renamed else b""))

fields = [
    str(int(data.get("filesExamined", 0))),
    str(int(data.get("filesAffected", 0))),
    str(int(data.get("filesSkipped", 0))),
    str(int(data.get("filesHashed", 0))),
    str(data.get("scriptStartTime", "")),
]
print("\t".join(fields))
PY
)"; then
        rm -f -- "$tmp_processed" "$tmp_renamed"
        if [[ "$meta" == mismatch:* ]]; then
            echo "Resume checkpoint exists but options differ from the previous run; starting from scratch."
        else
            echo "Resume checkpoint is invalid; starting from scratch."
        fi
        return 1
    fi

    IFS=$'\t' read -r files_examined files_affected files_skipped FILES_HASHED SCRIPT_START_TIME <<< "$meta"

    unset processed
    declare -gA processed=()
    verbose_status_timestamp "Restoring processed-entry state from checkpoint..."
    while IFS= read -r -d '' path; do
        processed["$path"]=1
        ((++prev_processed_count))
        if (( VERBOSE == 1 && prev_processed_count % 100000 == 0 )); then
            verbose_status_timestamp "Resume restore progress: ${prev_processed_count} processed entries loaded..."
        fi
    done < "$tmp_processed"

    renamed_list=()
    unset recorded
    declare -gA recorded=()
    verbose_status_timestamp "Restoring renamed-entry history from checkpoint..."
    while IFS= read -r -d '' entry; do
        renamed_list+=( "$entry" )
        recorded["$entry"]=1
        ((++prev_renamed_count))
        if (( VERBOSE == 1 && prev_renamed_count % 50000 == 0 )); then
            verbose_status_timestamp "Resume restore progress: ${prev_renamed_count} renamed entries loaded..."
        fi
    done < "$tmp_renamed"

    rm -f -- "$tmp_processed" "$tmp_renamed"
    RESUME_STATE_WAS_LOADED=1
    verbose_status_timestamp "Resume checkpoint restore complete: processed=${prev_processed_count}, renamed=${prev_renamed_count}"
    echo "Resume checkpoint loaded: $prev_processed_count entries marked as already processed."
    return 0
}

maybe_resume_from_checkpoint() {
    local answer=""

    [[ -f "$RESUME_STATE_FILE" ]] || return 0

    case "$CLI_RESUME_STATE" in
        fresh)
            return 0
            ;;
        resume)
            load_resume_checkpoint || true
            return 0
            ;;
        ask)
            if [[ "$EARLY_RESUME_DECISION" == "quit" ]]; then
                echo "Quitting."
                exit 0
            elif [[ "$EARLY_RESUME_DECISION" == "resume" ]]; then
                load_resume_checkpoint || true
            elif [[ "$EARLY_RESUME_DECISION" != "fresh" ]]; then
                echo
                echo "Checkpoint found from an interrupted run: $RESUME_STATE_FILE"
                verbose_question_timestamp "Resume from checkpoint?"
                echo "Resume from checkpoint?"
                echo "  [Y] Resume (default)"
                echo "  [N] Start from the beginning"
                echo "  [Q] Quit"
                echo -n "Choice [Y/n/q]: "
                flush_stdin
                read_single_key answer "$PROMPT_WAIT_SECONDS"
                echo
                if [[ "$answer" =~ [Qq] ]]; then
                    echo "Quitting."
                    exit 0
                elif [[ ! "$answer" =~ [Nn] ]]; then
                    load_resume_checkpoint || true
                fi
            fi
            ;;
    esac
}

record_rename() {
    local old="$1" new="$2"
    local key="$old|$new"
    [[ -n "${recorded[$key]+x}" ]] && return 0
    recorded["$key"]=1
    renamed_list+=("$key")
}

auto_yes_current_dir_matches() {
    local path="$1"
    local path_dir
    path_dir="$(dirname -- "$path")"
    [[ -n "$AUTO_RENAME_DIR" && "$path_dir" == "$AUTO_RENAME_DIR" ]]
}

print_rename_prompt_menu() {
    local kind_label="$1"
    verbose_question_timestamp "Rename this ${kind_label}?"
    echo "Rename this ${kind_label}?"
    echo "  [Y] Yes (default)"
    echo "  [N] No"
    echo "  [M] Rename by editing target filename"
    echo "  [A] All remaining"
    echo "  [D] Yes for this directory"
    echo "  [E] Add exception (skip this path and its subtree by filter match)"
    echo "  [X] Exact exception (do not rename only this exact path; still check subtree)"
    echo "  [Q] Quit"
    echo -n "Choice [Y/n/m/a/d/E/x/q]: "
}

choose_custom_rename_target() {
    local old_path="$1"
    local suggested_path="$2"
    local dir suggested_base edited_base

    dir="$(dirname -- "$old_path")"
    suggested_base="$(basename -- "$suggested_path")"

    echo >&2
    verbose_question_timestamp "Rename by editing target filename"
    echo "Rename by editing target filename (basename only):" >&2
    echo "  Use arrows/Home/End for cursor movement and editing." >&2
    echo "  Current suggestion: $suggested_base" >&2
    echo -n "New basename: " >&2
    read_line_editable edited_base "$PROMPT_WAIT_SECONDS" "$suggested_base"
    echo >&2

    if [[ -z "$edited_base" ]]; then
        edited_base="$suggested_base"
    fi

    if [[ "$edited_base" == *"/"* ]]; then
        echo -e "${YELLOW}SKIP:${RESET} Edited name must be a basename only (no '/')."
        return 1
    fi
    if [[ "$edited_base" == "." || "$edited_base" == ".." ]]; then
        echo -e "${YELLOW}SKIP:${RESET} Invalid edited basename: '$edited_base'"
        return 1
    fi

    if [[ "$dir" == "." ]]; then
        printf './%s' "$edited_base"
    else
        printf '%s/%s' "$dir" "$edited_base"
    fi
}

print_checksum_prompt_menu() {
    local label_lower="$1"
    local hash_file="$2"
    verbose_question_timestamp "Rename this ${label_lower} group?"
    echo "Rename this ${label_lower} group?"
    echo "  hash file: $hash_file"
    echo "  [Y] Yes (default)"
    echo "  [N] No"
    echo "  [A] All remaining"
    echo "  [D] Yes for this directory"
    echo "  [Q] Quit"
    echo -n "Choice [Y/n/a/d/q]: "
}

print_rename_action_verbose() {
    (( VERBOSE == 1 )) || return 0
    local old_path="$1"
    local new_path="$2"
    local reason="${3-}"

    local line="[VERBOSE] Renaming '${old_path}' -> '${new_path}'"
    local second=""
    if [[ -n "$reason" ]]; then
        second="due to ${reason}"
        line="${line} ${second}"
    fi

    if (( ${#line} <= MAX_LINE_LENGTH )); then
        echo "$line" >&2
    else
        echo "[VERBOSE] Renaming '${old_path}'" >&2
        echo "          -> '${new_path}'${second:+ ${second}}" >&2
    fi
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


print_summary() {
    (( SUMMARY_PRINTED == 0 )) || return 0
    SUMMARY_PRINTED=1
    SCRIPT_FINISH_TIME="${SCRIPT_FINISH_TIME:-$(date '+%Y-%m-%d %H:%M:%S')}"

    echo
    if (( files_affected > 0 )); then
        echo "Affected entries (last 100):"
        start_idx=0
        total_renamed=${#renamed_list[@]}
        if (( total_renamed > 100 )); then
            start_idx=$(( total_renamed - 100 ))
        fi
        for (( idx=start_idx; idx<total_renamed; idx++ )); do
            r="${renamed_list[$idx]}"
            old=${r%%|*}
            new=${r#*|}
            printf "  %s %b%s%b %s\n" \
                "$old" \
                "$RED" "$ARROW" "$RESET" \
                "$new"
        done
        echo
    fi

    echo "========= SUMMARY ========="
    echo "Script start time:     $SCRIPT_START_TIME"
    echo "Script finish time:    $SCRIPT_FINISH_TIME"
    echo "Mode:                  $mode"
    echo "Colors enabled:        $use_colors"
    echo "Verbose:               $VERBOSE"
    echo "Scope:                 $process_scope"
    echo "Entries examined:      $files_examined"
    echo "Files processed:       $files_examined"
    echo "Files hashed:          $FILES_HASHED"
    echo "Entries affected:      $files_affected"
    echo "Entries skipped:       $files_skipped"
    echo "Stopped by user:       $stopped_by_user"
    if (( USE_DB == 1 )); then
        echo "DB used:               yes"
        echo "DB hashes added:       $DB_HASHES_ADDED"
        echo "DB rows new:           $DB_ROWS_NEW"
        echo "DB rows updated:       $DB_ROWS_UPDATED"
        echo "DB rows removed:       $DB_ROWS_REMOVED"
        echo "DB stale rows removed: $DB_STALE_ROWS_REMOVED"
        echo "DB hash lookup hits:   $DB_HASH_LOOKUP_HITS"
        echo "DB hash lookup misses: $DB_HASH_LOOKUP_MISSES"
    else
        echo "DB used:               no"
    fi
    echo "==========================="
}

on_interrupt() {
    stopped_by_user=yes
    SCRIPT_FINISH_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
    save_resume_checkpoint
    echo
    echo "Interrupted by user (Ctrl-C)."
    echo "Checkpoint saved: $RESUME_STATE_FILE"
    print_summary
    exit 130
}

trap on_interrupt INT

startup_progress "Discovering and sorting entries for selected scope (this can take time on large trees)..."
if [[ "$process_scope" == "current" ]]; then
    mapfile -d '' -t ordered_paths < <(
        find . -mindepth 1 -maxdepth 1 -depth -print0 |
        python3 -c '
import sys
from datetime import datetime
import time
verbose = (len(sys.argv) > 1 and sys.argv[1] == "1")
buf = bytearray()
progress_every = 64 * 1024 * 1024
next_progress = progress_every
start = time.monotonic()
while True:
    chunk = sys.stdin.buffer.read(1024 * 1024)
    if not chunk:
        break
    buf.extend(chunk)
    if verbose and len(buf) >= next_progress:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        mb = len(buf) / (1024.0 * 1024.0)
        elapsed = time.monotonic() - start
        sys.stderr.write(f"[STARTUP {ts}] Discovery buffered: {mb:.1f} MB in {elapsed:.1f}s...\n")
        sys.stderr.flush()
        while len(buf) >= next_progress:
            next_progress += progress_every
items = [x for x in bytes(buf).split(b"\0") if x]
if verbose:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    mb = len(buf) / (1024.0 * 1024.0)
    elapsed = time.monotonic() - start
    sys.stderr.write(f"[STARTUP {ts}] Discovery done: {len(items)} entries buffered ({mb:.1f} MB) in {elapsed:.1f}s. Starting sort...\n")
    sys.stderr.flush()
def depth(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return s.count("/")
def is_checksum(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return 0 if (s.endswith(".sha512") or s.endswith(".md5")) else 1
sort_start = time.monotonic()
items.sort(key=lambda p: (-depth(p), is_checksum(p), p))
if verbose:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    sort_elapsed = time.monotonic() - sort_start
    total_elapsed = time.monotonic() - start
    sys.stderr.write(f"[STARTUP {ts}] Sorting done in {sort_elapsed:.1f}s (total startup discovery/sort: {total_elapsed:.1f}s). Starting transfer to shell...\n")
    sys.stderr.flush()
total_items = len(items)
chunk_items = 50000
report_every = 200000
next_report = report_every
written = 0
for i in range(0, total_items, chunk_items):
    chunk_items_list = items[i:i + chunk_items]
    if not chunk_items_list:
        continue
    sys.stdout.buffer.write(b"\0".join(chunk_items_list) + b"\0")
    written += len(chunk_items_list)
    if verbose:
        while written >= next_report:
            ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            pct = (written * 100.0 / total_items) if total_items else 100.0
            sys.stderr.write(f"[STARTUP {ts}] Transfer progress: {written}/{total_items} entries ({pct:.1f}%)...\n")
            sys.stderr.flush()
            next_report += report_every
if verbose:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    sys.stderr.write(f"[STARTUP {ts}] Transfer to shell complete: {written}/{total_items} entries.\n")
    sys.stderr.flush()
' "$VERBOSE"
    )
else
    mapfile -d '' -t ordered_paths < <(
        find . -depth -mindepth 1 -print0 |
        python3 -c '
import sys
from datetime import datetime
import time
verbose = (len(sys.argv) > 1 and sys.argv[1] == "1")
buf = bytearray()
progress_every = 64 * 1024 * 1024
next_progress = progress_every
start = time.monotonic()
while True:
    chunk = sys.stdin.buffer.read(1024 * 1024)
    if not chunk:
        break
    buf.extend(chunk)
    if verbose and len(buf) >= next_progress:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        mb = len(buf) / (1024.0 * 1024.0)
        elapsed = time.monotonic() - start
        sys.stderr.write(f"[STARTUP {ts}] Discovery buffered: {mb:.1f} MB in {elapsed:.1f}s...\n")
        sys.stderr.flush()
        while len(buf) >= next_progress:
            next_progress += progress_every
items = [x for x in bytes(buf).split(b"\0") if x]
if verbose:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    mb = len(buf) / (1024.0 * 1024.0)
    elapsed = time.monotonic() - start
    sys.stderr.write(f"[STARTUP {ts}] Discovery done: {len(items)} entries buffered ({mb:.1f} MB) in {elapsed:.1f}s. Starting sort...\n")
    sys.stderr.flush()
def depth(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return s.count("/")
def is_checksum(p: bytes) -> int:
    s = p.decode("utf-8", "surrogateescape")
    return 0 if (s.endswith(".sha512") or s.endswith(".md5")) else 1
sort_start = time.monotonic()
items.sort(key=lambda p: (-depth(p), is_checksum(p), p))
if verbose:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    sort_elapsed = time.monotonic() - sort_start
    total_elapsed = time.monotonic() - start
    sys.stderr.write(f"[STARTUP {ts}] Sorting done in {sort_elapsed:.1f}s (total startup discovery/sort: {total_elapsed:.1f}s). Starting transfer to shell...\n")
    sys.stderr.flush()
total_items = len(items)
chunk_items = 50000
report_every = 200000
next_report = report_every
written = 0
for i in range(0, total_items, chunk_items):
    chunk_items_list = items[i:i + chunk_items]
    if not chunk_items_list:
        continue
    sys.stdout.buffer.write(b"\0".join(chunk_items_list) + b"\0")
    written += len(chunk_items_list)
    if verbose:
        while written >= next_report:
            ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
            pct = (written * 100.0 / total_items) if total_items else 100.0
            sys.stderr.write(f"[STARTUP {ts}] Transfer progress: {written}/{total_items} entries ({pct:.1f}%)...\n")
            sys.stderr.flush()
            next_report += report_every
if verbose:
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    sys.stderr.write(f"[STARTUP {ts}] Transfer to shell complete: {written}/{total_items} entries.\n")
    sys.stderr.flush()
' "$VERBOSE"
    )
fi
startup_progress "Entry discovery and sort complete: ${#ordered_paths[@]} entries"
startup_progress "Entering main processing loop..."

vlog "Discovered entries to process: ${#ordered_paths[@]}"
vlog "Progress box updates every ${VERBOSE_MAIN_EVERY} iterations; already-processed entries may be skipped quickly."
maybe_resume_from_checkpoint

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

    if db_has_valid_entry "$f" && ! path_has_control_chars "$f"; then
        db_backfill_missing_hashes_for_existing_file "$f"
        if path_has_control_chars "$f"; then
            print_control_char_warning "$f"
        fi
        echo -e "${CYAN}DB SKIP:${RESET} '$(format_path_for_log "$f")'"
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
            print_resolved_ref_verbose "$ref" "${refs[-1]}"
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
                print_recovery_success_verbose "$ref" "$found_ref" "$replacement_ref"
                print_recovery_final_status_verbose "$ref" "success"
                echo -e "${CYAN}${label} RECOVERY CANDIDATE VERIFIED:${RESET} '$found_ref' matches the stored ${label,,}."
            else
                vlog "Recovery failed for '$ref'"
                print_recovery_final_status_verbose "$ref" "failed"
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
                print_protected_checksum_verbose "$sum_file"
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
            print_checksum_no_action_verbose "$sum_file"
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
        elif auto_yes_current_dir_matches "$sum_file"; then
            do_rename=yes
        else
            print_checksum_prompt_menu "${label,,}" "$sum_file"
            flush_stdin
            read_single_key input "$PROMPT_WAIT_SECONDS"
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
                    verbose_question_timestamp "Are you sure? [y/N]:"
                    echo "⚠️  This will rename ALL remaining files/directories."
                    echo -n "Are you sure? [y/N]: "
                    flush_stdin
                    read_single_key confirm "$PROMPT_WAIT_SECONDS"
                    echo
                    if [[ "$confirm" =~ [Yy] ]]; then
                        rename_all=yes
                        do_rename=yes
                    else
                        ((++files_skipped))
                        do_rename=no
                    fi
                    ;;
                d|D)
                    AUTO_RENAME_DIR="$(dirname -- "$sum_file")"
                    do_rename=yes
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
                print_rename_action_verbose "${refs[$i]}" "${new_refs[$i]}" "checksum group rename"
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
                    print_rename_action_verbose "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}" "html companion rename"
                    mv -i -- "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"
                    db_rewrite_subtree "${html_companion_old_dirs[$i]}" "${html_companion_new_dirs[$i]}"
                    db_mark_renamed_path_checked "${html_companion_new_dirs[$i]}" "plain"
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
            print_checksum_file_rename_verbose "$sum_file" "$new_sum"
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

    if is_internal_protected_path "$f"; then
        vlog "Protected internal file, no rename needed for '$f'"
        db_backfill_missing_hashes_for_existing_file "$f"
        ((++files_skipped))
        db_mark_checked "$f" "plain" "checked"
        continue
    fi

    new="$(transform_name "$f")"

    if is_protected_par2_name "$f"; then
        vlog "Protected .par2 basename starts with underscore, no rename needed for '$f'"
        db_backfill_missing_hashes_for_existing_file "$f"
        ((++files_skipped))
        db_mark_checked "$f" "plain" "checked"
        continue
    fi

    [[ "$f" == "$new" ]] && {
        vlog "No rename needed for '$f'"
        db_backfill_missing_hashes_for_existing_file "$f"
        ((++files_skipped))
        db_mark_checked "$f" "plain" "checked"
        continue
    }

    if [[ "$rename_all" == "yes" ]]; then
        print_rename_action_verbose "$f" "$new" "rename_all"
        perform_plain_entry_rename "$f" "$new" || break
        continue
    fi

    if auto_yes_current_dir_matches "$f"; then
        print_rename_action_verbose "$f" "$new" "per-directory auto-yes"
        perform_plain_entry_rename "$f" "$new" || break
        continue
    fi

    if exception_exists_for_path "$f"; then
        if grep -Fxq -- "$(exact_exception_entry_for_path "$f")" "$EXCLUDE_FILTERS_FILE" 2>/dev/null; then
            echo -e "${YELLOW}EXACT EXCEPTION EXISTS:${RESET} $(exact_exception_entry_for_path "$f") -> $EXCLUDE_FILTERS_FILE"
        else
            echo -e "${YELLOW}EXCEPTION EXISTS:${RESET} $(path_to_exclude_entry "$f") -> $EXCLUDE_FILTERS_FILE"
        fi
        ((++files_skipped))
        processed["$f"]=1
        db_mark_checked "$f" "plain" "checked"
        continue
    fi

    echo
    echo -e "${RED}OLD:${RESET} $f"
    echo -e "${GREEN}NEW:${RESET} $new"
    print_rename_prompt_menu "entry"
    flush_stdin
    read_single_key input "$PROMPT_WAIT_SECONDS"
    echo

    case "$input" in
        q|Q)
            stopped_by_user=yes
            break
            ;;
        n|N)
            ((++files_skipped))
            ;;
        m|M)
            custom_new="$(choose_custom_rename_target "$f" "$new" || true)"
            if [[ -z "$custom_new" ]]; then
                ((++files_skipped))
            elif [[ "$custom_new" == "$f" ]]; then
                vlog "Edited rename target matches current name, skipping '$f'"
                ((++files_skipped))
            else
                print_rename_action_verbose "$f" "$custom_new" "manual edit"
                perform_plain_entry_rename "$f" "$custom_new" || break
            fi
            ;;
        e|E)
            append_path_to_exclude_filters_file "$f"
            ((++files_skipped))
            processed["$f"]=1
            ;;
        x|X)
            append_exact_path_to_exclude_filters_file "$f"
            ((++files_skipped))
            processed["$f"]=1
            ;;
        a|A)
            echo
            verbose_question_timestamp "Are you sure? [y/N]:"
            echo "⚠️  This will rename ALL remaining files/directories."
            echo -n "Are you sure? [y/N]: "
            flush_stdin
            read_single_key confirm "$PROMPT_WAIT_SECONDS"
            echo

            if [[ "$confirm" =~ [Yy] ]]; then
                rename_all=yes
                vlog "rename_all enabled by user"
                perform_plain_entry_rename "$f" "$new" || break
            else
                ((++files_skipped))
            fi
            ;;
        d|D)
            AUTO_RENAME_DIR="$(dirname -- "$f")"
            vlog "Per-directory auto-yes enabled for '$AUTO_RENAME_DIR'"
            perform_plain_entry_rename "$f" "$new" || break
            ;;
        *)
            print_rename_action_verbose "$f" "$new"
            perform_plain_entry_rename "$f" "$new" || break
            ;;
    esac
done

if [[ "$stopped_by_user" != "yes" ]]; then
    clear_resume_state_file
    check_all_m3u_files
fi
SCRIPT_FINISH_TIME="$(date '+%Y-%m-%d %H:%M:%S')"
print_summary

