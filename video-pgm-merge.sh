#!/bin/bash

# 2026.05.26 - v. 0.2 - renamed from gopro-mp4-merge.sh
# 2026.05.26 - v. 0.1 - merge GoPro chapter MP4s (Windows merge-gopro batch port)

set -o nounset
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

find_merger() {
  if [[ -n "${MP4_MERGE_BIN:-}" && -x "${MP4_MERGE_BIN}" ]]; then
    printf '%s\n' "${MP4_MERGE_BIN}"
    return 0
  fi
  local name
  for name in mp4_merge-linux64 mp4_merge-linux mp4_merge; do
    if [[ -x "./${name}" ]]; then
      printf '%s\n' "./${name}"
      return 0
    fi
    if [[ -x "${SCRIPT_DIR}/${name}" ]]; then
      printf '%s\n' "${SCRIPT_DIR}/${name}"
      return 0
    fi
  done
  return 1
}

MERGER=$(find_merger) || {
  echo "(PGM) mp4_merge not found in . or ${SCRIPT_DIR}/" >&2
  echo "(PGM) Expected one of: mp4_merge-linux64, mp4_merge-linux, mp4_merge" >&2
  echo "(PGM) Or set MP4_MERGE_BIN=/path/to/mp4_merge" >&2
  exit 1
}

shopt -s nullglob nocaseglob
mp4_files=( *.mp4 )
shopt -u nocaseglob

if (( ${#mp4_files[@]} == 0 )); then
  echo "(PGM) No *.mp4 files in $(pwd)" >&2
  exit 1
fi

# Output basename from the highest part number (first in reverse sort, like dir /o-n)
top_file=$(printf '%s\n' "${mp4_files[@]}" | LC_ALL=C sort -r | head -n1)
file_base="${top_file%.*}"

# Merge list in ascending order (like dir /o:n)
mapfile -t merge_files < <(printf '%s\n' "${mp4_files[@]}" | LC_ALL=C sort)

clear 2>/dev/null || true
echo "Merging video chapters:"
printf ' %q' "${merge_files[@]}"
echo
echo

"${MERGER}" "${merge_files[@]}" --out "${file_base}_concat.mp4"
kod_powrotu=$?

echo
if (( kod_powrotu == 0 )); then
  echo "Done!"
else
  echo "Merge failed (exit ${kod_powrotu})."
fi

if tty -s </dev/tty 2>/dev/null; then
  read -r -p "Press Enter to continue..."
fi

exit "${kod_powrotu}"
