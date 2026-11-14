#!/bin/bash
# v. 20261114.164500 - startup: ask per-folder policies (existing set / multi-set / leftovers)
# v. 20261114.163000 - large boxed banner when starting each work directory
# v. 20261114.154500 - rest-of-run for verify/consolidate/anyway/delete-leftover prompts
# v. 20261113.221500 - verify-fail: ask consolidate anyway; *.old collision: ask replace/skip/quit
# v. 20261113.210800 - after create: offer delete leftover other PAR2/hash sets and *.old backups
# v. 20261113.184200 - skip/verify Choice: only default key capitalized ([ S/v/a/e/q ])
# v. 20261113.182200 - skip/verify: any single PAR2 set + single hash (not only _<dir> names)
# v. 20261113.182000 - folder banner: PAR2 stem and hash on separate lines
# v. 20261113.181800 - scope + hash choice: single-key, no Enter
# v. 20261113.181700 - scope prompt default P (per-subdir); only default key capitalized
# v. 20261113.181600 - convention skip/verify menu: one option per line + Choice line
# v. 20261113.181500 - convention PAR2+hash present: skip / verify / skip-rest / verify-rest
# v. 20261113.180800 - [timestamp] logs; per-folder Removed/Created/Elapsed; multi-folder end recap
# v. 20261113.175000 - exclude *.par2.old / *.sha*.old / *.md5.old from PAR2 sources and new hash
# v. 20261113.174500 - multi PAR2/hash: verify then offer consolidate; cleanup *.old default Y
# v. 20261113.173500 - scope: whole tree or one PAR2+hash per immediate subdirectory
# v. 20261113.134300 - par2 create: default -t/-T is nproc-1 when CPUs >= 2
# v. 20261113.134000 - par2 create: pass -t/-T (default nproc) for multi-core OpenMP
# v. 20260922.082714 - recovery percent prompt: q/Q quits instead of falling back to the default
# v. 20260922.082433 - hash menu: drop manual echo of first key; tty already echoes it (showed "11")
# v. 20260916.133341 - Run settings: mark hash/recovery/helpers given vs prompted; add Equivalent CLI
# v. 20260916.130951 - boxed output: draw rules with sed; tr truncated ─ to one invalid byte
# v. 20260812.180711 - Ctrl-C: remove incomplete PAR2/hash temp; restore *.par2.old
# v. 20260812.133413 - hash-only prompt: explain missing hash; default N
# v. 20260812.133230 - existing-PAR2 recreate prompt defaults to N
# v. 20260812.132634 - Y/n single-key; keep hash-only when declining PAR2 recreate
# v. 20260811.095711 - add --history (paged changelog via _script_header.sh print_script_history)
# v. 20260809.170555 - end with boxed RUN SUMMARY / RUN FINISHED like par2-pgm-check
# v. 20260809.170153 - hash menu: q/Q quits immediately (no Enter)
# v. 20260809.165517 - hash menu: detect *sum tools; numbered pick; q quits; re-ask
# v. 20260809.164003 - fix -b: use enough blocks so -r% ≈ data size (not file-count)
# v. 20260809.155541 - prompt to exclude rename.sh helpers from PAR2 (default yes)
# v. 20260806.224414 - initial: create volume-only PAR2 + SHA-512/MD5 hash for cwd subtree

# 2026.11.14 - v. 0.1.31 - At run start (interactive): ask per-folder policies — existing one PAR2+hash (skip/verify/ask), multi-set verify/consolidate-anyway/consolidate (always/never/ask), delete leftovers (always/never/ask); --yes skips these and keeps prior defaults
# 2026.11.14 - v. 0.1.30 - Starting each work directory prints a large boxed NEXT DIRECTORY banner (job N of M in per-subdir mode) so catalog changes stand out
# 2026.11.14 - v. 0.1.29 - Rest-of-run ([ a ]/[ e ]) on: multi-set verify-first, consolidate, consolidate-anyway (verify-fail and skip-verify), and delete-leftover protection
# 2026.11.13 - v. 0.1.28 - If verify fails before consolidate: ask Consolidate anyway / continue / quit (default C). If renaming to *.old but that backup already exists: ask Replace / skip / quit (default R) instead of dying
# 2026.11.13 - v. 0.1.27 - After a successful create/hash: offer to delete superseded leftovers — other active PAR2 sets/hashes (e.g. media-basename) and any *.par2.old / hash *.old (not only after consolidate)
# 2026.11.13 - v. 0.1.26 - Skip/verify menu: only default key capitalized ([ S ] skip); rest-of-run uses [ a ]/[ e ] (not S/V) so Choice is [ S/v/a/e/q ]
# 2026.11.13 - v. 0.1.25 - Skip/verify also when exactly one PAR2 set and one hash exist under any names (e.g. media-basename _file / __file.sha512), not only _<dir> / __<dir>.ext
# 2026.11.13 - v. 0.1.24 - Per-folder banner prints PAR2 stem and hash file on separate lines (not one long | line)
# 2026.11.13 - v. 0.1.23 - Scope and hash-menu prompts accept a single key without Enter (like Y/n); recovery % still needs Enter for multi-digit values
# 2026.11.13 - v. 0.1.22 - Scope prompt defaults to per-subdir [ P ]; only the default key is capitalized ([ w ] / [ P ] / [ q ]); --yes and Enter/timeout/invalid also use per-subdir when subdirs exist
# 2026.11.13 - v. 0.1.21 - Convention skip/verify prompt lists options on separate lines (like rename.sh) then a Choice line
# 2026.11.13 - v. 0.1.20 - If a work dir already has exactly one convention PAR2 set (_<dir>) and one convention hash (__<dir>.ext): ask skip / verify / skip-for-rest / verify-for-rest (default skip); verify OK ends the folder without recreate; --yes skips without verify
# 2026.11.13 - v. 0.1.19 - Status/prompt timestamps use [ YYYY.MM.DD HH:MM:SS ]; after each folder print Removed/Created/Elapsed; if more than one folder, repeat a folders recap at the end
# 2026.11.13 - v. 0.1.18 - Do not treat consolidate backups (*.par2.old, *.sha512.old, *.md5.old, …) as data: exclude them from PAR2 create sources and from the new hash manifest
# 2026.11.13 - v. 0.1.17 - If a work dir has 2+ distinct PAR2 sets and/or 2+ hash manifests: list them, offer verify (default Y); if OK offer consolidate into one volume-only PAR2 + one hash (default Y); then ask to delete the renamed *.old leftovers (default Y). --yes skips this offer (keeps existing multi sets)
# 2026.11.13 - v. 0.1.16 - If cwd has immediate subdirectories: ask whole-tree (one PAR2+hash here) vs per-subdir (one PAR2+hash in each direct child for that child's full subtree; loose files in cwd ignored). --scope whole|per-subdir; --yes defaults to per-subdir when subdirs exist
# 2026.11.13 - v. 0.1.15 - Default par2 -t/-T is nproc-1 when CPUs >= 2 (leave one core free); still 1 on single-CPU hosts
# 2026.11.13 - v. 0.1.14 - par2 create uses all CPUs by default: -t (Reed-Solomon) and -T (parallel file hashing) from nproc; override with --threads / --file-threads or PAR2_THREADS / PAR2_FILE_THREADS
# 2026.09.22 - v. 0.1.13 - Recovery percent prompt accepts q/Q to quit (advertised in the prompt); previously q was just an invalid percent and the run continued with the default
# 2026.09.22 - v. 0.1.12 - Hash menu echoed the typed digit twice ("11" for 1): read -n 1 leaves terminal ECHO on (only read -s turns it off), so the extra printf of the first key was redundant
# 2026.09.16 - v. 0.1.11 - === Run settings ===: report --hash / --recovery / rename-helper choices as given, --yes default, or prompted (with the selected value), show the effective PROMPT_TIMEOUT, and add an "Equivalent CLI:" line that repeats the run non-interactively
# 2026.09.16 - v. 0.1.10 - Boxed summaries: horizontal rules via sed 's/ /─/g'; tr is byte-wise and cut the 3-byte ─ (U+2500) down to a lone 0xE2, printing invalid UTF-8
# 2026.08.12 - v. 0.1.9 - Ctrl-C removes incomplete PAR2/hash temp and restores *.par2.old
# 2026.08.12 - v. 0.1.8 - Hash-only offer explains PAR2-without-hash; default N
# 2026.08.12 - v. 0.1.7 - Existing-PAR2 recreate prompt defaults to N (keep set; offer hash-only)
# 2026.08.12 - v. 0.1.6 - Y/n prompts are single-key; N on existing PAR2 still offers hash-only
# 2026.08.09 - v. 0.1.5 - Boxed RUN SUMMARY / RUN FINISHED at end (like par2-pgm-check)
# 2026.08.09 - v. 0.1.4 - Hash menu: q/Q quits on keypress (no Enter required)
# 2026.08.09 - v. 0.1.3 - Detect system *sum tools; numbered hash menu (q=quit, invalid=retry)
# 2026.08.09 - v. 0.1.2 - Fix PAR2 -b: floor at 2000 / aim ~1MiB blocks (avoid huge recovery)
# 2026.08.09 - v. 0.1.1 - Ask to exclude rename.sh helper files from PAR2 (default yes); still hash them
# 2026.08.06 - v. 0.1.0 - initial release: _<dir>.par2 volume set + __<dir>.sha512|md5 for whole subtree
#
# par2-hash-pgm-create.sh
#
# Create a PAR2 archive and a hash file for the current directory tree.
#

show_help() {
  cat <<EOF
Usage: $(script_live_basename) [-h|--help] [-v|--version] [--no_startup_delay] [options]

Create a volume-only PAR2 set and a hash manifest.

Naming (from the work directory basename, e.g. .../MyAlbum):
  PAR2 stem:  _MyAlbum.par2  (volume-only: _MyAlbum.vol….par2; index removed)
  Hash file:  __MyAlbum.<ext>  (ext from chosen hash, e.g. .sha512 / .md5 / .b2)

Scope (when the current directory has immediate subdirectories):
  Whole tree (default): one PAR2 + hash in cwd covering cwd and all depths.
  Per subdirectory: for each direct child only, one PAR2 + hash inside that
  child covering that child's full subtree. Files that sit only in cwd are
  ignored in this mode.

Order (per work directory):
  1) Create PAR2 for all non-empty data files under the tree
     (excludes *.par2 / backups and hash manifests).
     Optionally excludes rename.sh helper files (prompt; default yes).
  2) Write the hash file for every regular file in the tree, including the new
     PAR2 volume(s), excluding the hash file being written.
     (rename.sh helpers are still hashed even when excluded from PAR2.)

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --history            Print script changelog from the header and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
  --hash ALG           Prefer ALG (sha512|sha384|sha256|sha224|sha1|md5|b2).
  --sha512             Prefer SHA-512 (default when available).
  --sha256             Prefer SHA-256.
  --md5                Prefer MD5.
  --recovery N         Recovery percent 1-100 (skips the recovery prompt).
  --exclude-rename-helpers
                       Exclude rename.sh helper files from PAR2 (no prompt).
  --include-rename-helpers
                       Include rename.sh helper files in PAR2 (no prompt).
  --yes, -y            Accept prompt defaults (hash algo, recovery, exclude
                       rename helpers = yes) without asking.
  -n, --dry-run        Show what would be done; create nothing.
  --threads N          par2 -t N (Reed-Solomon / main processing threads).
                       Default: nproc-1 when CPUs >= 2, else 1.
  --file-threads N     par2 -T N (files hashed in parallel during create).
                       Default: same as --threads; capped at source file count.
  --scope whole|per-subdir
                       Creation scope when cwd has immediate subdirectories.
                       per-subdir = one PAR2+hash in each direct child
                       (default with --yes when subdirs exist).
                       whole = one PAR2+hash in cwd.

Interactive prompts (unless --yes / flag already set):
  Scope:          If cwd has subdirs: [ w ] / [ P ] / [ q ] — single key, no Enter
                  (default P). Skipped when there are no immediate subdirs.
  Hash algorithm: numbered list of *sum tools on PATH; digit 1-N or Enter =
                  default; q = quit — single key, no Enter; invalid asks again.
  Recovery %:     Type 1-100 then Enter (Enter alone = 20% or --recovery value);
                  q + Enter quits. Multi-digit needs Enter.
  Rename helpers: Exclude from PAR2? [Y/n/q] — single key, no Enter (default yes).
  Run policies:   After scope (interactive): set per-folder defaults for this run —
                  existing one PAR2+hash [ S ]kip / [ v ]erify / [ A ]sk (default A);
                  multi-set verify / consolidate-anyway / consolidate each
                  [ Y ] always / [ n ] never / [ A ]sk (default A);
                  delete leftovers [ Y ]/[ n ]/[ A ] (default A). --yes skips.
  Existing set:   If not preset: one PAR2 + one hash → [ S ]/[ v ]/[ a ]/[ e ]/[ q ]
                  (default S; rest-of-run a/e). --yes skips without verifying.
  Multi-set:      If not preset: verify-first / consolidate / consolidate-anyway
                  menus include [ a ]/[ e ] rest-of-run.
  Leftovers:      If not preset: delete other PAR2/hash / *.old? [ Y/n/a/e/q ].
  Existing PAR2:  Rename to *.par2.old and recreate? [y/N/q] — single key
                  (default N = keep PAR2). If kept and no hash file exists,
                  offers to create one [y/N/q] (default N).
  Existing hash:  Overwrite? [Y/n/q] — single key (default yes).

Environment:
  PAR2_CMD             par2 executable (default: par2)
  PAR2_THREADS         Same as --threads (default: nproc-1 if CPUs >= 2, else 1)
  PAR2_FILE_THREADS    Same as --file-threads (same default)
  PROMPT_TIMEOUT       Seconds to wait for interactive prompts (unset = no timeout)

Examples:
  cd /path/to/MyAlbum && $(script_live_basename)
  $(script_live_basename) --hash sha256 --recovery 10
  $(script_live_basename) --md5 --yes
  $(script_live_basename) --threads 8 --file-threads 4
  $(script_live_basename) --scope per-subdir --hash md5 --yes
  $(script_live_basename) --include-rename-helpers
  $(script_live_basename) -n
EOF
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. "${profile_location_dir:-$HOME}/bin/_script_header.sh" "${HEADER_EXTRA_ARGS[@]}"

PAR2_CMD="${PAR2_CMD:-par2}"
PROMPT_TIMEOUT="${PROMPT_TIMEOUT-}"
HASH_PREF=""
# Parallel arrays filled by discover_hash_tools (id, label, cmd, ext).
HASH_IDS=()
HASH_LABELS=()
HASH_CMDS=()
HASH_EXTS=()
RECOVERY_CLI=""
AUTO_YES=0
DRY_RUN=0
# Empty = resolve later to nproc-1 (if CPUs >= 2); CLI sets these when flags given.
THREADS_CLI=""
FILE_THREADS_CLI=""
PAR2_THREADS="${PAR2_THREADS:-}"
PAR2_FILE_THREADS="${PAR2_FILE_THREADS:-}"
SCOPE_CLI=""
# whole | per-subdir (set after resolve_create_scope)
CREATE_SCOPE=""
CREATE_SCOPE_SOURCE=""
START_DIR=""
MULTI_JOB_MODE=0
MULTI_JOB_TOTAL=0
MULTI_JOB_OK=0
MULTI_JOB_SKIP=0
MULTI_JOB_FAIL=0
MULTI_FOLDER_RECAPS=()
CONSOLIDATE_DONE=0
# empty | skip | verify — remember choice for later convention-protected folders
EXISTING_PROTECTION_POLICY=""
# empty | yes | no — rest-of-run policies for multi-set / cleanup prompts
VERIFY_MULTI_POLICY=""
CONSOLIDATE_POLICY=""
CONSOLIDATE_ANYWAY_POLICY=""
DELETE_LEFTOVER_POLICY=""
JOB_START_EPOCH=0
JOB_BACKED_UP_COUNT=0
JOB_DELETED_COUNT=0
JOB_CREATED_COUNT=0
JOB_OUTCOME=""
# -1 = ask (default yes); 1 = exclude; 0 = include
EXCLUDE_RENAME_HELPERS_CLI=-1
EXCLUDE_RENAME_HELPERS=1
MAX_PAR2_BLOCKS=32768
# par2cmdline default block count; also the floor when file count is lower.
# Using -b == file count with few huge files makes each block ≈ largest file,
# so -r20% recovery becomes (0.2 * N) * largest_file (can be >> source total).
MIN_PAR2_BLOCKS=2000
# Prefer roughly 1 MiB source blocks when data size allows (capped at MAX).
TARGET_PAR2_BLOCK_BYTES=$((1024 * 1024))
return_code=0

WORK_DIR=""
DIR_NAME=""
PAR2_STEM=""
HASH_ALGO=""
HASH_EXT=""
HASH_CMD=""
HASH_FILE=""
HASH_LABEL=""
RECOVERY_PCT=20
SCRIPT_START_STR=""
SCRIPT_START_EPOCH=0
RENAME_HELPERS_FOUND=()
CREATED_PAR2_VOLS=()
PAR2_SOURCE_COUNT=0
PAR2_SOURCE_BYTES=0
HASH_ENTRY_COUNT=0
SUMMARY_PRINTED=0
# ok | quit | error — controls end banner wording
RUN_OUTCOME=""
# 1 = create/replace PAR2; 0 = skip PAR2 create (hash-only)
CREATE_PAR2=1
# Interrupt cleanup: incomplete outputs from this run only.
PAR2_CREATE_IN_PROGRESS=0
HASH_TEMP=""
# Absolute paths of *.par2.old we created; restore on interrupt until create succeeds.
CLEANUP_RESTORE_OLDPATHS=()

PGM_HAVE_BOXES=no
if command -v boxes >/dev/null 2>&1; then
  PGM_HAVE_BOXES=yes
fi

# Remove incomplete stem outputs (index + volumes) written during this create.
# Echoes each removed basename; returns count via CLEANUP_REMOVED_COUNT.
cleanup_remove_new_par2_outputs() {
  local f
  CLEANUP_REMOVED_COUNT=0
  [[ -n "${WORK_DIR:-}" && -n "${PAR2_STEM:-}" ]] || return 0
  shopt -s nullglob
  for f in \
    "${WORK_DIR}/${PAR2_STEM}.par2" \
    "${WORK_DIR}/${PAR2_STEM}".vol*.par2 \
    "${WORK_DIR}/${PAR2_STEM}.PAR2" \
    "${WORK_DIR}/${PAR2_STEM}".vol*.PAR2
  do
    [[ -e "$f" ]] || continue
    if rm -f -- "$f"; then
      printf '  removed: %s\n' "$(basename -- "$f")"
      CLEANUP_REMOVED_COUNT=$((CLEANUP_REMOVED_COUNT + 1))
    fi
  done
  shopt -u nullglob
  return 0
}

# Restore PAR2 members we renamed to *.par2.old before a recreate.
cleanup_restore_par2_backups() {
  local old_path active
  CLEANUP_RESTORED_COUNT=0
  for old_path in "${CLEANUP_RESTORE_OLDPATHS[@]+"${CLEANUP_RESTORE_OLDPATHS[@]}"}"; do
    [[ -n "$old_path" && -e "$old_path" ]] || continue
    active="${old_path%.old}"
    if [[ -e "$active" ]]; then
      rm -f -- "$active" || true
    fi
    if mv -- "$old_path" "$active"; then
      printf '  restored: %s (from %s)\n' "$(basename -- "$active")" "$(basename -- "$old_path")"
      CLEANUP_RESTORED_COUNT=$((CLEANUP_RESTORED_COUNT + 1))
    fi
  done
  CLEANUP_RESTORE_OLDPATHS=()
  return 0
}

cleanup_hash_temp() {
  if [[ -n "${HASH_TEMP:-}" && -e "$HASH_TEMP" ]]; then
    rm -f -- "$HASH_TEMP" || true
    printf '  removed temp: %s\n' "$HASH_TEMP"
    HASH_TEMP=""
    return 0
  fi
  HASH_TEMP=""
  return 1
}

cleanup_on_interrupt() {
  local did=0
  CLEANUP_REMOVED_COUNT=0
  CLEANUP_RESTORED_COUNT=0
  echo "Cleaning up files created by this run..."

  if cleanup_hash_temp; then
    did=1
  fi

  # Incomplete PAR2 (create in progress) or recreate: remove new stem files, then restore backups.
  if (( PAR2_CREATE_IN_PROGRESS == 1 )) || ((${#CLEANUP_RESTORE_OLDPATHS[@]} > 0)); then
    cleanup_remove_new_par2_outputs
    (( CLEANUP_REMOVED_COUNT > 0 )) && did=1
  fi
  if ((${#CLEANUP_RESTORE_OLDPATHS[@]} > 0)); then
    cleanup_restore_par2_backups
    (( CLEANUP_RESTORED_COUNT > 0 )) && did=1
  fi

  PAR2_CREATE_IN_PROGRESS=0

  if (( did == 0 )); then
    echo "  (nothing to clean up)"
  else
    echo "  Cleanup finished."
  fi
}

# Override header's ctrl_c so INT actually removes incomplete outputs.
ctrl_c() {
  echo
  echo "** Trapped CTRL-C - cleaning up...."
  cleanup_on_interrupt
  echo
  if [ -n "${STY:-}" ]; then
    echo -ne "${tcScrTitleStart}${CALLER_SCRIPT_BASENAME}${tcScrTitleEnd}"
  fi
  exit 130
}
trap ctrl_c INT

die() {
  echo "Error: $*" >&2
  return_code=1
  RUN_OUTCOME=error
  print_run_finished_banner
  . "${profile_location_dir:-$HOME}/bin/_script_footer.sh"
  exit 1
}

finish() {
  local rc="${return_code:-0}"
  [[ -n "$RUN_OUTCOME" ]] || {
    if (( rc == 0 )); then
      RUN_OUTCOME=ok
    else
      RUN_OUTCOME=error
    fi
  }
  print_run_finished_banner
  . "${profile_location_dir:-$HOME}/bin/_script_footer.sh"
  exit "$rc"
}

emit_unicode_box() {
  local -a lines=( "$@" )
  local max_len=0 line w

  for line in "${lines[@]}"; do
    (( ${#line} > max_len )) && max_len=${#line}
  done
  (( max_len < 52 )) && max_len=52
  w=$(( max_len + 2 ))

  printf '┌%*s┐\n' "$w" '' | sed 's/ /─/g'
  for line in "${lines[@]}"; do
    printf '│ %-*s │\n' "$max_len" "$line"
  done
  printf '└%*s┘\n' "$w" '' | sed 's/ /─/g'
}

emit_boxed_block() {
  local design="$1"
  shift
  local -a lines=( "$@" )

  if [[ "$PGM_HAVE_BOXES" == yes ]]; then
    printf '%s\n' "${lines[@]}" | boxes -a c -d "$design"
  else
    emit_unicode_box "${lines[@]}"
  fi
}

print_run_summary() {
  local finished_str elapsed_human vol="" hash_entries_word="entries"
  local -a lines=()

  (( SUMMARY_PRINTED == 0 )) || return 0
  SUMMARY_PRINTED=1

  finished_str="$(date '+%Y.%m.%d %H:%M:%S')"
  elapsed_human="$(format_elapsed "$(( $(date +%s) - SCRIPT_START_EPOCH ))")"
  (( HASH_ENTRY_COUNT == 1 )) && hash_entries_word="entry"

  lines+=( "*** RUN SUMMARY ***" )
  if (( DRY_RUN == 1 )); then
    lines+=( "Mode: dry-run (nothing written)" )
  elif (( CREATE_PAR2 == 0 )); then
    lines+=( "Mode: hash-only (existing PAR2 left unchanged)" )
  else
    lines+=( "Mode: created PAR2 + hash manifest" )
  fi
  lines+=( "Directory: $WORK_DIR" )
  if (( CREATE_PAR2 == 1 )); then
    lines+=( "PAR2 stem: ${PAR2_STEM}.par2 (volume-only, -r${RECOVERY_PCT}%)" )
    if ((${#CREATED_PAR2_VOLS[@]} > 0)); then
      for vol in "${CREATED_PAR2_VOLS[@]}"; do
        lines+=( "PAR2 file: $vol" )
      done
    else
      lines+=( "PAR2 file: ${PAR2_STEM}.vol*.par2" )
    fi
    lines+=( "Protected: ${PAR2_SOURCE_COUNT} file(s), $(format_bytes_approx "$PAR2_SOURCE_BYTES")" )
  else
    lines+=( "PAR2: left existing set unchanged (${PAR2_STEM}*)" )
  fi
  if [[ -n "${HASH_FILE:-}" ]]; then
    lines+=( "Hash file: $(basename -- "$HASH_FILE") (${HASH_LABEL:-$HASH_ALGO}, ${HASH_ENTRY_COUNT} ${hash_entries_word})" )
  fi
  if (( EXCLUDE_RENAME_HELPERS == 1 && ${#RENAME_HELPERS_FOUND[@]} > 0 )); then
    lines+=( "Rename helpers excluded from PAR2: ${#RENAME_HELPERS_FOUND[@]}" )
  fi
  lines+=( "Started:  $SCRIPT_START_STR" )
  lines+=( "Finished: $finished_str" )
  lines+=( "Elapsed:  $elapsed_human" )

  echo
  emit_boxed_block ada-box "${lines[@]}"
  echo
}

print_run_finished_banner() {
  local rc="${return_code:-0}"
  local -a lines=()

  case "${RUN_OUTCOME:-}" in
    quit)
      lines+=( "*** RUN FINISHED: QUIT (exit $rc) ***" )
      lines+=( "Stopped at user request (q)." )
      ;;
    ok)
      print_run_summary
      lines+=( "*** RUN FINISHED: OK (exit $rc) ***" )
      if (( DRY_RUN == 1 )); then
        lines+=( "Dry-run completed; no files were written." )
      elif (( CREATE_PAR2 == 0 )); then
        lines+=( "Hash file created; existing PAR2 left unchanged." )
      else
        lines+=( "PAR2 archive and hash file are ready." )
      fi
      ;;
    *)
      lines+=( "*** RUN FINISHED: PROBLEM (exit $rc) ***" )
      lines+=( "Stopped with an error (see messages above)." )
      ;;
  esac
  lines+=( "Normal exit - the shell prompt returning means the script completed." )

  echo
  case "${RUN_OUTCOME:-}" in
    ok) emit_boxed_block ada-box "${lines[@]}" ;;
    *)  emit_boxed_block stone "${lines[@]}" ;;
  esac
  echo
}

wall_clock_now() {
  date '+%Y.%m.%d %H:%M:%S'
}

user_prompt_ts_prefix() {
  printf '[ %s ] ' "$(wall_clock_now)"
}

# Timestamped status line (prompts use user_prompt_ts_prefix; raw par2 output is left alone).
log_msg() {
  printf '[ %s ] %s\n' "$(wall_clock_now)" "$*"
}

reset_job_counters() {
  JOB_START_EPOCH=$(date +%s)
  JOB_BACKED_UP_COUNT=0
  JOB_DELETED_COUNT=0
  JOB_CREATED_COUNT=0
  JOB_OUTCOME=""
}

print_folder_done_summary() {
  local elapsed outcome_note="" removed_n=0 removed_note="" created_note=""
  local recap=""

  elapsed="$(format_elapsed "$(( $(date +%s) - JOB_START_EPOCH ))")"
  outcome_note="${JOB_OUTCOME:-done}"

  if (( JOB_DELETED_COUNT > 0 )); then
    removed_n=$JOB_DELETED_COUNT
    removed_note="old backup(s) deleted"
  elif (( JOB_BACKED_UP_COUNT > 0 )); then
    removed_n=$JOB_BACKED_UP_COUNT
    removed_note="renamed to *.old (kept on disk)"
  else
    removed_n=0
    removed_note="none"
  fi

  if (( JOB_CREATED_COUNT > 0 )); then
    created_note="${JOB_CREATED_COUNT} file(s)"
    if (( CREATE_PAR2 == 1 && ${#CREATED_PAR2_VOLS[@]} > 0 )); then
      created_note+=" (PAR2: ${CREATED_PAR2_VOLS[*]}"
      if [[ -n "${HASH_FILE:-}" && -e "${HASH_FILE:-}" ]]; then
        created_note+="; hash: $(basename -- "$HASH_FILE")"
      fi
      created_note+=")"
    elif [[ -n "${HASH_FILE:-}" && $HASH_ENTRY_COUNT -gt 0 ]]; then
      created_note+=" (hash: $(basename -- "$HASH_FILE"), ${HASH_ENTRY_COUNT} line(s))"
    fi
  else
    created_note="0 file(s)"
  fi

  log_msg "=== Folder done: ${DIR_NAME} (${outcome_note}) ==="
  log_msg "Removed: ${removed_n} file(s) (${removed_note})"
  log_msg "Created: ${created_note}"
  log_msg "Elapsed (this folder): ${elapsed}"

  recap="${DIR_NAME}: removed ${removed_n}, created ${JOB_CREATED_COUNT}, elapsed ${elapsed} [ ${outcome_note} ]"
  MULTI_FOLDER_RECAPS+=("$recap")
}

prompt_has_timeout() {
  [[ -n "${PROMPT_TIMEOUT:-}" && "${PROMPT_TIMEOUT}" =~ ^[1-9][0-9]*$ ]]
}

prompt_timeout_label() {
  if prompt_has_timeout; then
    printf '%ss timeout' "$PROMPT_TIMEOUT"
  else
    printf '%s' 'no timeout'
  fi
}

read_line_with_timeout() {
  local __var="$1"
  if prompt_has_timeout; then
    IFS= read -r -t "$PROMPT_TIMEOUT" "$__var"
  else
    IFS= read -r "$__var"
  fi
}

# Single-key hash menu choice (no Enter). Enter = default (empty).
# Sets __var to "" (default), 1-9, or q. Returns: 0 ok, 1 timeout→default, 2 quit.
read_hash_choice_with_timeout() {
  local __var="$1"
  local first=""

  while true; do
    if prompt_has_timeout; then
      IFS= read -r -t "$PROMPT_TIMEOUT" -n 1 first || {
        echo
        printf -v "$__var" '%s' ""
        return 1
      }
    else
      IFS= read -r -n 1 first || {
        echo
        printf -v "$__var" '%s' ""
        return 1
      }
    fi

    case "$first" in
      ""|$'\n')
        printf -v "$__var" '%s' ""
        return 0
        ;;
      q|Q)
        echo
        printf -v "$__var" '%s' q
        return 2
        ;;
      [1-9])
        echo
        printf -v "$__var" '%s' "$first"
        return 0
        ;;
      *)
        echo
        printf '%sInvalid key "%s". Press 1-9, q, or Enter for default: ' \
          "$(user_prompt_ts_prefix)" "$first"
        ;;
    esac
  done
}

# Single-key Y/n/q (no Enter). Enter uses default (y or n).
# Sets __var to y|n|q. Returns 0=answer, 1=timeout→default, 2=quit.
read_yn_key_with_timeout() {
  local __var="$1"
  local default="${2:-y}"
  local first=""

  [[ "$default" == y || "$default" == n ]] || default=y

  while true; do
    if prompt_has_timeout; then
      IFS= read -r -t "$PROMPT_TIMEOUT" -n 1 first || {
        echo
        printf -v "$__var" '%s' "$default"
        return 1
      }
    else
      IFS= read -r -n 1 first || {
        echo
        printf -v "$__var" '%s' "$default"
        return 1
      }
    fi

    case "$first" in
      ""|$'\n')
        printf -v "$__var" '%s' "$default"
        return 0
        ;;
      y|Y)
        echo
        printf -v "$__var" '%s' y
        return 0
        ;;
      n|N)
        echo
        printf -v "$__var" '%s' n
        return 0
        ;;
      q|Q)
        echo
        printf -v "$__var" '%s' q
        return 2
        ;;
      *)
        echo
        printf '%sInvalid key "%s". Press Y, N, Q, or Enter for default (%s): ' \
          "$(user_prompt_ts_prefix)" "$first" "${default^^}"
        ;;
    esac
  done
}

# Single-key S/v/a/e/q for existing protection (only default key shown uppercase).
# Sets __var to skip|verify|skip_rest|verify_rest|q.
# Returns: 0=answer, 1=timeout→default, 2=quit.
# default: skip|verify (Enter).
read_skip_verify_key_with_timeout() {
  local __var="$1"
  local default="${2:-skip}"
  local first=""

  case "$default" in
    skip|verify) ;;
    *) default=skip ;;
  esac

  while true; do
    if prompt_has_timeout; then
      IFS= read -r -t "$PROMPT_TIMEOUT" -n 1 first || {
        echo
        printf -v "$__var" '%s' "$default"
        return 1
      }
    else
      IFS= read -r -n 1 first || {
        echo
        printf -v "$__var" '%s' "$default"
        return 1
      }
    fi

    case "$first" in
      ""|$'\n')
        printf -v "$__var" '%s' "$default"
        return 0
        ;;
      s|S)
        echo
        printf -v "$__var" '%s' skip
        return 0
        ;;
      v|V)
        echo
        printf -v "$__var" '%s' verify
        return 0
        ;;
      a|A)
        echo
        printf -v "$__var" '%s' skip_rest
        return 0
        ;;
      e|E)
        echo
        printf -v "$__var" '%s' verify_rest
        return 0
        ;;
      q|Q)
        echo
        printf -v "$__var" '%s' q
        return 2
        ;;
      *)
        echo
        printf '%sInvalid key "%s". Press S, v, a, e, q, or Enter for default (%s): ' \
          "$(user_prompt_ts_prefix)" "$first" "$default"
        ;;
    esac
  done
}

# Single-key yes/no with optional rest-of-run (a=yes rest, e=no rest).
# Caller prints the menu lines. yes_key is the letter for "yes" (y or c).
# default_ans: yes|no. Sets __var to yes|no. Returns 0=ok, 1=timeout→default, 2=quit.
# If policy_var_name is non-empty and user picks a/e, that global is set to yes|no.
read_yes_no_rest_key_with_timeout() {
  local __var="$1"
  local default_ans="${2:-yes}"
  local yes_key="${3:-y}"
  local policy_var_name="${4:-}"
  local first="" yes_l no_disp choice_hint def_disp

  case "$default_ans" in
    yes|no) ;;
    *) default_ans=yes ;;
  esac
  yes_key="${yes_key:0:1}"
  yes_l="${yes_key,,}"
  if [[ "$default_ans" == yes ]]; then
    def_disp="${yes_l^^}"
    no_disp=n
    choice_hint="[ ${def_disp}/n/a/e/q ]"
  else
    def_disp=N
    no_disp=n
    choice_hint="[ ${yes_l}/${def_disp}/a/e/q ]"
  fi

  while true; do
    if prompt_has_timeout; then
      IFS= read -r -t "$PROMPT_TIMEOUT" -n 1 first || {
        echo
        printf -v "$__var" '%s' "$default_ans"
        return 1
      }
    else
      IFS= read -r -n 1 first || {
        echo
        printf -v "$__var" '%s' "$default_ans"
        return 1
      }
    fi

    case "$first" in
      ""|$'\n')
        printf -v "$__var" '%s' "$default_ans"
        return 0
        ;;
      q|Q)
        echo
        printf -v "$__var" '%s' quit
        return 2
        ;;
      a|A)
        echo
        printf -v "$__var" '%s' yes
        if [[ -n "$policy_var_name" ]]; then
          printf -v "$policy_var_name" '%s' yes
          log_msg "Will use yes for this prompt for the rest of the run."
        fi
        return 0
        ;;
      e|E)
        echo
        printf -v "$__var" '%s' no
        if [[ -n "$policy_var_name" ]]; then
          printf -v "$policy_var_name" '%s' no
          log_msg "Will use no for this prompt for the rest of the run."
        fi
        return 0
        ;;
      n|N)
        echo
        printf -v "$__var" '%s' no
        return 0
        ;;
      *)
        if [[ "${first,,}" == "$yes_l" ]]; then
          echo
          printf -v "$__var" '%s' yes
          return 0
        fi
        echo
        printf '%sInvalid key "%s". Press keys from %s or Enter for default (%s): ' \
          "$(user_prompt_ts_prefix)" "$first" "$choice_hint" "$def_disp"
        ;;
    esac
  done
}

# Apply remembered yes|no policy. Sets __var; returns 0 if policy set, 1 if empty.
apply_yes_no_policy() {
  local __var="$1"
  local policy="$2"
  local label="${3:-this prompt}"

  case "$policy" in
    yes|no)
      printf -v "$__var" '%s' "$policy"
      log_msg "Using remembered choice for ${label}: ${policy}."
      return 0
      ;;
  esac
  return 1
}

is_par2_backup_basename() {
  local base="$1"
  case "$base" in
    *_old.par2|*_old.PAR2) return 0 ;;
    *.par2.old|*.PAR2.old|*.par2.OLD|*.PAR2.OLD) return 0 ;;
  esac
  return 1
}

# Hash/PAR2 sidecars renamed aside (e.g. during consolidate) — not data to protect.
is_protection_backup_basename() {
  local base="$1"
  is_par2_backup_basename "$base" && return 0
  case "${base,,}" in
    *.sha512.old|*.sha384.old|*.sha256.old|*.sha224.old|*.sha1.old|*.md5.old|*.b2.old) return 0 ;;
  esac
  return 1
}

is_par2_basename() {
  local base="$1"
  [[ "$base" == *.par2 || "$base" == *.PAR2 ]] || return 1
  is_par2_backup_basename "$base" && return 1
  return 0
}

is_hash_manifest_basename() {
  local base="$1"
  case "${base,,}" in
    *.sha512|*.sha384|*.sha256|*.sha224|*.sha1|*.md5|*.b2) return 0 ;;
  esac
  return 1
}

# rename.sh sidecar / helper files (matched by basename anywhere in the tree).
is_rename_helper_basename() {
  local base="$1"
  case "$base" in
    _exclude-rename.sh.txt)
      return 0
      ;;
    _rename.sh.resume-state.json|rename.sh.resume-state.json)
      return 0
      ;;
    _rename.sh-optional-db.sqlite3|rename.sh-optional-db.sqlite3|\
    _rename.sh-optional-db.sqlite3-wal|rename.sh-optional-db.sqlite3-wal|\
    _rename.sh-optional-db.sqlite3-shm|rename.sh-optional-db.sqlite3-shm|\
    _rename.sh-optional-db.sqlite3-journal|rename.sh-optional-db.sqlite3-journal)
      return 0
      ;;
  esac
  return 1
}

# Files protected by the new PAR2 set (excludes PAR2 archives, hash manifests, *.old backups).
is_par2_source_basename() {
  local base="$1"
  case "$base" in
    *.par2|*.PAR2) return 1 ;;
    *_old.par2|*_old.PAR2) return 1 ;;
    *.par2.old|*.PAR2.old|*.par2.OLD|*.PAR2.OLD) return 1 ;;
  esac
  is_protection_backup_basename "$base" && return 1
  is_hash_manifest_basename "$base" && return 1
  if (( EXCLUDE_RENAME_HELPERS == 1 )) && is_rename_helper_basename "$base"; then
    return 1
  fi
  return 0
}

relpath_from_root() {
  local abs="$1"
  local root="$2"
  if [[ "$abs" == "$root"/* ]]; then
    printf '%s\n' "${abs#"$root"/}"
  else
    printf '%s\n' "$(basename -- "$abs")"
  fi
}

collect_sorted_relpaths() {
  local root="$1"
  local mode="$2" # par2-sources | hash-all
  local -n _out=$3
  local f base rel exclude_hash=""
  local -a found=()

  _out=()
  exclude_hash="${4:-}"

  while IFS= read -r -d '' f; do
    [[ -f "$f" ]] || continue
    base="$(basename -- "$f")"
    rel="$(relpath_from_root "$f" "$root")"

    if [[ -n "$exclude_hash" && "$rel" == "$exclude_hash" ]]; then
      continue
    fi

    case "$mode" in
      par2-sources)
        is_par2_source_basename "$base" || continue
        [[ -s "$f" ]] || continue
        ;;
      hash-all)
        # Do not list consolidate/recreate backups in the new manifest.
        is_protection_backup_basename "$base" && continue
        ;;
      *)
        die "Internal error: unknown collect mode: $mode"
        ;;
    esac
    found+=("$rel")
  done < <(find "$root" -type f -print0 2>/dev/null)

  if ((${#found[@]} > 1)); then
    IFS=$'\n' found=($(printf '%s\n' "${found[@]}" | LC_ALL=C sort -f))
    unset IFS
  fi
  _out=("${found[@]}")
}

list_existing_stem_par2() {
  local root="$1"
  local stem="$2"
  local -n _out=$3
  local f base

  _out=()
  shopt -s nullglob
  for f in "$root/${stem}.par2" "$root/${stem}".vol*.par2 \
           "$root/${stem}.PAR2" "$root/${stem}".vol*.PAR2; do
    [[ -f "$f" ]] || continue
    base="$(basename -- "$f")"
    is_par2_backup_basename "$base" && continue
    _out+=("$f")
  done
  shopt -u nullglob
}

# Stem used to group index + volume files into one PAR2 set.
par2_stem_from_basename() {
  local base="$1"

  is_par2_basename "$base" || return 1
  base="${base%.par2}"
  base="${base%.PAR2}"
  if [[ "$base" =~ ^(.*)\.vol[0-9]*[-+_][0-9]+$ ]]; then
    base="${BASH_REMATCH[1]}"
  fi
  printf '%s' "$base"
}

# Unique PAR2 set stems in root (non-recursive). Fills name-ref with stem strings.
list_par2_set_stems_in_dir() {
  local root="$1"
  local -n _out=$2
  local f base stem
  local -A seen=()

  _out=()
  shopt -s nullglob
  for f in "$root"/*.par2 "$root"/*.PAR2; do
    [[ -f "$f" ]] || continue
    base="$(basename -- "$f")"
    is_par2_basename "$base" || continue
    stem="$(par2_stem_from_basename "$base")" || continue
    [[ -n "$stem" ]] || continue
    [[ -n "${seen[${stem,,}]:-}" ]] && continue
    seen["${stem,,}"]=1
    _out+=("$stem")
  done
  shopt -u nullglob
  if ((${#_out[@]} > 1)); then
    IFS=$'\n' _out=($(printf '%s\n' "${_out[@]}" | LC_ALL=C sort -f))
    unset IFS
  fi
}

# Hash manifests in root (non-recursive).
list_hash_manifests_in_dir() {
  local root="$1"
  local -n _out=$2
  local f base

  _out=()
  shopt -s nullglob
  for f in "$root"/*; do
    [[ -f "$f" ]] || continue
    base="$(basename -- "$f")"
    is_hash_manifest_basename "$base" || continue
    case "$base" in
      *.old|*.OLD|*_old.*) continue ;;
    esac
    _out+=("$f")
  done
  shopt -u nullglob
  if ((${#_out[@]} > 1)); then
    IFS=$'\n' _out=($(printf '%s\n' "${_out[@]}" | LC_ALL=C sort -f))
    unset IFS
  fi
}

hash_verify_cmd_for_file() {
  local base="$1"
  case "${base,,}" in
    *.sha512) printf 'sha512sum' ;;
    *.sha384) printf 'sha384sum' ;;
    *.sha256) printf 'sha256sum' ;;
    *.sha224) printf 'sha224sum' ;;
    *.sha1)   printf 'sha1sum' ;;
    *.md5)    printf 'md5sum' ;;
    *.b2)     printf 'b2sum' ;;
    *)        return 1 ;;
  esac
}

# Verify every PAR2 set and every hash manifest in WORK_DIR. Returns 0 if all OK.
verify_dir_par2_and_hashes() {
  local -a stems=() hashes=() members=()
  local stem f base cmd rc=0 any=0 verify_rc=0

  list_par2_set_stems_in_dir "$WORK_DIR" stems
  list_hash_manifests_in_dir "$WORK_DIR" hashes

  echo "=== Verify existing PAR2 set(s) and hash manifest(s) ==="
  for stem in "${stems[@]}"; do
    members=()
    list_existing_stem_par2 "$WORK_DIR" "$stem" members
    ((${#members[@]} > 0)) || continue
    any=1
    f="${members[0]}"
    # Prefer an index if present; else first volume.
    for base in "${members[@]}"; do
      if [[ "$(basename -- "$base")" == "${stem}.par2" || "$(basename -- "$base")" == "${stem}.PAR2" ]]; then
        f="$base"
        break
      fi
    done
    echo "PAR2 verify: $(basename -- "$f") (set ${stem})"
    (
      cd "$WORK_DIR" || exit 1
      "$PAR2_CMD" verify "$(basename -- "$f")"
    )
    verify_rc=$?
    if (( verify_rc != 0 )); then
      echo "PAR2 verify FAILED for set ${stem} (exit ${verify_rc})." >&2
      rc=1
    else
      echo "PAR2 verify OK: ${stem}"
    fi
  done

  for f in "${hashes[@]}"; do
    base="$(basename -- "$f")"
    cmd="$(hash_verify_cmd_for_file "$base")" || {
      echo "Skipping hash verify (unknown type): $base" >&2
      continue
    }
    command -v "$cmd" >/dev/null 2>&1 || {
      echo "Skipping hash verify ('$cmd' not found): $base" >&2
      continue
    }
    any=1
    echo "Hash verify: $base ($cmd -c)"
    (
      cd "$WORK_DIR" || exit 1
      "$cmd" -c -- "$base"
    )
    verify_rc=$?
    if (( verify_rc != 0 )); then
      echo "Hash verify FAILED for $base (exit ${verify_rc})." >&2
      rc=1
    else
      echo "Hash verify OK: $base"
    fi
  done

  if (( any == 0 )); then
    echo "Nothing to verify."
    return 0
  fi
  return "$rc"
}

# When path.old already exists before a backup rename.
# Returns: 0=dst cleared (caller may mv), 1=skip this src, 2=quit.
offer_resolve_old_backup_collision() {
  local dst="$1"
  local ans="" base_old

  base_old="$(basename -- "$dst")"
  echo
  log_msg "Backup already exists: ${base_old}"
  if (( AUTO_YES == 1 )); then
    log_msg "Replacing existing *.old (--yes)."
    if (( DRY_RUN == 1 )); then
      log_msg "[dry-run] rm -- ${base_old}"
      return 0
    fi
    rm -f -- "$dst" || die "Failed to remove existing backup: ${base_old}"
    return 0
  fi

  echo "  [ R ] Replace — delete existing *.old, then rename current file to *.old (default)"
  echo "  [ s ] Skip — leave the current file as-is (do not back it up)"
  echo "  [ q ] Quit"
  printf '%sChoice [ R/s/q ] (%s): ' \
    "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
  while true; do
    if prompt_has_timeout; then
      IFS= read -r -t "$PROMPT_TIMEOUT" -n 1 ans || ans=R
    else
      IFS= read -r -n 1 ans || ans=R
    fi
    case "$ans" in
      ""|$'\n'|r|R)
        echo
        if (( DRY_RUN == 1 )); then
          log_msg "[dry-run] rm -- ${base_old}"
          return 0
        fi
        rm -f -- "$dst" || die "Failed to remove existing backup: ${base_old}"
        log_msg "deleted old backup: ${base_old}"
        return 0
        ;;
      s|S)
        echo
        log_msg "Skipped backup for this file (left in place)."
        return 1
        ;;
      q|Q)
        echo
        return 2
        ;;
      *)
        echo
        printf '%sInvalid key "%s". Press R, s, q, or Enter for default (R): ' \
          "$(user_prompt_ts_prefix)" "$ans"
        ;;
    esac
  done
}

# Returns: 0=ok, 2=quit.
backup_paths_to_old() {
  local -a paths=("$@")
  local src dst base
  local coll_rc=0

  for src in "${paths[@]}"; do
    [[ -e "$src" ]] || continue
    base="$(basename -- "$src")"
    dst="${src}.old"
    if [[ -e "$dst" ]]; then
      coll_rc=0
      offer_resolve_old_backup_collision "$dst" || coll_rc=$?
      case "$coll_rc" in
        1) continue ;;
        2) return 2 ;;
      esac
    fi
    if (( DRY_RUN == 1 )); then
      log_msg "[dry-run] mv -- ${base} -> $(basename -- "$dst")"
      JOB_BACKED_UP_COUNT=$((JOB_BACKED_UP_COUNT + 1))
      continue
    fi
    mv -- "$src" "$dst" || die "Failed to rename $base to $(basename -- "$dst")."
    log_msg "${base} -> $(basename -- "$dst")"
    CLEANUP_RESTORE_OLDPATHS+=("$dst")
    JOB_BACKED_UP_COUNT=$((JOB_BACKED_UP_COUNT + 1))
  done
  return 0
}

# After create/hash: offer to delete superseded protection — other PAR2 sets/hashes
# still active (not the new _<dir> / __<dir>.ext) plus any *.par2.old / hash *.old.
# Returns: 0=ok, 2=quit.
offer_delete_superseded_protection() {
  local -a victims=() stems=() hashes=() members=()
  local f stem ans="" want_hash="" base

  want_hash="$(basename -- "$HASH_FILE")"

  list_par2_set_stems_in_dir "$WORK_DIR" stems
  for stem in "${stems[@]}"; do
    [[ "${stem,,}" == "${PAR2_STEM,,}" ]] && continue
    members=()
    list_existing_stem_par2 "$WORK_DIR" "$stem" members
    victims+=("${members[@]}")
  done

  list_hash_manifests_in_dir "$WORK_DIR" hashes
  for f in "${hashes[@]}"; do
    base="$(basename -- "$f")"
    [[ "${base,,}" == "${want_hash,,}" ]] && continue
    victims+=("$f")
  done

  shopt -s nullglob
  for f in "$WORK_DIR"/*.par2.old "$WORK_DIR"/*.PAR2.old \
           "$WORK_DIR"/*.sha512.old "$WORK_DIR"/*.sha384.old \
           "$WORK_DIR"/*.sha256.old "$WORK_DIR"/*.sha224.old \
           "$WORK_DIR"/*.sha1.old "$WORK_DIR"/*.md5.old "$WORK_DIR"/*.b2.old \
           "$WORK_DIR"/*.SHA512.old "$WORK_DIR"/*.MD5.old; do
    [[ -f "$f" ]] || continue
    victims+=("$f")
  done
  shopt -u nullglob

  ((${#victims[@]} > 0)) || return 0

  # Dedupe paths (same file listed twice).
  if ((${#victims[@]} > 1)); then
    local -A seen=()
    local -a uniq=()
    for f in "${victims[@]}"; do
      [[ -n "${seen[$f]:-}" ]] && continue
      seen[$f]=1
      uniq+=("$f")
    done
    victims=("${uniq[@]}")
  fi

  echo
  echo "Superseded / leftover protection file(s) (${#victims[@]}):"
  for f in "${victims[@]}"; do
    printf '  %s\n' "$(basename -- "$f")"
  done
  echo "These are other PAR2/hash sets or *.old backups; keeping the new ${PAR2_STEM}* / ${want_hash}."
  if (( AUTO_YES == 1 )); then
    echo "Deleting leftover protection (--yes)."
    ans=yes
  elif apply_yes_no_policy ans "$DELETE_LEFTOVER_POLICY" "delete leftover protection"; then
    :
  else
    echo "  [ Y ] Delete those leftover protection file(s) now (default)"
    echo "  [ n ] Keep them"
    echo "  [ a ] Delete leftovers for the rest of the run (same as [ Y ])"
    echo "  [ e ] Keep leftovers for the rest of the run (same as [ n ])"
    echo "  [ q ] Quit"
    printf '%sChoice [ Y/n/a/e/q ] (%s): ' \
      "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
    read_yes_no_rest_key_with_timeout ans yes y DELETE_LEFTOVER_POLICY
    case $? in
      2) echo "Quit."; return 2 ;;
    esac
  fi
  case "$ans" in
    yes)
      for f in "${victims[@]}"; do
        if (( DRY_RUN == 1 )); then
          log_msg "[dry-run] rm -- $(basename -- "$f")"
          JOB_DELETED_COUNT=$((JOB_DELETED_COUNT + 1))
        else
          if rm -f -- "$f"; then
            log_msg "deleted: $(basename -- "$f")"
            JOB_DELETED_COUNT=$((JOB_DELETED_COUNT + 1))
          fi
        fi
      done
      CLEANUP_RESTORE_OLDPATHS=()
      ;;
    *)
      log_msg "Keeping leftover protection file(s)."
      CLEANUP_RESTORE_OLDPATHS=()
      ;;
  esac
  return 0
}

# Compat alias (older call sites / history wording).
offer_delete_consolidate_old_backups() {
  offer_delete_superseded_protection
}

# If 2+ PAR2 sets and/or 2+ hashes: verify (default Y), then consolidate (default Y).
# Sets CONSOLIDATE_DONE=1 when create should proceed as a fresh unified set.
# Returns 0=continue job, 2=quit run, 3=skip directory.
maybe_offer_verify_and_consolidate() {
  local -a stems=() hashes=() all_par2=() members=()
  local stem f ans="" verify_ok=0 offer_rc=0

  CONSOLIDATE_DONE=0
  list_par2_set_stems_in_dir "$WORK_DIR" stems
  list_hash_manifests_in_dir "$WORK_DIR" hashes

  if (( ${#stems[@]} < 2 && ${#hashes[@]} < 2 )); then
    return 0
  fi

  echo
  echo "Multiple protection files in this directory:"
  if ((${#stems[@]} >= 2)); then
    echo "  PAR2 sets (${#stems[@]}):"
    for stem in "${stems[@]}"; do
      members=()
      list_existing_stem_par2 "$WORK_DIR" "$stem" members
      printf '    - %s (%d file(s)' "$stem" "${#members[@]}"
      printf ')\n'
      for f in "${members[@]}"; do
        printf '        %s\n' "$(basename -- "$f")"
      done
    done
  elif ((${#stems[@]} == 1)); then
    echo "  PAR2 sets: 1 (${stems[0]})"
  else
    echo "  PAR2 sets: none"
  fi
  if ((${#hashes[@]} >= 2)); then
    echo "  Hash manifests (${#hashes[@]}):"
    for f in "${hashes[@]}"; do
      printf '    - %s\n' "$(basename -- "$f")"
    done
  elif ((${#hashes[@]} == 1)); then
    echo "  Hash manifests: 1 ($(basename -- "${hashes[0]}"))"
  else
    echo "  Hash manifests: none"
  fi
  echo "Suggestion: verify everything first; if OK, consolidate into one PAR2 + one hash."

  if (( AUTO_YES == 1 )); then
    echo "Skipping verify/consolidate offer (--yes keeps existing multi sets)."
    return 0
  fi

  if apply_yes_no_policy ans "$VERIFY_MULTI_POLICY" "verify multi-set first"; then
    :
  else
    echo "  [ Y ] Verify existing PAR2 set(s) and hash file(s) first (default)"
    echo "  [ n ] Skip verify"
    echo "  [ a ] Verify first for the rest of the run (same as [ Y ])"
    echo "  [ e ] Skip verify for the rest of the run (same as [ n ])"
    echo "  [ q ] Quit"
    printf '%sChoice [ Y/n/a/e/q ] (%s): ' \
      "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
    read_yes_no_rest_key_with_timeout ans yes y VERIFY_MULTI_POLICY
    case $? in
      2) echo "Quit."; return 2 ;;
    esac
  fi
  case "$ans" in
    yes)
      if verify_dir_par2_and_hashes; then
        verify_ok=1
        echo "Verification passed."
      else
        echo
        log_msg "Verification reported problems (often missing refs to already-removed files)."
        if apply_yes_no_policy ans "$CONSOLIDATE_ANYWAY_POLICY" "consolidate anyway after verify-fail"; then
          :
        else
          echo "  [ C ] Consolidate anyway into one PAR2 + one hash (default)"
          echo "  [ n ] Do not consolidate — continue with normal recreate prompts"
          echo "  [ a ] Consolidate anyway for the rest of the run (same as [ C ])"
          echo "  [ e ] Do not consolidate for the rest of the run (same as [ n ])"
          echo "  [ q ] Quit"
          printf '%sChoice [ C/n/a/e/q ] (%s): ' \
            "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
          read_yes_no_rest_key_with_timeout ans yes c CONSOLIDATE_ANYWAY_POLICY
          case $? in
            2) echo "Quit."; return 2 ;;
          esac
        fi
        case "$ans" in
          yes) verify_ok=1 ;;
          *)
            log_msg "Leaving multiple protection files as-is (no consolidate)."
            return 0
            ;;
        esac
      fi
      ;;
    *)
      echo "Skipping verify."
      verify_ok=0
      if apply_yes_no_policy ans "$CONSOLIDATE_ANYWAY_POLICY" "consolidate anyway without verify"; then
        :
      else
        echo "  [ y ] Consolidate anyway into one PAR2 + one hash (without verify)"
        echo "  [ N ] Do not consolidate (default)"
        echo "  [ a ] Consolidate anyway for the rest of the run (same as [ y ])"
        echo "  [ e ] Do not consolidate for the rest of the run (same as [ N ])"
        echo "  [ q ] Quit"
        printf '%sChoice [ y/N/a/e/q ] (%s): ' \
          "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
        read_yes_no_rest_key_with_timeout ans no y CONSOLIDATE_ANYWAY_POLICY
        case $? in
          2) echo "Quit."; return 2 ;;
        esac
      fi
      case "$ans" in
        yes) verify_ok=1 ;;
        *) echo "Leaving multiple protection files as-is."; return 0 ;;
      esac
      ;;
  esac

  if (( verify_ok != 1 )); then
    return 0
  fi

  if apply_yes_no_policy ans "$CONSOLIDATE_POLICY" "consolidate into one set"; then
    :
  else
    echo "  [ Y ] Consolidate into one PAR2 + one hash for this directory (default)"
    echo "  [ n ] Leave multiple protection files as-is"
    echo "  [ a ] Consolidate for the rest of the run (same as [ Y ])"
    echo "  [ e ] Do not consolidate for the rest of the run (same as [ n ])"
    echo "  [ q ] Quit"
    printf '%sChoice [ Y/n/a/e/q ] (%s): ' \
      "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
    read_yes_no_rest_key_with_timeout ans yes y CONSOLIDATE_POLICY
    case $? in
      2) echo "Quit."; return 2 ;;
    esac
  fi
  case "$ans" in
    yes) ;;
    *) echo "Leaving multiple protection files as-is."; return 0 ;;
  esac

  echo "Backing up existing PAR2 set(s) and hash manifest(s) to *.old ..."
  all_par2=()
  for stem in "${stems[@]}"; do
    members=()
    list_existing_stem_par2 "$WORK_DIR" "$stem" members
    all_par2+=("${members[@]}")
  done
  offer_rc=0
  backup_paths_to_old "${all_par2[@]}" || offer_rc=$?
  if (( offer_rc == 2 )); then
    echo "Quit."
    return 2
  fi
  offer_rc=0
  backup_paths_to_old "${hashes[@]}" || offer_rc=$?
  if (( offer_rc == 2 )); then
    echo "Quit."
    return 2
  fi
  # New create owns these; do not auto-restore mid-create on success path.
  PAR2_CREATE_IN_PROGRESS=0
  CONSOLIDATE_DONE=1
  CREATE_PAR2=1
  echo "Will create a single volume-only PAR2 (${PAR2_STEM}) and hash (__${DIR_NAME}.${HASH_EXT})."
  return 0
}

# Exactly one PAR2 set and exactly one hash manifest (any names).
dir_has_single_par2_and_hash() {
  local -a stems=() hashes=() members=()

  list_par2_set_stems_in_dir "$WORK_DIR" stems
  list_hash_manifests_in_dir "$WORK_DIR" hashes

  ((${#stems[@]} == 1 && ${#hashes[@]} == 1)) || return 1
  members=()
  list_existing_stem_par2 "$WORK_DIR" "${stems[0]}" members
  ((${#members[@]} > 0)) || return 1
  return 0
}

# When one PAR2 set + one hash already exist: skip or verify (optionally for rest of run).
# Names need not match _<dir> / __<dir>.ext (e.g. media-basename protection is OK).
# Returns: 0=continue create flow, 2=quit, 3=skip folder (done without create),
#          4=verified OK (done without create).
maybe_offer_skip_or_verify_existing() {
  local -a stems=() hashes=() members=()
  local ans="" action="" f stem=""

  (( CONSOLIDATE_DONE == 1 )) && return 0
  dir_has_single_par2_and_hash || return 0

  list_par2_set_stems_in_dir "$WORK_DIR" stems
  list_hash_manifests_in_dir "$WORK_DIR" hashes
  stem="${stems[0]}"
  members=()
  list_existing_stem_par2 "$WORK_DIR" "$stem" members

  echo
  log_msg "Existing protection found (1 PAR2 set + 1 hash):"
  log_msg "  PAR2 set: ${stem} (${#members[@]} file(s))"
  for f in "${members[@]}"; do
    log_msg "    $(basename -- "$f")"
  done
  log_msg "  Hash:     $(basename -- "${hashes[0]}")"
  if [[ "${stem,,}" != "${PAR2_STEM,,}" ]] || \
     [[ "$(basename -- "${hashes[0]}")" != "__${DIR_NAME}.${HASH_EXT}" ]]; then
    log_msg "  Note: names differ from this script's defaults (_${DIR_NAME} / __${DIR_NAME}.${HASH_EXT})."
  fi

  if (( AUTO_YES == 1 )); then
    log_msg "Skipping this directory (--yes; leave existing PAR2 + hash unchanged)."
    return 3
  fi

  if [[ -n "$EXISTING_PROTECTION_POLICY" ]]; then
    action="$EXISTING_PROTECTION_POLICY"
    log_msg "Using remembered choice for this run: ${action}."
  else
    echo "This directory already has one PAR2 set and one hash."
    echo "  [ S ] Skip this folder — leave PAR2 + hash unchanged (default)"
    echo "  [ v ] Verify this folder — if OK, leave unchanged"
    echo "  [ a ] Skip for the rest of the run (same as [ S ] for later matching folders)"
    echo "  [ e ] Verify for the rest of the run (same as [ v ] for later matching folders)"
    echo "  [ q ] Quit"
    printf '%sChoice [ S/v/a/e/q ] (default: S, %s): ' \
      "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
    read_skip_verify_key_with_timeout ans skip
    case $? in
      2) log_msg "Quit."; return 2 ;;
    esac
    case "$ans" in
      skip)
        action=skip
        ;;
      verify)
        action=verify
        ;;
      skip_rest)
        EXISTING_PROTECTION_POLICY=skip
        action=skip
        log_msg "Will skip remaining folders that already have one PAR2 + one hash."
        ;;
      verify_rest)
        EXISTING_PROTECTION_POLICY=verify
        action=verify
        log_msg "Will verify remaining folders that already have one PAR2 + one hash."
        ;;
      *)
        action=skip
        ;;
    esac
  fi

  case "$action" in
    skip)
      log_msg "Skipped (existing PAR2 + hash left unchanged)."
      return 3
      ;;
    verify)
      if verify_dir_par2_and_hashes; then
        log_msg "Verification passed — leaving existing protection unchanged."
        return 4
      fi
      log_msg "Verification FAILED — continuing so you can recreate if you want." >&2
      return 0
      ;;
  esac
  return 0
}

prompt_hash_algo() {
  local preferred="${1:-}"
  local ans="" i n def_idx=1 id label cmd

  discover_hash_tools
  ((${#HASH_IDS[@]} > 0)) || die "No hash tools found (need one of: sha512sum sha384sum sha256sum sha224sum sha1sum md5sum b2sum)."

  # Resolve preferred id to an available entry; default sha512 then first.
  if [[ -z "$preferred" ]]; then
    preferred="sha512"
  fi
  preferred="$(normalize_hash_id "$preferred")"
  def_idx="$(hash_index_for_id "$preferred")"
  if (( def_idx == 0 )); then
    if [[ -n "$HASH_PREF" ]]; then
      echo "Preferred hash '$HASH_PREF' is not available on this system; using ${HASH_LABELS[0]}."
    fi
    preferred="${HASH_IDS[0]}"
    def_idx=1
  else
    preferred="${HASH_IDS[def_idx - 1]}"
  fi

  if (( AUTO_YES == 1 )); then
    HASH_ALGO="$preferred"
    apply_hash_algo
    return 0
  fi

  n=${#HASH_IDS[@]}
  echo "Hash algorithms available on this system:"
  for (( i = 0; i < n; i++ )); do
    id="${HASH_IDS[$i]}"
    label="${HASH_LABELS[$i]}"
    cmd="${HASH_CMDS[$i]}"
    if (( i + 1 == def_idx )); then
      printf '  %d) %-8s (%s)  [default]\n' "$((i + 1))" "$label" "$cmd"
    else
      printf '  %d) %-8s (%s)\n' "$((i + 1))" "$label" "$cmd"
    fi
  done
  echo

  while true; do
    printf '%sChoose hash [1-%d] (default: %d = %s; q=quit, %s): ' \
      "$(user_prompt_ts_prefix)" "$n" "$def_idx" "${HASH_LABELS[def_idx - 1]}" \
      "$(prompt_timeout_label)"
    read_hash_choice_with_timeout ans
    case $? in
      1)
        ans=""
        echo
        ;;
      2)
        echo "Quit."
        return_code=0
        RUN_OUTCOME=quit
        finish
        ;;
    esac
    ans="${ans//[[:space:]]/}"
    case "$ans" in
      "")
        HASH_ALGO="${HASH_IDS[def_idx - 1]}"
        apply_hash_algo
        return 0
        ;;
      q|Q)
        echo "Quit."
        return_code=0
        RUN_OUTCOME=quit
        finish
        ;;
    esac
    ans="${ans,,}"
    if [[ "$ans" =~ ^[1-9][0-9]*$ ]] && (( ans >= 1 && ans <= n )); then
      HASH_ALGO="${HASH_IDS[ans - 1]}"
      apply_hash_algo
      return 0
    fi
    id="$(normalize_hash_id "$ans")"
    i="$(hash_index_for_id "$id")"
    if (( i > 0 )); then
      HASH_ALGO="${HASH_IDS[i - 1]}"
      apply_hash_algo
      return 0
    fi
    echo "Invalid choice '$ans'. Press a number 1-${n}, Enter for default, or q to quit."
  done
}

normalize_hash_id() {
  local raw="${1,,}"
  raw="${raw//[[:space:]]/}"
  case "$raw" in
    sha512|sha-512|512) printf 'sha512\n' ;;
    sha384|sha-384|384) printf 'sha384\n' ;;
    sha256|sha-256|256) printf 'sha256\n' ;;
    sha224|sha-224|224) printf 'sha224\n' ;;
    sha1|sha-1) printf 'sha1\n' ;;
    md5) printf 'md5\n' ;;
    b2|blake2|blake2b) printf 'b2\n' ;;
    *) printf '%s\n' "$raw" ;;
  esac
}

# Populate HASH_IDS / HASH_LABELS / HASH_CMDS / HASH_EXTS for tools on PATH.
discover_hash_tools() {
  local -a specs=(
    "sha512|SHA-512|sha512sum|sha512"
    "sha384|SHA-384|sha384sum|sha384"
    "sha256|SHA-256|sha256sum|sha256"
    "sha224|SHA-224|sha224sum|sha224"
    "sha1|SHA-1|sha1sum|sha1"
    "md5|MD5|md5sum|md5"
    "b2|BLAKE2|b2sum|b2"
  )
  local spec id label cmd ext

  HASH_IDS=()
  HASH_LABELS=()
  HASH_CMDS=()
  HASH_EXTS=()

  for spec in "${specs[@]}"; do
    IFS='|' read -r id label cmd ext <<< "$spec"
    command -v "$cmd" >/dev/null 2>&1 || continue
    HASH_IDS+=("$id")
    HASH_LABELS+=("$label")
    HASH_CMDS+=("$cmd")
    HASH_EXTS+=("$ext")
  done
}

hash_index_for_id() {
  local want="$1" i
  for i in "${!HASH_IDS[@]}"; do
    if [[ "${HASH_IDS[$i]}" == "$want" ]]; then
      printf '%s\n' "$((i + 1))"
      return 0
    fi
  done
  printf '0\n'
}

prompt_recovery_percent() {
  local suggested="${1:-20}"
  local ans=""

  [[ "$suggested" =~ ^[1-9][0-9]?$|^100$ ]] || suggested=20

  if (( AUTO_YES == 1 )); then
    RECOVERY_PCT="$suggested"
    return 0
  fi

  printf '%sRecovery percent for PAR2 set [1-100] (default: %s%%; q=quit, %s): ' \
    "$(user_prompt_ts_prefix)" "$suggested" "$(prompt_timeout_label)"
  if ! read_line_with_timeout ans; then
    ans=""
    echo
  fi
  ans="${ans//[[:space:]]/}"
  case "$ans" in
    q|Q)
      echo "Quit."
      return_code=0
      RUN_OUTCOME=quit
      finish
      ;;
  esac
  ans="${ans%%%}"
  [[ -z "$ans" ]] && ans="$suggested"
  if [[ ! "$ans" =~ ^[1-9][0-9]?$|^100$ ]]; then
    echo "Invalid percent '$ans'; using ${suggested}%."
    ans="$suggested"
  fi
  RECOVERY_PCT="$ans"
}

find_rename_helpers() {
  local root="$1"
  local -n _out=$2
  local f base rel
  local -a found=()

  _out=()
  while IFS= read -r -d '' f; do
    [[ -f "$f" ]] || continue
    base="$(basename -- "$f")"
    is_rename_helper_basename "$base" || continue
    rel="$(relpath_from_root "$f" "$root")"
    found+=("$rel")
  done < <(find "$root" -type f -print0 2>/dev/null)

  if ((${#found[@]} > 1)); then
    IFS=$'\n' found=($(printf '%s\n' "${found[@]}" | LC_ALL=C sort -f))
    unset IFS
  fi
  _out=("${found[@]}")
}

prompt_exclude_rename_helpers() {
  local ans="" rel

  if (( EXCLUDE_RENAME_HELPERS_CLI == 0 || EXCLUDE_RENAME_HELPERS_CLI == 1 )); then
    EXCLUDE_RENAME_HELPERS="$EXCLUDE_RENAME_HELPERS_CLI"
    return 0
  fi

  if (( AUTO_YES == 1 )); then
    EXCLUDE_RENAME_HELPERS=1
    return 0
  fi

  RENAME_HELPERS_FOUND=()
  find_rename_helpers "$WORK_DIR" RENAME_HELPERS_FOUND

  if ((${#RENAME_HELPERS_FOUND[@]} == 0)); then
    echo "No rename.sh helper files found under this tree."
    EXCLUDE_RENAME_HELPERS=1
    return 0
  fi

  echo "Found ${#RENAME_HELPERS_FOUND[@]} rename.sh helper file(s) (database, exclude list, resume state):"
  for rel in "${RENAME_HELPERS_FOUND[@]}"; do
    printf '  %s\n' "$rel"
  done
  echo "These are typically regenerated by rename.sh and do not need PAR2 recovery."

  printf '%sExclude rename.sh helper files from the PAR2 set? [Y/n/q] (%s): ' \
    "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
  read_yn_key_with_timeout ans y
  case $? in
    2)
      echo "Quit."
      return_code=0
      RUN_OUTCOME=quit
      finish
      ;;
  esac
  case "$ans" in
    y) EXCLUDE_RENAME_HELPERS=1 ;;
    n) EXCLUDE_RENAME_HELPERS=0 ;;
    *) EXCLUDE_RENAME_HELPERS=1 ;;
  esac
}

# Always / never / ask (default ask). Sets __var to always|never|ask.
# Returns: 0=ok, 2=quit. yes_key is the "always" letter (usually y).
read_always_never_ask_key_with_timeout() {
  local __var="$1"
  local yes_key="${2:-y}"
  local first="" yes_l

  yes_key="${yes_key:0:1}"
  yes_l="${yes_key,,}"

  while true; do
    if prompt_has_timeout; then
      IFS= read -r -t "$PROMPT_TIMEOUT" -n 1 first || {
        echo
        printf -v "$__var" '%s' ask
        return 1
      }
    else
      IFS= read -r -n 1 first || {
        echo
        printf -v "$__var" '%s' ask
        return 1
      }
    fi

    case "$first" in
      ""|$'\n'|a|A)
        echo
        printf -v "$__var" '%s' ask
        return 0
        ;;
      n|N)
        echo
        printf -v "$__var" '%s' never
        return 0
        ;;
      q|Q)
        echo
        printf -v "$__var" '%s' quit
        return 2
        ;;
      *)
        if [[ "${first,,}" == "$yes_l" ]]; then
          echo
          printf -v "$__var" '%s' always
          return 0
        fi
        echo
        printf '%sInvalid key "%s". Press %s, n, A, q, or Enter for default (A): ' \
          "$(user_prompt_ts_prefix)" "$first" "${yes_l^^}"
        ;;
    esac
  done
}

policy_label_existing() {
  case "${EXISTING_PROTECTION_POLICY:-}" in
    skip) printf 'always skip' ;;
    verify) printf 'always verify' ;;
    *) printf 'ask each time' ;;
  esac
}

policy_label_yes_no_ask() {
  case "${1:-}" in
    yes) printf 'always' ;;
    no) printf 'never' ;;
    *) printf 'ask each time' ;;
  esac
}

# Apply always|never|ask → yes|no|empty policy var.
set_yes_no_policy_from_choice() {
  local choice="$1"
  local policy_var_name="$2"

  case "$choice" in
    always) printf -v "$policy_var_name" '%s' yes ;;
    never)  printf -v "$policy_var_name" '%s' no ;;
    *)      printf -v "$policy_var_name" '%s' "" ;;
  esac
}

# Interactive run-start policies (1–3). Returns 2 if user quits.
prompt_run_folder_policies() {
  local ans=""

  if (( AUTO_YES == 1 )); then
    return 0
  fi

  echo
  echo "=== Per-folder policies for this run ==="
  echo "Choose defaults now; you can still quit later. Enter / [ A ] = ask each time."
  echo

  echo "1) Folder already has exactly one PAR2 set and one hash:"
  echo "  [ S ] Always skip (leave unchanged)"
  echo "  [ v ] Always verify (leave unchanged if OK)"
  echo "  [ A ] Ask each time (default)"
  echo "  [ q ] Quit"
  printf '%sChoice [ S/v/A/q ] (%s): ' \
    "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
  while true; do
    if prompt_has_timeout; then
      IFS= read -r -t "$PROMPT_TIMEOUT" -n 1 ans || ans=A
    else
      IFS= read -r -n 1 ans || ans=A
    fi
    case "$ans" in
      ""|$'\n'|a|A)
        echo
        EXISTING_PROTECTION_POLICY=""
        break
        ;;
      s|S)
        echo
        EXISTING_PROTECTION_POLICY=skip
        break
        ;;
      v|V)
        echo
        EXISTING_PROTECTION_POLICY=verify
        break
        ;;
      q|Q)
        echo
        return 2
        ;;
      *)
        echo
        printf '%sInvalid key "%s". Press S, v, A, q, or Enter for default (A): ' \
          "$(user_prompt_ts_prefix)" "$ans"
        ;;
    esac
  done

  echo
  echo "2a) Folder has multiple PAR2 sets and/or hashes — verify first?"
  echo "  [ Y ] Always verify first"
  echo "  [ n ] Never verify first"
  echo "  [ A ] Ask each time (default)"
  echo "  [ q ] Quit"
  printf '%sChoice [ Y/n/A/q ] (%s): ' \
    "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
  read_always_never_ask_key_with_timeout ans y
  case $? in
    2) return 2 ;;
  esac
  set_yes_no_policy_from_choice "$ans" VERIFY_MULTI_POLICY

  echo
  echo "2b) If verify fails or is skipped — consolidate anyway into one set?"
  echo "  [ Y ] Always consolidate anyway"
  echo "  [ n ] Never consolidate anyway"
  echo "  [ A ] Ask each time (default)"
  echo "  [ q ] Quit"
  printf '%sChoice [ Y/n/A/q ] (%s): ' \
    "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
  read_always_never_ask_key_with_timeout ans y
  case $? in
    2) return 2 ;;
  esac
  set_yes_no_policy_from_choice "$ans" CONSOLIDATE_ANYWAY_POLICY

  echo
  echo "2c) When consolidate is offered — consolidate into one PAR2 + one hash?"
  echo "  [ Y ] Always consolidate"
  echo "  [ n ] Never consolidate"
  echo "  [ A ] Ask each time (default)"
  echo "  [ q ] Quit"
  printf '%sChoice [ Y/n/A/q ] (%s): ' \
    "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
  read_always_never_ask_key_with_timeout ans y
  case $? in
    2) return 2 ;;
  esac
  set_yes_no_policy_from_choice "$ans" CONSOLIDATE_POLICY

  echo
  echo "3) After create — delete leftover other PAR2/hash sets and *.old backups?"
  echo "  [ Y ] Always delete leftovers"
  echo "  [ n ] Never delete leftovers"
  echo "  [ A ] Ask each time (default)"
  echo "  [ q ] Quit"
  printf '%sChoice [ Y/n/A/q ] (%s): ' \
    "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
  read_always_never_ask_key_with_timeout ans y
  case $? in
    2) return 2 ;;
  esac
  set_yes_no_policy_from_choice "$ans" DELETE_LEFTOVER_POLICY

  echo
  log_msg "Policies: existing=$(policy_label_existing); verify-multi=$(policy_label_yes_no_ask "$VERIFY_MULTI_POLICY"); consolidate-anyway=$(policy_label_yes_no_ask "$CONSOLIDATE_ANYWAY_POLICY"); consolidate=$(policy_label_yes_no_ask "$CONSOLIDATE_POLICY"); leftovers=$(policy_label_yes_no_ask "$DELETE_LEFTOVER_POLICY")"
  return 0
}

apply_hash_algo() {
  local i idx=0
  [[ -n "$HASH_ALGO" ]] || die "Internal error: HASH_ALGO empty."
  if ((${#HASH_IDS[@]} == 0)); then
    discover_hash_tools
  fi
  idx="$(hash_index_for_id "$HASH_ALGO")"
  (( idx > 0 )) || die "Hash algorithm not available on this system: $HASH_ALGO"
  i=$((idx - 1))
  HASH_LABEL="${HASH_LABELS[$i]}"
  HASH_CMD="${HASH_CMDS[$i]}"
  HASH_EXT="${HASH_EXTS[$i]}"
  HASH_FILE="${WORK_DIR}/__${DIR_NAME}.${HASH_EXT}"
}

format_elapsed() {
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

format_bytes_approx() {
  local b="${1:-0}"
  if (( b >= 1099511627776 )); then
    awk -v b="$b" 'BEGIN { printf "%.1fT", b/1099511627776 }'
  elif (( b >= 1073741824 )); then
    awk -v b="$b" 'BEGIN { printf "%.1fG", b/1073741824 }'
  elif (( b >= 1048576 )); then
    awk -v b="$b" 'BEGIN { printf "%.1fM", b/1048576 }'
  elif (( b >= 1024 )); then
    awk -v b="$b" 'BEGIN { printf "%.1fK", b/1024 }'
  else
    printf '%sB' "$b"
  fi
}

# PAR2 needs block_count >= file count (max 32768). Prefer enough blocks so
# -rN% recovery size ≈ N% of source data (not N% of file-count * largest file).
choose_par2_block_count() {
  local nfiles="$1"
  local total_bytes="$2"
  local blocks by_size

  (( nfiles > 0 )) || { printf '0\n'; return 1; }
  if (( nfiles > MAX_PAR2_BLOCKS )); then
    printf '0\n'
    return 1
  fi

  blocks=$nfiles
  if (( total_bytes > 0 )); then
    by_size=$(( (total_bytes + TARGET_PAR2_BLOCK_BYTES - 1) / TARGET_PAR2_BLOCK_BYTES ))
    (( by_size > blocks )) && blocks=$by_size
  fi
  (( blocks < MIN_PAR2_BLOCKS )) && blocks=$MIN_PAR2_BLOCKS
  (( blocks > MAX_PAR2_BLOCKS )) && blocks=$MAX_PAR2_BLOCKS
  (( blocks < nfiles )) && blocks=$nfiles
  printf '%s\n' "$blocks"
}

detect_cpu_count() {
  local n
  n="$(nproc 2>/dev/null || true)"
  [[ "$n" =~ ^[1-9][0-9]*$ ]] || n="$(getconf _NPROCESSORS_ONLN 2>/dev/null || true)"
  [[ "$n" =~ ^[1-9][0-9]*$ ]] || n=1
  printf '%s' "$n"
}

# Default thread count: leave one core free when the host has at least 2 CPUs.
default_par2_thread_count() {
  local cpus
  cpus="$(detect_cpu_count)"
  if (( cpus >= 2 )); then
    printf '%s' "$((cpus - 1))"
  else
    printf '1'
  fi
}

# Resolve PAR2_THREADS / PAR2_FILE_THREADS (CLI > env > nproc-1 if CPUs >= 2).
# Sets PAR2_THREADS_SOURCE / PAR2_FILE_THREADS_SOURCE to cli|env|default.
resolve_par2_thread_counts() {
  local default_threads
  default_threads="$(default_par2_thread_count)"
  if [[ -n "$THREADS_CLI" ]]; then
    PAR2_THREADS="$THREADS_CLI"
    PAR2_THREADS_SOURCE=cli
  elif [[ -n "${PAR2_THREADS}" ]]; then
    PAR2_THREADS_SOURCE=env
  else
    PAR2_THREADS="$default_threads"
    PAR2_THREADS_SOURCE=default
  fi
  if [[ -n "$FILE_THREADS_CLI" ]]; then
    PAR2_FILE_THREADS="$FILE_THREADS_CLI"
    PAR2_FILE_THREADS_SOURCE=cli
  elif [[ -n "${PAR2_FILE_THREADS}" ]]; then
    PAR2_FILE_THREADS_SOURCE=env
  else
    PAR2_FILE_THREADS="$default_threads"
    PAR2_FILE_THREADS_SOURCE=default
  fi
  [[ "$PAR2_THREADS" =~ ^[1-9][0-9]*$ ]] \
    || die "Invalid PAR2_THREADS / --threads '$PAR2_THREADS' (use a positive integer)."
  [[ "$PAR2_FILE_THREADS" =~ ^[1-9][0-9]*$ ]] \
    || die "Invalid PAR2_FILE_THREADS / --file-threads '$PAR2_FILE_THREADS' (use a positive integer)."
}

sum_source_bytes() {
  local root="$1"
  shift
  local rel total=0 sz
  for rel in "$@"; do
    sz=$(stat -c '%s' -- "$root/$rel" 2>/dev/null) || sz=0
    [[ "$sz" =~ ^[0-9]+$ ]] || sz=0
    total=$(( total + sz ))
  done
  printf '%s\n' "$total"
}

# Returns: 0=ok, 2=quit.
backup_existing_stem_par2() {
  local -a members=("$@")
  local src dst base
  local -a backed=()
  local coll_rc=0

  for src in "${members[@]}"; do
    base="$(basename -- "$src")"
    dst="${src}.old"
    if [[ -e "$dst" ]]; then
      coll_rc=0
      offer_resolve_old_backup_collision "$dst" || coll_rc=$?
      case "$coll_rc" in
        1) continue ;;
        2) return 2 ;;
      esac
    fi
    if (( DRY_RUN == 1 )); then
      log_msg "[dry-run] mv -- ${base} -> $(basename -- "$dst")"
      JOB_BACKED_UP_COUNT=$((JOB_BACKED_UP_COUNT + 1))
      continue
    fi
    mv -- "$src" "$dst" || die "Failed to rename $base to $(basename -- "$dst")."
    log_msg "${base} -> $(basename -- "$dst")"
    backed+=("$dst")
    CLEANUP_RESTORE_OLDPATHS+=("$dst")
    JOB_BACKED_UP_COUNT=$((JOB_BACKED_UP_COUNT + 1))
  done
  return 0
}

create_par2_volume_only() {
  local stem="$1"
  local percent="$2"
  shift 2
  local -a sources=("$@")
  local block_count create_rc=0 index_path total_bytes=0 approx_block=0 approx_recovery=0
  local file_threads=1
  local -a vols=()

  ((${#sources[@]} > 0)) || die "No non-empty data files to protect."

  if ((${#sources[@]} > MAX_PAR2_BLOCKS)); then
    die "${#sources[@]} non-empty files exceeds PAR2 max block count (${MAX_PAR2_BLOCKS}). Split the tree first."
  fi

  # Thread counts resolved once at startup (CLI > env > nproc).
  file_threads=$PAR2_FILE_THREADS
  if (( file_threads > ${#sources[@]} )); then
    file_threads=${#sources[@]}
  fi
  (( file_threads >= 1 )) || file_threads=1

  total_bytes="$(sum_source_bytes "$WORK_DIR" "${sources[@]}")"
  block_count="$(choose_par2_block_count "${#sources[@]}" "$total_bytes")"
  [[ "$block_count" =~ ^[1-9][0-9]*$ ]] || die "Could not choose a PAR2 block count."

  PAR2_SOURCE_COUNT=${#sources[@]}
  PAR2_SOURCE_BYTES=$total_bytes
  CREATED_PAR2_VOLS=()

  approx_block=$(( (total_bytes + block_count - 1) / block_count ))
  approx_recovery=$(( total_bytes * percent / 100 ))

  echo "par2 create: ${#sources[@]} file(s), -b${block_count}, -r${percent}%, -n1, -t${PAR2_THREADS}, -T${file_threads}"
  echo "  source data:   $(format_bytes_approx "$total_bytes") (${total_bytes} bytes)"
  echo "  ~block size:   $(format_bytes_approx "$approx_block")"
  echo "  ~recovery size:$(format_bytes_approx "$approx_recovery") (about ${percent}% of source)"
  echo "  threads:       -t${PAR2_THREADS} (compute), -T${file_threads} (file hashing)"
  echo "  stem: ${stem}.par2 (volume-only; index removed after create)"

  if (( DRY_RUN == 1 )); then
    log_msg "[dry-run] ${PAR2_CMD} create -t${PAR2_THREADS} -T${file_threads} -n1 -b${block_count} -r${percent} -- ${stem}.par2 <${#sources[@]} files>"
    CREATED_PAR2_VOLS=( "${stem}.vol*.par2 (dry-run)" )
    JOB_CREATED_COUNT=$((JOB_CREATED_COUNT + 1))
    return 0
  fi

  PAR2_CREATE_IN_PROGRESS=1
  (
    cd "$WORK_DIR" || exit 1
    "$PAR2_CMD" create -t"$PAR2_THREADS" -T"$file_threads" -n1 -b"$block_count" -r"$percent" -- "${stem}.par2" "${sources[@]}"
  )
  create_rc=$?
  if (( create_rc != 0 )); then
    echo "par2 create failed (exit ${create_rc}); removing incomplete outputs..."
    cleanup_remove_new_par2_outputs
    if ((${#CLEANUP_RESTORE_OLDPATHS[@]} > 0)); then
      cleanup_restore_par2_backups
    fi
    PAR2_CREATE_IN_PROGRESS=0
    die "par2 create failed (exit ${create_rc})."
  fi

  index_path="${WORK_DIR}/${stem}.par2"
  shopt -s nullglob
  vols=("${WORK_DIR}/${stem}".vol*.par2 "${WORK_DIR}/${stem}".vol*.PAR2)
  shopt -u nullglob

  if ((${#vols[@]} == 0)); then
    [[ -f "$index_path" ]] && rm -f -- "$index_path"
    if ((${#CLEANUP_RESTORE_OLDPATHS[@]} > 0)); then
      cleanup_restore_par2_backups
    fi
    PAR2_CREATE_IN_PROGRESS=0
    die "par2 create did not produce a volume file for ${stem}."
  fi

  if [[ -f "$index_path" ]]; then
    rm -f -- "$index_path"
    echo "Removed index ${stem}.par2 (keeping volume-only set)."
  fi

  # Create succeeded: keep new volumes; leave *.par2.old on disk; do not restore on later Ctrl-C.
  PAR2_CREATE_IN_PROGRESS=0
  CLEANUP_RESTORE_OLDPATHS=()

  log_msg "New PAR2 volume(s):"
  for f in "${vols[@]}"; do
    log_msg "  $(basename -- "$f")"
    CREATED_PAR2_VOLS+=( "$(basename -- "$f")" )
    JOB_CREATED_COUNT=$((JOB_CREATED_COUNT + 1))
  done
}

write_hash_manifest() {
  local out_file="$1"
  local algo_cmd="$2"
  shift 2
  local -a rels=("$@")
  local rel digest line_count=0

  ((${#rels[@]} > 0)) || die "No files to hash."

  echo "Hashing ${#rels[@]} file(s) with ${algo_cmd} -> $(basename -- "$out_file")"

  if (( DRY_RUN == 1 )); then
    log_msg "[dry-run] would write ${#rels[@]} lines to $(basename -- "$out_file")"
    HASH_ENTRY_COUNT=${#rels[@]}
    JOB_CREATED_COUNT=$((JOB_CREATED_COUNT + 1))
    return 0
  fi

  command -v "$algo_cmd" >/dev/null 2>&1 || die "'$algo_cmd' not found."

  HASH_TEMP=$(mktemp "${TMPDIR:-/tmp}/par2-hash-pgm-create.XXXXXX") || die "mktemp failed."

  for rel in "${rels[@]}"; do
    if [[ ! -f "${WORK_DIR}/${rel}" ]]; then
      rm -f -- "$HASH_TEMP"
      HASH_TEMP=""
      die "Missing file while hashing: $rel"
    fi
    digest="$("$algo_cmd" -- "${WORK_DIR}/${rel}" | awk '{print tolower($1)}')"
    if [[ -z "$digest" ]]; then
      rm -f -- "$HASH_TEMP"
      HASH_TEMP=""
      die "Failed to hash: $rel"
    fi
    # GNU *sum -c binary form: one space then '*', then relative path.
    printf '%s *%s\n' "$digest" "$rel" >>"$HASH_TEMP"
    ((++line_count))
    if (( line_count % 100 == 0 )); then
      log_msg "... hashed ${line_count} / ${#rels[@]}"
    fi
  done

  if ! mv -- "$HASH_TEMP" "$out_file"; then
    rm -f -- "$HASH_TEMP"
    HASH_TEMP=""
    die "Failed to write $out_file"
  fi
  HASH_TEMP=""
  HASH_ENTRY_COUNT=$line_count
  JOB_CREATED_COUNT=$((JOB_CREATED_COUNT + 1))
  log_msg "Wrote ${line_count} checksum line(s): $(basename -- "$out_file")"
}

list_immediate_subdirs() {
  local root="$1"
  local -n _out=$2
  local d

  _out=()
  while IFS= read -r -d '' d; do
    [[ -d "$d" ]] || continue
    _out+=("$d")
  done < <(find "$root" -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null | LC_ALL=C sort -z)
}

set_work_directory() {
  local dir="$1"

  WORK_DIR="$(cd -- "$dir" && pwd -P)" || die "Cannot enter directory: $dir"
  DIR_NAME="$(basename -- "$WORK_DIR")"
  [[ -n "$DIR_NAME" && "$DIR_NAME" != "/" && "$DIR_NAME" != "." ]] \
    || die "Cannot derive a usable directory name from: $WORK_DIR"
  PAR2_STEM="_${DIR_NAME}"
  if [[ -n "${HASH_ALGO:-}" ]]; then
    apply_hash_algo
  else
    HASH_FILE=""
  fi
  RENAME_HELPERS_FOUND=()
  CREATED_PAR2_VOLS=()
  PAR2_SOURCE_COUNT=0
  PAR2_SOURCE_BYTES=0
  HASH_ENTRY_COUNT=0
  SUMMARY_PRINTED=0
  CREATE_PAR2=1
  PAR2_CREATE_IN_PROGRESS=0
  HASH_TEMP=""
  CLEANUP_RESTORE_OLDPATHS=()
}

# Resolve CREATE_SCOPE: whole | per-subdir. Returns 2 if user quits.
resolve_create_scope() {
  local -a subdirs=()
  local first=""

  list_immediate_subdirs "$START_DIR" subdirs

  if ((${#subdirs[@]} == 0)); then
    CREATE_SCOPE=whole
    CREATE_SCOPE_SOURCE=nosubdirs
    return 0
  fi

  if [[ -n "$SCOPE_CLI" ]]; then
    CREATE_SCOPE="$SCOPE_CLI"
    CREATE_SCOPE_SOURCE=cli
    return 0
  fi

  if (( AUTO_YES == 1 )); then
    CREATE_SCOPE=per-subdir
    CREATE_SCOPE_SOURCE=yes
    return 0
  fi

  echo "This directory has ${#subdirs[@]} immediate subdirectory(ies)."
  echo "What should be created?"
  echo "  [ w ] Whole tree — one PAR2 + hash in this directory (all files here and below)"
  echo "  [ P ] Per subdirectory — one PAR2 + hash in each immediate child (full subtree each;"
  echo "        files that sit only in this directory are ignored)  [default]"
  echo "  [ q ] Quit"
  printf '%sChoice [ w/P/q ] (%s): ' "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"

  while true; do
    if prompt_has_timeout; then
      if ! IFS= read -r -t "$PROMPT_TIMEOUT" -n 1 first; then
        echo
        echo "Timed out — using per subdirectory."
        CREATE_SCOPE=per-subdir
        CREATE_SCOPE_SOURCE=default
        return 0
      fi
    else
      IFS= read -r -n 1 first || first=""
    fi

    case "$first" in
      ""|$'\n'|p|P)
        echo
        CREATE_SCOPE=per-subdir
        CREATE_SCOPE_SOURCE=prompt
        return 0
        ;;
      w|W)
        echo
        CREATE_SCOPE=whole
        CREATE_SCOPE_SOURCE=prompt
        return 0
        ;;
      q|Q)
        echo
        return 2
        ;;
      *)
        echo
        printf '%sInvalid key "%s". Press w, P, q, or Enter for default (P): ' \
          "$(user_prompt_ts_prefix)" "$first"
        ;;
    esac
  done
}

# Command line that reproduces this run: the resolved hash/recovery/helper answers as flags.
print_run_settings_equivalent_cli() {
  local cmd="" out="" p q_dir
  local -a parts=()

  if declare -F script_live_basename >/dev/null 2>&1; then
    cmd="$(script_live_basename)"
  elif [[ -n "${SCRIPT_SELF_LIVE_PATH:-}" ]]; then
    cmd="$(basename -- "${SCRIPT_SELF_LIVE_PATH}")"
  else
    cmd="$(basename -- "${BASH_SOURCE[0]:-$0}")"
  fi
  [[ -n "$cmd" ]] || cmd="par2-hash-pgm-create.sh"

  parts+=("--hash" "$HASH_ALGO")
  parts+=("--recovery" "$RECOVERY_PCT")
  parts+=("--threads" "$PAR2_THREADS")
  parts+=("--file-threads" "$PAR2_FILE_THREADS")
  parts+=("--scope" "$CREATE_SCOPE")
  if (( EXCLUDE_RENAME_HELPERS == 1 )); then
    parts+=("--exclude-rename-helpers")
  else
    parts+=("--include-rename-helpers")
  fi
  (( AUTO_YES == 1 )) && parts+=("--yes")
  (( DRY_RUN == 1 )) && parts+=("--dry-run")

  out="$(printf '%q' "$cmd")"
  for p in "${parts[@]}"; do
    out+=" $(printf '%q' "$p")"
  done

  q_dir="$(printf '%q' "${START_DIR:-$WORK_DIR}")"
  if prompt_has_timeout; then
    printf '  %-16s%s\n' "Equivalent CLI:" "PROMPT_TIMEOUT=${PROMPT_TIMEOUT} cd $q_dir && $out"
  else
    printf '  %-16s%s\n' "Equivalent CLI:" "cd $q_dir && $out"
  fi
}

print_run_settings() {
  echo "=== Run settings ==="
  echo "  Start dir:     ${START_DIR:-$WORK_DIR}"
  case "${CREATE_SCOPE_SOURCE:-}" in
    cli) echo "  --scope:       given (${CREATE_SCOPE})" ;;
    yes) echo "  --scope:       not given (--yes default: per-subdir)" ;;
    nosubdirs) echo "  --scope:       whole (no immediate subdirectories)" ;;
    prompt) echo "  --scope:       not given (prompted; selected: ${CREATE_SCOPE})" ;;
    default) echo "  --scope:       per-subdir (fallback)" ;;
    *) echo "  --scope:       ${CREATE_SCOPE:-per-subdir}" ;;
  esac
  if [[ "$CREATE_SCOPE" == per-subdir ]]; then
    echo "  Scope note:    one PAR2+hash per immediate child; loose files in start dir ignored"
  else
    echo "  Work dir:      $WORK_DIR"
    echo "  Parent name:   $DIR_NAME"
    echo "  PAR2 stem:     ${PAR2_STEM}.par2 (volume-only)"
    echo "  Hash file:     __${DIR_NAME}.${HASH_EXT}"
  fi
  if [[ -n "$HASH_PREF" ]]; then
    echo "  --hash:        given (${HASH_LABEL} / ${HASH_CMD})"
  elif (( AUTO_YES == 1 )); then
    echo "  --hash:        not given (--yes default: ${HASH_LABEL} / ${HASH_CMD})"
  else
    echo "  --hash:        not given (prompted; selected: ${HASH_LABEL} / ${HASH_CMD})"
  fi
  if [[ -n "$RECOVERY_CLI" ]]; then
    echo "  --recovery:    given (${RECOVERY_PCT}%)"
  elif (( AUTO_YES == 1 )); then
    echo "  --recovery:    not given (--yes default: ${RECOVERY_PCT}%)"
  else
    echo "  --recovery:    not given (prompted; selected: ${RECOVERY_PCT}%)"
  fi
  if (( EXCLUDE_RENAME_HELPERS_CLI == 1 )); then
    echo "  Rename helpers: --exclude-rename-helpers given (excluded from PAR2, still hashed)"
  elif (( EXCLUDE_RENAME_HELPERS_CLI == 0 )); then
    echo "  Rename helpers: --include-rename-helpers given (included in PAR2)"
  elif (( EXCLUDE_RENAME_HELPERS == 1 )); then
    echo "  Rename helpers: not given (prompted; selected: excluded from PAR2, still hashed)"
  else
    echo "  Rename helpers: not given (prompted; selected: included in PAR2)"
  fi
  if (( AUTO_YES == 1 )); then
    echo "  Folder policies: --yes (existing: skip; multi-set offer skipped; leftovers: delete)"
  else
    echo "  Existing 1+1:  $(policy_label_existing)"
    echo "  Verify multi:  $(policy_label_yes_no_ask "$VERIFY_MULTI_POLICY")"
    echo "  Consol. anyway:$(policy_label_yes_no_ask "$CONSOLIDATE_ANYWAY_POLICY")"
    echo "  Consolidate:   $(policy_label_yes_no_ask "$CONSOLIDATE_POLICY")"
    echo "  Leftovers:     $(policy_label_yes_no_ask "$DELETE_LEFTOVER_POLICY")"
  fi
  echo "  PAR2_CMD:      $PAR2_CMD"
  case "${PAR2_THREADS_SOURCE:-default}" in
    cli) echo "  --threads:     given (${PAR2_THREADS})" ;;
    env) echo "  --threads:     from PAR2_THREADS (${PAR2_THREADS})" ;;
    *)   echo "  --threads:     default nproc-1 if CPUs>=2 (${PAR2_THREADS})" ;;
  esac
  case "${PAR2_FILE_THREADS_SOURCE:-default}" in
    cli) echo "  --file-threads: given (${PAR2_FILE_THREADS})" ;;
    env) echo "  --file-threads: from PAR2_FILE_THREADS (${PAR2_FILE_THREADS})" ;;
    *)   echo "  --file-threads: default nproc-1 if CPUs>=2 (${PAR2_FILE_THREADS})" ;;
  esac
  if (( DRY_RUN == 1 )); then
    echo "  Mode:          dry-run (no changes)"
  elif (( AUTO_YES == 1 )); then
    echo "  Mode:          --yes (defaults accepted)"
  else
    echo "  Mode:          interactive"
  fi
  echo "  PROMPT_TIMEOUT: $(prompt_timeout_label)"
  print_run_settings_equivalent_cli
  echo
}

print_multi_job_summary() {
  local line total_elapsed

  total_elapsed="$(format_elapsed "$(( $(date +%s) - SCRIPT_START_EPOCH ))")"
  echo
  log_msg "=== Multi-directory summary ==="
  log_msg "Directories: ${MULTI_JOB_TOTAL}  |  OK: ${MULTI_JOB_OK}  |  Skipped: ${MULTI_JOB_SKIP}  |  Failed: ${MULTI_JOB_FAIL}"
  log_msg "Total elapsed: ${total_elapsed}"
  if (( MULTI_JOB_TOTAL > 1 && ${#MULTI_FOLDER_RECAPS[@]} > 0 )); then
    log_msg "Per-folder recap:"
    for line in "${MULTI_FOLDER_RECAPS[@]}"; do
      log_msg "  ${line}"
    done
  fi
  echo
}

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      . "${profile_location_dir:-$HOME}/bin/_script_footer.sh"
      exit 0
      ;;
    -v|--version)
      print_version_banner
      . "${profile_location_dir:-$HOME}/bin/_script_footer.sh"
      exit 0
      ;;
    --history)
      print_script_history
      exit 0
      ;;
    --sha512)
      HASH_PREF="sha512"
      shift
      ;;
    --sha384)
      HASH_PREF="sha384"
      shift
      ;;
    --sha256)
      HASH_PREF="sha256"
      shift
      ;;
    --sha224)
      HASH_PREF="sha224"
      shift
      ;;
    --sha1)
      HASH_PREF="sha1"
      shift
      ;;
    --md5)
      HASH_PREF="md5"
      shift
      ;;
    --b2)
      HASH_PREF="b2"
      shift
      ;;
    --hash)
      [[ $# -ge 2 ]] || die "Missing value for --hash (e.g. sha512, md5, b2)."
      HASH_PREF="$(normalize_hash_id "$2")"
      shift 2
      ;;
    --recovery)
      [[ $# -ge 2 ]] || die "Missing value for --recovery (1-100)."
      RECOVERY_CLI="$2"
      [[ "$RECOVERY_CLI" =~ ^[1-9][0-9]?$|^100$ ]] || die "Invalid --recovery '$RECOVERY_CLI' (use 1-100)."
      shift 2
      ;;
    --exclude-rename-helpers)
      EXCLUDE_RENAME_HELPERS_CLI=1
      shift
      ;;
    --include-rename-helpers)
      EXCLUDE_RENAME_HELPERS_CLI=0
      shift
      ;;
    --yes|-y)
      AUTO_YES=1
      shift
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    --threads)
      [[ $# -ge 2 ]] || die "Missing value for --threads (positive integer)."
      THREADS_CLI="$2"
      [[ "$THREADS_CLI" =~ ^[1-9][0-9]*$ ]] || die "Invalid --threads '$THREADS_CLI' (use a positive integer)."
      shift 2
      ;;
    --file-threads)
      [[ $# -ge 2 ]] || die "Missing value for --file-threads (positive integer)."
      FILE_THREADS_CLI="$2"
      [[ "$FILE_THREADS_CLI" =~ ^[1-9][0-9]*$ ]] || die "Invalid --file-threads '$FILE_THREADS_CLI' (use a positive integer)."
      shift 2
      ;;
    --scope)
      [[ $# -ge 2 ]] || die "Missing value for --scope (whole|per-subdir)."
      case "${2,,}" in
        whole|tree|all) SCOPE_CLI=whole ;;
        per-subdir|per_subdir|subdir|subdirs|per) SCOPE_CLI=per-subdir ;;
        *) die "Invalid --scope '$2' (use whole or per-subdir)." ;;
      esac
      shift 2
      ;;
    --)
      shift
      break
      ;;
    -*)
      die "Unknown option: $1 (try -h)"
      ;;
    *)
      die "Unexpected argument: $1 (run in the target directory; try -h)"
      ;;
  esac
done

command -v "$PAR2_CMD" >/dev/null 2>&1 || die "'$PAR2_CMD' not found. Install par2cmdline or set PAR2_CMD."
resolve_par2_thread_counts

START_DIR="$(pwd -P)"
SCRIPT_START_EPOCH=$(date +%s)
SCRIPT_START_STR="$(date '+%Y.%m.%d %H:%M:%S')"

# Hash algo needs a provisional work dir so HASH_* / HASH_FILE resolve for settings.
set_work_directory "$START_DIR"

prompt_hash_algo "${HASH_PREF:-}"

if [[ -n "$RECOVERY_CLI" ]]; then
  RECOVERY_PCT="$RECOVERY_CLI"
else
  prompt_recovery_percent 20
fi

prompt_exclude_rename_helpers

if ! resolve_create_scope; then
  echo "Quit."
  return_code=0
  RUN_OUTCOME=quit
  finish
fi

if ! prompt_run_folder_policies; then
  echo "Quit."
  return_code=0
  RUN_OUTCOME=quit
  finish
fi

# Re-apply after scope (HASH_FILE may be refreshed); start dir still provisional for whole.
set_work_directory "$START_DIR"
print_run_settings

print_next_directory_banner() {
  local -a lines=()
  local job_note=""

  if (( MULTI_JOB_MODE == 1 && MULTI_JOB_TOTAL > 0 )); then
    job_note=" (job ${MULTI_JOB_TOTAL}"
    if ((${#job_dirs[@]} > 0)); then
      job_note+=" of ${#job_dirs[@]}"
    fi
    job_note+=")"
  fi

  lines+=( "*** NEXT DIRECTORY${job_note} ***" )
  lines+=( "" )
  lines+=( "Directory: $WORK_DIR" )
  lines+=( "Basename:  $DIR_NAME" )
  lines+=( "PAR2 stem: ${PAR2_STEM}.par2 (volume-only)" )
  lines+=( "Hash file: __${DIR_NAME}.${HASH_EXT}" )
  lines+=( "" )
  lines+=( "Started:   $(wall_clock_now)" )

  echo
  emit_boxed_block stone "${lines[@]}"
  echo
}

# Run create+hash for the current WORK_DIR.
# Returns: 0=ok, 2=quit entire run, 3=skip this directory.
run_create_job() {
  local -a existing_par2=() par2_sources=() hash_targets=()
  local ans="" f rel hash_rel
  local job_rc=0 offer_rc=0

  CONSOLIDATE_DONE=0
  reset_job_counters

  print_next_directory_banner

  offer_rc=0
  maybe_offer_verify_and_consolidate || offer_rc=$?
  case "$offer_rc" in
    2) JOB_OUTCOME=quit; print_folder_done_summary; return 2 ;;
    3) JOB_OUTCOME=skipped; print_folder_done_summary; return 3 ;;
  esac

  offer_rc=0
  maybe_offer_skip_or_verify_existing || offer_rc=$?
  case "$offer_rc" in
    2) JOB_OUTCOME=quit; print_folder_done_summary; return 2 ;;
    3) JOB_OUTCOME=skipped; print_folder_done_summary; return 3 ;;
    4) JOB_OUTCOME=ok; print_folder_done_summary; return 0 ;;
  esac

  existing_par2=()
  list_existing_stem_par2 "$WORK_DIR" "$PAR2_STEM" existing_par2
  CREATE_PAR2=1
  if (( CONSOLIDATE_DONE == 1 )); then
    # Old PAR2/hash already moved to *.old; create fresh unified set.
    CREATE_PAR2=1
  elif ((${#existing_par2[@]} > 0)); then
    log_msg "Existing PAR2 file(s) for stem ${PAR2_STEM}:"
    for f in "${existing_par2[@]}"; do
      log_msg "  $(basename -- "$f")"
    done
    if (( AUTO_YES == 1 )); then
      log_msg "Keeping existing PAR2 unchanged (--yes; recreate defaults to no)."
      CREATE_PAR2=0
      if [[ ! -e "$HASH_FILE" ]]; then
        log_msg "No hash file present; skipping this directory (--yes)."
        JOB_OUTCOME=skipped
        print_folder_done_summary
        return 3
      fi
    else
      ans=""
      printf '%sRename existing PAR2 to *.par2.old and recreate? [y/N/q] (%s): ' \
        "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
      read_yn_key_with_timeout ans n
      case $? in
        2)
          log_msg "Quit."
          JOB_OUTCOME=quit
          print_folder_done_summary
          return 2
          ;;
      esac
      case "$ans" in
        y)
          offer_rc=0
          backup_existing_stem_par2 "${existing_par2[@]}" || offer_rc=$?
          if (( offer_rc == 2 )); then
            log_msg "Quit."
            JOB_OUTCOME=quit
            print_folder_done_summary
            return 2
          fi
          CREATE_PAR2=1
          ;;
        n)
          log_msg "Keeping existing PAR2 unchanged."
          CREATE_PAR2=0
          if [[ ! -e "$HASH_FILE" ]]; then
            echo
            log_msg "Situation: PAR2 archive(s) exist for this directory, but there is no"
            log_msg "  hash manifest yet (expected: $(basename -- "$HASH_FILE"))."
            log_msg "Suggestion: create a hash file covering all files in this tree,"
            log_msg "  including the existing PAR2 file(s). PAR2 will not be modified."
            printf '%sCreate hash file now? [y/N/q] (%s): ' \
              "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
            read_yn_key_with_timeout ans n
            case $? in
              2)
                log_msg "Quit."
                JOB_OUTCOME=quit
                print_folder_done_summary
                return 2
                ;;
            esac
            case "$ans" in
              y)
                log_msg "Will create hash file only."
                ;;
              *)
                log_msg "Skipped (no PAR2 recreate, no hash file)."
                JOB_OUTCOME=skipped
                print_folder_done_summary
                return 3
                ;;
            esac
          else
            log_msg "Hash file already present: $(basename -- "$HASH_FILE") (overwrite prompt follows if needed)."
          fi
          ;;
        *)
          log_msg "Quit."
          JOB_OUTCOME=quit
          print_folder_done_summary
          return 2
          ;;
      esac
    fi
    echo
  fi

  if (( CONSOLIDATE_DONE == 1 )); then
    : # target hash path is free (old manifests renamed to *.old)
  elif [[ -e "$HASH_FILE" ]]; then
    log_msg "Hash file already exists: $(basename -- "$HASH_FILE")"
    if (( AUTO_YES == 1 )); then
      log_msg "Will overwrite (--yes)."
    else
      ans=""
      printf '%sOverwrite existing hash file? [Y/n/q] (%s): ' \
        "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
      read_yn_key_with_timeout ans y
      case $? in
        2)
          log_msg "Quit."
          JOB_OUTCOME=quit
          print_folder_done_summary
          return 2
          ;;
      esac
      case "$ans" in
        y)
          ;;
        *)
          log_msg "Skipped (hash file left unchanged)."
          JOB_OUTCOME=skipped
          print_folder_done_summary
          return 3
          ;;
      esac
    fi
    echo
  fi

  if (( CREATE_PAR2 == 1 )); then
    log_msg "=== Step 1: collect PAR2 source files (subtree; exclude PAR2 + hash manifests) ==="
    par2_sources=()
    collect_sorted_relpaths "$WORK_DIR" par2-sources par2_sources
    if (( EXCLUDE_RENAME_HELPERS == 1 )); then
      if ((${#RENAME_HELPERS_FOUND[@]} == 0)); then
        find_rename_helpers "$WORK_DIR" RENAME_HELPERS_FOUND
      fi
      if ((${#RENAME_HELPERS_FOUND[@]} > 0)); then
        log_msg "Excluding ${#RENAME_HELPERS_FOUND[@]} rename.sh helper file(s) from PAR2:"
        for rel in "${RENAME_HELPERS_FOUND[@]}"; do
          log_msg "  ${rel}"
        done
      fi
    fi
    log_msg "Found ${#par2_sources[@]} non-empty data file(s) to protect."
    if ((${#par2_sources[@]} == 0)); then
      log_msg "No data files to protect under: $WORK_DIR — skipping."
      JOB_OUTCOME=skipped
      print_folder_done_summary
      return 3
    fi

    echo
    log_msg "=== Step 2: create PAR2 (volume-only) ==="
    create_par2_volume_only "$PAR2_STEM" "$RECOVERY_PCT" "${par2_sources[@]}"
  else
    log_msg "=== Step 1-2: skipped (keeping existing PAR2; hash-only mode) ==="
  fi

  # Remove superseded sets / *.old before hashing so the new manifest stays clean.
  offer_rc=0
  offer_delete_superseded_protection || offer_rc=$?
  if (( offer_rc == 2 )); then
    JOB_OUTCOME=quit
    print_folder_done_summary
    return 2
  fi

  echo
  log_msg "=== Step 3: write hash manifest (all files including PAR2; exclude hash file itself) ==="
  hash_targets=()
  hash_rel="$(basename -- "$HASH_FILE")"
  collect_sorted_relpaths "$WORK_DIR" hash-all hash_targets "$hash_rel"
  write_hash_manifest "$HASH_FILE" "$HASH_CMD" "${hash_targets[@]}"

  JOB_OUTCOME=ok
  print_folder_done_summary
  print_run_summary
  return 0
}

if [[ "$CREATE_SCOPE" == per-subdir ]]; then
  MULTI_JOB_MODE=1
  job_dirs=()
  list_immediate_subdirs "$START_DIR" job_dirs
  ((${#job_dirs[@]} > 0)) || die "Internal error: per-subdir scope but no immediate subdirectories."

  echo "Per-subdirectory mode: ${#job_dirs[@]} job(s). Loose files in $START_DIR are ignored."
  for job_dir in "${job_dirs[@]}"; do
    set_work_directory "$job_dir"
    MULTI_JOB_TOTAL=$((MULTI_JOB_TOTAL + 1))
    job_rc=0
    run_create_job || job_rc=$?
    case "$job_rc" in
      0) MULTI_JOB_OK=$((MULTI_JOB_OK + 1)) ;;
      2)
        return_code=0
        RUN_OUTCOME=quit
        print_multi_job_summary
        finish
        ;;
      3) MULTI_JOB_SKIP=$((MULTI_JOB_SKIP + 1)) ;;
      *)
        MULTI_JOB_FAIL=$((MULTI_JOB_FAIL + 1))
        echo "Error: job failed for $job_dir (rc=$job_rc)" >&2
        ;;
    esac
  done

  print_multi_job_summary
  if (( MULTI_JOB_FAIL > 0 )); then
    return_code=1
    RUN_OUTCOME=error
  elif (( MULTI_JOB_OK == 0 && MULTI_JOB_SKIP > 0 )); then
    return_code=0
    RUN_OUTCOME=quit
  else
    return_code=0
    RUN_OUTCOME=ok
  fi
  # Summaries already printed per job.
  SUMMARY_PRINTED=1
  finish
fi

# Whole-tree mode (default).
set_work_directory "$START_DIR"
job_rc=0
run_create_job || job_rc=$?
case "$job_rc" in
  0)
    return_code=0
    RUN_OUTCOME=ok
    finish
    ;;
  2|3)
    return_code=0
    RUN_OUTCOME=quit
    finish
    ;;
  *)
    return_code=1
    RUN_OUTCOME=error
    finish
    ;;
esac
