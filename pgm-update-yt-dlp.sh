#!/usr/bin/env bash

# 2026.02.04 - v. 0.1 - initial release

. /root/bin/_script_header.sh

set -euo pipefail

BIN_DIR="/usr/local/bin"
SYMLINK_NAME="youtube-dl"
TEMP_NAME="yt-dlp_skasuj"
PREFIX="yt-dlp_linux-"
SLEEP_SECONDS=5

GITHUB_LATEST_API="https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"

APPLY=0
FORCE=0

for arg in "${@:-}"; do
  case "$arg" in
    --dry-run) APPLY=0 ;;
    --apply|--do-it) APPLY=1 ;;
    --force) FORCE=1 ;;
    *) ;;
  esac
done

DRY_RUN=$(( 1 - APPLY ))

log() {
  printf '[%s] %s\n' "$(date '+%Y.%m.%d %H:%M:%S')" "$*"
}

run() {
  if (( DRY_RUN )); then
    log "[DRY-RUN] $*"
  else
    log "$*"
    "$@"
  fi
}

version_from_name() {
  local name="$1"
  [[ "$name" =~ yt-dlp_linux-([0-9]{4}\.[0-9]{2}\.[0-9]{2})$ ]] && \
    printf '%s\n' "${BASH_REMATCH[1]}"
}

is_older_version() {
  local a="${1//./}"
  local b="${2//./}"
  [[ "$a" -lt "$b" ]]
}

get_latest_version_github() {
  local json tag
  json="$(curl -fsSL "$GITHUB_LATEST_API" 2>/dev/null || true)"
  [[ -n "$json" ]] || return 1

  tag="$(printf '%s\n' "$json" | grep -m1 -E '"tag_name"' \
        | sed -E 's/.*"tag_name"\s*:\s*"([^"]+)".*/\1/')"
  printf '%s\n' "$tag"
}

cd "$BIN_DIR"

if (( DRY_RUN )); then
  log "Starting yt-dlp updater in DRY-RUN mode (use --apply to execute)"
else
  log "Starting yt-dlp updater in APPLY mode"
fi

# --- wait for fuser
while fuser "$SYMLINK_NAME" >/dev/null 2>&1; do
  log "In use: $SYMLINK_NAME. Waiting ${SLEEP_SECONDS}s..."
  sleep "$SLEEP_SECONDS"
done

log "Not in use: $SYMLINK_NAME. Continuing."

CURRENT_TARGET="$(readlink "$SYMLINK_NAME")"
log "Current target: $CURRENT_TARGET"

CURRENT_VERSION="$(version_from_name "$CURRENT_TARGET" || true)"
[[ -n "$CURRENT_VERSION" ]] && log "Current version: $CURRENT_VERSION"

if (( ! FORCE )); then
  log "Checking upstream latest version..."
  LATEST_VERSION="$(get_latest_version_github || true)"

  if [[ "$LATEST_VERSION" =~ ^[0-9]{4}\.[0-9]{2}\.[0-9]{2}$ ]]; then
    log "Latest version: $LATEST_VERSION"

    if [[ -n "$CURRENT_VERSION" ]] && \
       ! is_older_version "$CURRENT_VERSION" "$LATEST_VERSION"; then
      log "No newer version available. Exiting."
      exit 0
    fi
  else
    log "WARNING: could not determine latest version from GitHub"
  fi
else
  log "Skipping version check (--force)"
fi

run rm -f "$SYMLINK_NAME"
run cp -a "$CURRENT_TARGET" "$TEMP_NAME"
run chmod 0755 "$TEMP_NAME"

if (( DRY_RUN )); then
  VERSION_RAW="${LATEST_VERSION:-2099.12.31}"
  log "[DRY-RUN] ./$TEMP_NAME --update"
  log "[DRY-RUN] assuming version after update: $VERSION_RAW"
else
  log "./$TEMP_NAME --update"
  "./$TEMP_NAME" --update
  VERSION_RAW="$("./$TEMP_NAME" --version | head -n1 | xargs)"
fi

NEW_NAME="${PREFIX}${VERSION_RAW}"
log "New binary name: $NEW_NAME"

run rm -f "$NEW_NAME"
run mv "$TEMP_NAME" "$NEW_NAME"
run chmod 0755 "$NEW_NAME"
run ln -s "$NEW_NAME" "$SYMLINK_NAME"

if (( DRY_RUN )); then
  log "[DRY-RUN] Would show: ls -l $SYMLINK_NAME $NEW_NAME"
else
  ls -l "$SYMLINK_NAME" "$NEW_NAME"
fi

. /root/bin/_script_footer.sh

