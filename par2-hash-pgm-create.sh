#!/bin/bash
# v. 20260809.155541 - prompt to exclude rename.sh helpers from PAR2 (default yes)
# v. 20260806.224414 - initial: create volume-only PAR2 + SHA-512/MD5 hash for cwd subtree

# 2026.08.09 - v. 0.1.1 - Ask to exclude rename.sh helper files from PAR2 (default yes); still hash them
# 2026.08.06 - v. 0.1.0 - initial release: _<dir>.par2 volume set + __<dir>.sha512|md5 for whole subtree
#
# par2-hash-pgm-create.sh
#
# Create a PAR2 archive and a SHA-512 (default) or MD5 hash file for the current directory tree.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay] [options]

Create a volume-only PAR2 set and a hash manifest for the current directory
(whole subtree).

Naming (from the parent directory basename, e.g. cwd .../MyAlbum):
  PAR2 stem:  _MyAlbum.par2  (volume-only: _MyAlbum.vol….par2; index removed)
  Hash file:  __MyAlbum.sha512  (or __MyAlbum.md5)

Order:
  1) Create PAR2 for all non-empty data files under the tree
     (excludes *.par2 / backups and hash manifests *.md5|*.sha512|*.sha256).
     Optionally excludes rename.sh helper files (prompt; default yes).
  2) Write the hash file for every regular file in the tree, including the new
     PAR2 volume(s), excluding the hash file being written.
     (rename.sh helpers are still hashed even when excluded from PAR2.)

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
  --sha512             Prefer SHA-512 for the hash file (default).
  --md5                Prefer MD5 for the hash file.
  --recovery N         Recovery percent 1-100 (skips the recovery prompt).
  --exclude-rename-helpers
                       Exclude rename.sh helper files from PAR2 (no prompt).
  --include-rename-helpers
                       Include rename.sh helper files in PAR2 (no prompt).
  --yes, -y            Accept prompt defaults (hash algo, recovery, exclude
                       rename helpers = yes) without asking.
  -n, --dry-run        Show what would be done; create nothing.

Interactive prompts (unless --yes / flag already set):
  Hash algorithm: Enter accepts the preferred default (SHA-512 unless --md5).
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
  $(basename "$0") --md5 --recovery 10
  $(basename "$0") --yes
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
RECOVERY_CLI=""
AUTO_YES=0
DRY_RUN=0
# -1 = ask (default yes); 1 = exclude; 0 = include
EXCLUDE_RENAME_HELPERS_CLI=-1
EXCLUDE_RENAME_HELPERS=1
MAX_PAR2_BLOCKS=32768
return_code=0

WORK_DIR=""
DIR_NAME=""
PAR2_STEM=""
HASH_ALGO=""
HASH_EXT=""
HASH_CMD=""
HASH_FILE=""
RECOVERY_PCT=20
SCRIPT_START_STR=""
SCRIPT_START_EPOCH=0
RENAME_HELPERS_FOUND=()

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
    *.sha512|*.sha256|*.md5) return 0 ;;
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
  local preferred="${1:-sha512}"
  local ans="" def_label

  case "$preferred" in
    md5) def_label="MD5" ;;
    *) preferred="sha512"; def_label="SHA-512" ;;
  esac

  if (( AUTO_YES == 1 )); then
    HASH_ALGO="$preferred"
    return 0
  fi

  printf '%sHash algorithm [sha512|md5] (default: %s, %s): ' \
    "$(user_prompt_ts_prefix)" "$def_label" "$(prompt_timeout_label)"
  if ! read_line_with_timeout ans; then
    ans=""
    echo
  fi
  ans="${ans//[[:space:]]/}"
  ans="${ans,,}"
  [[ -z "$ans" ]] && ans="$preferred"
  case "$ans" in
    sha512|sha-512|512)
      HASH_ALGO="sha512"
      ;;
    md5)
      HASH_ALGO="md5"
      ;;
    *)
      echo "Invalid choice '$ans'; using ${def_label}."
      HASH_ALGO="$preferred"
      ;;
  esac
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
  case "$HASH_ALGO" in
    md5)
      HASH_EXT="md5"
      HASH_CMD="md5sum"
      ;;
    sha512)
      HASH_EXT="sha512"
      HASH_CMD="sha512sum"
      ;;
    *)
      die "Unsupported hash algorithm: $HASH_ALGO"
      ;;
  esac
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
  local block_count create_rc=0 index_path
  local -a vols=()

  ((${#sources[@]} > 0)) || die "No non-empty data files to protect."

  block_count=${#sources[@]}
  if (( block_count > MAX_PAR2_BLOCKS )); then
    die "${block_count} non-empty files exceeds PAR2 max block count (${MAX_PAR2_BLOCKS}). Split the tree first."
  fi

  echo "par2 create: ${#sources[@]} file(s), -b${block_count}, -r${percent}%, -n1"
  echo "  stem: ${stem}.par2 (volume-only; index removed after create)"

  if (( DRY_RUN == 1 )); then
    echo "  [dry-run] ${PAR2_CMD} create -n1 -b${block_count} -r${percent} -- ${stem}.par2 <${block_count} files>"
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
  echo "Wrote ${line_count} checksum line(s): $(basename -- "$out_file")"
}

print_run_settings() {
  echo "=== Run settings ==="
  echo "  Directory:     $WORK_DIR"
  echo "  Parent name:   $DIR_NAME"
  echo "  PAR2 stem:     ${PAR2_STEM}.par2 (volume-only)"
  echo "  Hash file:     __${DIR_NAME}.${HASH_EXT}"
  echo "  Hash algo:     ${HASH_ALGO}"
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
    --sha512)
      HASH_PREF="sha512"
      shift
      ;;
    --md5)
      HASH_PREF="md5"
      shift
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

prompt_hash_algo "${HASH_PREF:-sha512}"
apply_hash_algo

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

elapsed=$(( $(date +%s) - SCRIPT_START_EPOCH ))
echo
echo "=== Done ==="
echo "  Started:  $SCRIPT_START_STR"
echo "  Finished: $(date '+%Y.%m.%d %H:%M:%S')"
echo "  Elapsed:  $(format_elapsed "$elapsed")"
echo "  PAR2:     ${PAR2_STEM}.vol*.par2"
echo "  Hash:     $(basename -- "$HASH_FILE")"
if (( DRY_RUN == 1 )); then
  echo "  (dry-run: nothing written)"
fi

return_code=0
finish
