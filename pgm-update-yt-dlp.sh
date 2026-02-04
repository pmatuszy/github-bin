#!/usr/bin/env bash
set -euo pipefail

BIN_DIR="/usr/local/bin"
SYMLINK_NAME="youtube-dl"
TEMP_NAME="yt-dlp_skasuj"
PREFIX="yt-dlp_linux-"
SLEEP_SECONDS=5

# Default is DRY-RUN; only --apply performs changes
APPLY=0
case "${1:-}" in
  ""|--dry-run) APPLY=0 ;;
  --apply|--do-it) APPLY=1 ;;
  *)
    echo "Usage: $0 [--dry-run] [--apply|--do-it]" >&2
    exit 2
    ;;
esac

DRY_RUN=$(( 1 - APPLY ))

log() {
  printf '%s %s\n' "$(date '+%Y.%m.%d %H:%M:%S')" "$*"
}

run() {
  if (( DRY_RUN )); then
    log "[DRY-RUN] $*"
  else
    log "$*"
    "$@"
  fi
}

cd "$BIN_DIR"
if (( DRY_RUN )); then
  log "Starting yt-dlp updater in DRY-RUN mode (no changes). Use --apply to execute."
else
  log "Starting yt-dlp updater in APPLY mode (will modify files)."
fi

# --- Wait for fuser ---
while true; do
  if fuser "$SYMLINK_NAME" >/dev/null 2>&1; then
    log "In use: $SYMLINK_NAME. Waiting ${SLEEP_SECONDS}s..."
    sleep "$SLEEP_SECONDS"
  else
    log "Not in use: $SYMLINK_NAME. Continuing."
    break
  fi
done

# --- Validate symlink ---
if [[ ! -L "$SYMLINK_NAME" ]]; then
  log "ERROR: $SYMLINK_NAME is not a symlink"
  exit 1
fi

CURRENT_TARGET="$(readlink "$SYMLINK_NAME")"
log "Current target: $CURRENT_TARGET"

# --- Remove symlink ---
run rm -f "$SYMLINK_NAME"

# --- Copy to temp ---
run cp -a "$CURRENT_TARGET" "$TEMP_NAME"
run chmod 0755 "$TEMP_NAME"

# --- Update temp binary ---
if (( DRY_RUN )); then
  log "[DRY-RUN] ./$TEMP_NAME --update"
  VERSION_RAW="2099.12.31"
  log "[DRY-RUN] assuming version: $VERSION_RAW"
else
  log "./$TEMP_NAME --update"
  "./$TEMP_NAME" --update
  VERSION_RAW="$("./$TEMP_NAME" --version | head -n1 | tr -d '\r' | xargs)"
fi

if [[ ! "$VERSION_RAW" =~ ^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$ ]]; then
  log "ERROR: Version '$VERSION_RAW' invalid"
  exit 1
fi

NEW_NAME="${PREFIX}${VERSION_RAW}"
log "New binary name: $NEW_NAME"

# --- Rename + relink ---
run rm -f "$NEW_NAME"
run mv "$TEMP_NAME" "$NEW_NAME"
run chmod 0755 "$NEW_NAME"
run ln -s "$NEW_NAME" "$SYMLINK_NAME"

# --- Final state ---
if (( DRY_RUN )); then
  log "[DRY-RUN] Done. Would show current state with:"
  log "[DRY-RUN] ls -l $SYMLINK_NAME $NEW_NAME"
else
  log "Done. Current state:"
  ls -l "$SYMLINK_NAME" "$NEW_NAME"
fi

