#!/bin/bash
# v. 20260811.095711 - add --history (paged changelog via _script_header.sh print_script_history)
# v. 20260809.170555 - end with boxed RUN SUMMARY / RUN FINISHED like par2-pgm-check
# v. 20260809.170153 - hash menu: q/Q quits immediately (no Enter)
# v. 20260809.165517 - hash menu: detect *sum tools; numbered pick; q quits; re-ask
# v. 20260809.164003 - fix -b: use enough blocks so -r% ≈ data size (not file-count)
# v. 20260809.155541 - prompt to exclude rename.sh helpers from PAR2 (default yes)
# v. 20260806.224414 - initial: create volume-only PAR2 + SHA-512/MD5 hash for cwd subtree

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
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay] [options]

Create a volume-only PAR2 set and a hash manifest for the current directory
(whole subtree).

Naming (from the parent directory basename, e.g. cwd .../MyAlbum):
  PAR2 stem:  _MyAlbum.par2  (volume-only: _MyAlbum.vol….par2; index removed)
  Hash file:  __MyAlbum.<ext>  (ext from chosen hash, e.g. .sha512 / .md5 / .b2)

Order:
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

Interactive prompts (unless --yes / flag already set):
  Hash algorithm: numbered list of *sum tools found on PATH; Enter = default;
                  q/Q = quit immediately (no Enter); invalid input asks again.
  Recovery %:     Enter accepts 20% (or --recovery value).
  Rename helpers: Exclude from PAR2? [Y/n] (default yes). Files:
                    _exclude-rename.sh.txt, _rename.sh-optional-db.sqlite3
                    (+ -wal/-shm/-journal), legacy rename.sh-optional-db.sqlite3,
                    _rename.sh.resume-state.json

Environment:
  PAR2_CMD             par2 executable (default: par2)
  PROMPT_TIMEOUT       Seconds to wait for interactive prompts (unset = no timeout)

Examples:
  cd /path/to/MyAlbum && $(basename "$0")
  $(basename "$0") --hash sha256 --recovery 10
  $(basename "$0") --md5 --yes
  $(basename "$0") --include-rename-helpers
  $(basename "$0") -n
EOF
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

PGM_HAVE_BOXES=no
if command -v boxes >/dev/null 2>&1; then
  PGM_HAVE_BOXES=yes
fi

die() {
  echo "Error: $*" >&2
  return_code=1
  RUN_OUTCOME=error
  print_run_finished_banner
  . /root/bin/_script_footer.sh
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
  . /root/bin/_script_footer.sh
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

  printf '┌%*s┐\n' "$w" '' | tr ' ' '─'
  for line in "${lines[@]}"; do
    printf '│ %-*s │\n' "$max_len" "$line"
  done
  printf '└%*s┘\n' "$w" '' | tr ' ' '─'
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
  else
    lines+=( "Mode: created PAR2 + hash manifest" )
  fi
  lines+=( "Directory: $WORK_DIR" )
  lines+=( "PAR2 stem: ${PAR2_STEM}.par2 (volume-only, -r${RECOVERY_PCT}%)" )
  if ((${#CREATED_PAR2_VOLS[@]} > 0)); then
    for vol in "${CREATED_PAR2_VOLS[@]}"; do
      lines+=( "PAR2 file: $vol" )
    done
  else
    lines+=( "PAR2 file: ${PAR2_STEM}.vol*.par2" )
  fi
  lines+=( "Protected: ${PAR2_SOURCE_COUNT} file(s), $(format_bytes_approx "$PAR2_SOURCE_BYTES")" )
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

user_prompt_ts_prefix() {
  printf '(%s) ' "$(date '+%Y.%m.%d %H:%M:%S')"
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

# First key with -n1 so q/Q can quit without Enter; then read the rest of the line
# for numbers/names. Empty first key (Enter) = default. Sets REPLY-style via nameref.
# Returns: 0 ok, 1 timeout/EOF (treat as default), 2 quit requested.
read_hash_choice_with_timeout() {
  local __var="$1"
  local first="" rest=""

  if prompt_has_timeout; then
    IFS= read -r -t "$PROMPT_TIMEOUT" -n 1 first || {
      printf -v "$__var" '%s' ""
      return 1
    }
  else
    IFS= read -r -n 1 first || {
      printf -v "$__var" '%s' ""
      return 1
    }
  fi

  case "$first" in
    q|Q)
      echo
      printf -v "$__var" '%s' "$first"
      return 2
      ;;
    ""|$'\n')
      printf -v "$__var" '%s' ""
      return 0
      ;;
  esac

  # Echo the first char (read -n 1 is silent) then finish the line.
  printf '%s' "$first"
  if prompt_has_timeout; then
    IFS= read -r -t "$PROMPT_TIMEOUT" rest || rest=""
  else
    IFS= read -r rest || rest=""
  fi
  printf -v "$__var" '%s' "${first}${rest}"
  return 0
}

is_par2_backup_basename() {
  local base="$1"
  case "$base" in
    *_old.par2|*_old.PAR2) return 0 ;;
    *.par2.old|*.PAR2.old|*.par2.OLD|*.PAR2.OLD) return 0 ;;
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

# Files protected by the new PAR2 set (excludes PAR2 archives and hash manifests).
is_par2_source_basename() {
  local base="$1"
  case "$base" in
    *.par2|*.PAR2) return 1 ;;
    *_old.par2|*_old.PAR2) return 1 ;;
    *.par2.old|*.PAR2.old|*.par2.OLD|*.PAR2.OLD) return 1 ;;
  esac
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
    echo "Invalid choice '$ans'. Enter a number 1-${n}, a hash name, Enter for default, or q to quit."
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

  printf '%sRecovery percent for PAR2 set [1-100] (default: %s%%, %s): ' \
    "$(user_prompt_ts_prefix)" "$suggested" "$(prompt_timeout_label)"
  if ! read_line_with_timeout ans; then
    ans=""
    echo
  fi
  ans="${ans//[[:space:]]/}"
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

  printf '%sExclude rename.sh helper files from the PAR2 set? [Y/n] (%s): ' \
    "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
  if ! read_line_with_timeout ans; then
    ans=""
    echo
  fi
  ans="${ans//[[:space:]]/}"
  ans="${ans,,}"
  case "$ans" in
    ""|y|yes)
      EXCLUDE_RENAME_HELPERS=1
      ;;
    n|no)
      EXCLUDE_RENAME_HELPERS=0
      ;;
    *)
      echo "Invalid choice '$ans'; excluding helpers (default yes)."
      EXCLUDE_RENAME_HELPERS=1
      ;;
  esac
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

backup_existing_stem_par2() {
  local -a members=("$@")
  local src dst base
  local -a backed=()

  for src in "${members[@]}"; do
    base="$(basename -- "$src")"
    dst="${src}.old"
    if [[ -e "$dst" ]]; then
      die "Backup already exists: $(basename -- "$dst") (remove/rename it first)."
    fi
    if (( DRY_RUN == 1 )); then
      printf '  [dry-run] mv -- %q %q\n' "$src" "$dst"
      continue
    fi
    mv -- "$src" "$dst" || die "Failed to rename $base to $(basename -- "$dst")."
    printf '  %s -> %s\n' "$base" "$(basename -- "$dst")"
    backed+=("$dst")
  done
}

create_par2_volume_only() {
  local stem="$1"
  local percent="$2"
  shift 2
  local -a sources=("$@")
  local block_count create_rc=0 index_path total_bytes=0 approx_block=0 approx_recovery=0
  local -a vols=()

  ((${#sources[@]} > 0)) || die "No non-empty data files to protect."

  if ((${#sources[@]} > MAX_PAR2_BLOCKS)); then
    die "${#sources[@]} non-empty files exceeds PAR2 max block count (${MAX_PAR2_BLOCKS}). Split the tree first."
  fi

  total_bytes="$(sum_source_bytes "$WORK_DIR" "${sources[@]}")"
  block_count="$(choose_par2_block_count "${#sources[@]}" "$total_bytes")"
  [[ "$block_count" =~ ^[1-9][0-9]*$ ]] || die "Could not choose a PAR2 block count."

  PAR2_SOURCE_COUNT=${#sources[@]}
  PAR2_SOURCE_BYTES=$total_bytes
  CREATED_PAR2_VOLS=()

  approx_block=$(( (total_bytes + block_count - 1) / block_count ))
  approx_recovery=$(( total_bytes * percent / 100 ))

  echo "par2 create: ${#sources[@]} file(s), -b${block_count}, -r${percent}%, -n1"
  echo "  source data:   $(format_bytes_approx "$total_bytes") (${total_bytes} bytes)"
  echo "  ~block size:   $(format_bytes_approx "$approx_block")"
  echo "  ~recovery size:$(format_bytes_approx "$approx_recovery") (about ${percent}% of source)"
  echo "  stem: ${stem}.par2 (volume-only; index removed after create)"

  if (( DRY_RUN == 1 )); then
    echo "  [dry-run] ${PAR2_CMD} create -n1 -b${block_count} -r${percent} -- ${stem}.par2 <${#sources[@]} files>"
    CREATED_PAR2_VOLS=( "${stem}.vol*.par2 (dry-run)" )
    return 0
  fi

  (
    cd "$WORK_DIR" || exit 1
    "$PAR2_CMD" create -n1 -b"$block_count" -r"$percent" -- "${stem}.par2" "${sources[@]}"
  )
  create_rc=$?
  (( create_rc == 0 )) || die "par2 create failed (exit ${create_rc})."

  index_path="${WORK_DIR}/${stem}.par2"
  shopt -s nullglob
  vols=("${WORK_DIR}/${stem}".vol*.par2 "${WORK_DIR}/${stem}".vol*.PAR2)
  shopt -u nullglob

  if ((${#vols[@]} == 0)); then
    [[ -f "$index_path" ]] && rm -f -- "$index_path"
    die "par2 create did not produce a volume file for ${stem}."
  fi

  if [[ -f "$index_path" ]]; then
    rm -f -- "$index_path"
    echo "Removed index ${stem}.par2 (keeping volume-only set)."
  fi

  echo "New PAR2 volume(s):"
  for f in "${vols[@]}"; do
    printf '  %s\n' "$(basename -- "$f")"
    CREATED_PAR2_VOLS+=( "$(basename -- "$f")" )
  done
}

write_hash_manifest() {
  local out_file="$1"
  local algo_cmd="$2"
  shift 2
  local -a rels=("$@")
  local rel digest tmp line_count=0

  ((${#rels[@]} > 0)) || die "No files to hash."

  echo "Hashing ${#rels[@]} file(s) with ${algo_cmd} -> $(basename -- "$out_file")"

  if (( DRY_RUN == 1 )); then
    echo "  [dry-run] would write ${#rels[@]} lines to $(basename -- "$out_file")"
    HASH_ENTRY_COUNT=${#rels[@]}
    return 0
  fi

  command -v "$algo_cmd" >/dev/null 2>&1 || die "'$algo_cmd' not found."

  tmp=$(mktemp "${TMPDIR:-/tmp}/par2-hash-pgm-create.XXXXXX") || die "mktemp failed."

  for rel in "${rels[@]}"; do
    if [[ ! -f "${WORK_DIR}/${rel}" ]]; then
      rm -f -- "$tmp"
      die "Missing file while hashing: $rel"
    fi
    digest="$("$algo_cmd" -- "${WORK_DIR}/${rel}" | awk '{print tolower($1)}')"
    if [[ -z "$digest" ]]; then
      rm -f -- "$tmp"
      die "Failed to hash: $rel"
    fi
    # GNU *sum -c binary form: one space then '*', then relative path.
    printf '%s *%s\n' "$digest" "$rel" >>"$tmp"
    ((++line_count))
    if (( line_count % 100 == 0 )); then
      printf '  ... hashed %d / %d\n' "$line_count" "${#rels[@]}"
    fi
  done

  if ! mv -- "$tmp" "$out_file"; then
    rm -f -- "$tmp"
    die "Failed to write $out_file"
  fi
  HASH_ENTRY_COUNT=$line_count
  echo "Wrote ${line_count} checksum line(s): $(basename -- "$out_file")"
}

print_run_settings() {
  echo "=== Run settings ==="
  echo "  Directory:     $WORK_DIR"
  echo "  Parent name:   $DIR_NAME"
  echo "  PAR2 stem:     ${PAR2_STEM}.par2 (volume-only)"
  echo "  Hash file:     __${DIR_NAME}.${HASH_EXT}"
  echo "  Hash algo:     ${HASH_LABEL} (${HASH_CMD})"
  echo "  Recovery:      ${RECOVERY_PCT}%"
  if (( EXCLUDE_RENAME_HELPERS == 1 )); then
    echo "  Rename helpers: excluded from PAR2 (still hashed)"
  else
    echo "  Rename helpers: included in PAR2"
  fi
  echo "  PAR2_CMD:      $PAR2_CMD"
  if (( DRY_RUN == 1 )); then
    echo "  Mode:          dry-run (no changes)"
  elif (( AUTO_YES == 1 )); then
    echo "  Mode:          --yes (defaults accepted)"
  else
    echo "  Mode:          interactive"
  fi
  echo
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

WORK_DIR="$(pwd -P)"
DIR_NAME="$(basename -- "$WORK_DIR")"
[[ -n "$DIR_NAME" && "$DIR_NAME" != "/" && "$DIR_NAME" != "." ]] \
  || die "Cannot derive a usable parent directory name from: $WORK_DIR"

PAR2_STEM="_${DIR_NAME}"
SCRIPT_START_EPOCH=$(date +%s)
SCRIPT_START_STR="$(date '+%Y.%m.%d %H:%M:%S')"

prompt_hash_algo "${HASH_PREF:-}"

if [[ -n "$RECOVERY_CLI" ]]; then
  RECOVERY_PCT="$RECOVERY_CLI"
else
  prompt_recovery_percent 20
fi

prompt_exclude_rename_helpers

print_run_settings

# Existing PAR2 for this stem?
existing_par2=()
list_existing_stem_par2 "$WORK_DIR" "$PAR2_STEM" existing_par2
if ((${#existing_par2[@]} > 0)); then
  echo "Existing PAR2 file(s) for stem ${PAR2_STEM}:"
  for f in "${existing_par2[@]}"; do
    printf '  %s\n' "$(basename -- "$f")"
  done
  if (( AUTO_YES == 1 )); then
    echo "Renaming them to *.par2.old (--yes)."
    backup_existing_stem_par2 "${existing_par2[@]}"
  else
    ans=""
    printf '%sRename existing PAR2 to *.par2.old and continue? [Y/n] (%s): ' \
      "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
    if ! read_line_with_timeout ans; then
      ans=""
      echo
    fi
    ans="${ans//[[:space:]]/}"
    ans="${ans,,}"
    case "$ans" in
      ""|y|yes)
        backup_existing_stem_par2 "${existing_par2[@]}"
        ;;
      *)
        echo "Aborted (existing PAR2 left unchanged)."
        return_code=0
        RUN_OUTCOME=quit
        finish
        ;;
    esac
  fi
  echo
fi

# Existing hash file?
if [[ -e "$HASH_FILE" ]]; then
  echo "Hash file already exists: $(basename -- "$HASH_FILE")"
  if (( AUTO_YES == 1 )); then
    echo "Will overwrite (--yes)."
  else
    ans=""
    printf '%sOverwrite existing hash file? [Y/n] (%s): ' \
      "$(user_prompt_ts_prefix)" "$(prompt_timeout_label)"
    if ! read_line_with_timeout ans; then
      ans=""
      echo
    fi
    ans="${ans//[[:space:]]/}"
    ans="${ans,,}"
    case "$ans" in
      ""|y|yes)
        ;;
      *)
        echo "Aborted (hash file left unchanged)."
        return_code=0
        RUN_OUTCOME=quit
        finish
        ;;
    esac
  fi
  echo
fi

echo "=== Step 1: collect PAR2 source files (subtree; exclude PAR2 + hash manifests) ==="
par2_sources=()
collect_sorted_relpaths "$WORK_DIR" par2-sources par2_sources
if (( EXCLUDE_RENAME_HELPERS == 1 )); then
  if ((${#RENAME_HELPERS_FOUND[@]} == 0)); then
    find_rename_helpers "$WORK_DIR" RENAME_HELPERS_FOUND
  fi
  if ((${#RENAME_HELPERS_FOUND[@]} > 0)); then
    echo "Excluding ${#RENAME_HELPERS_FOUND[@]} rename.sh helper file(s) from PAR2:"
    for rel in "${RENAME_HELPERS_FOUND[@]}"; do
      printf '  %s\n' "$rel"
    done
  fi
fi
echo "Found ${#par2_sources[@]} non-empty data file(s) to protect."
((${#par2_sources[@]} > 0)) || die "No data files to protect under: $WORK_DIR"

echo
echo "=== Step 2: create PAR2 (volume-only) ==="
create_par2_volume_only "$PAR2_STEM" "$RECOVERY_PCT" "${par2_sources[@]}"

echo
echo "=== Step 3: write hash manifest (all files including PAR2; exclude hash file itself) ==="
hash_targets=()
hash_rel="$(basename -- "$HASH_FILE")"
collect_sorted_relpaths "$WORK_DIR" hash-all hash_targets "$hash_rel"
write_hash_manifest "$HASH_FILE" "$HASH_CMD" "${hash_targets[@]}"

RUN_OUTCOME=ok
return_code=0
finish
