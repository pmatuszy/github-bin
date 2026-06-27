#!/bin/bash

# 2026.06.27 - v. 1.1 - print full [feeds.NAME-] config block (TOML) for yt feed tools
# 2026.06.27 - v. 1.0 - resolve YouTube @handle to channel /videos URL

set -o nounset
set -o pipefail

usage() {
  cat <<'EOF'
Usage: znajdz-id-kanalu.sh CHANNEL_HANDLE

CHANNEL_HANDLE  YouTube handle with or without leading @ (e.g. SomeChannel or @SomeChannel).

Prints the channel /videos URL and a ready-to-paste [feeds.NAME-] config block.
NAME is derived from the handle (safe for TOML table keys).
EOF
}

feed_key_from_handle() {
  local handle="$1"
  local key
  key="$(printf '%s' "$handle" | sed -E 's/[^A-Za-z0-9._-]+/_/g; s/^_+//; s/_+$//')"
  [[ -n "$key" ]] || key='channel'
  printf '%s' "$key"
}

resolve_channel_id() {
  local handle="$1"
  curl -D- --silent "https://www.youtube.com/@${handle}" \
    | tr ',' '\n' \
    | grep -i 'externalId' \
    | sed 's|.*:||g' \
    | tr -d '"' \
    | head -n1
}

print_feed_config() {
  local feed_key="$1" url="$2"
  cat <<EOF

[feeds.${feed_key}-]
url = "${url}"
page_size = 40
quality = "high"
format = "audio"
update_period = "12h"
filters = { min_duration = 180, max_age = 180}
max_height = 720
youtube_dl_args = [ "--js-runtimes", "deno:/usr/local/bin/deno", "--cookies-from-browser", "firefox" ]
EOF
}

handle="${1:-}"
handle="${handle#@}"

if [[ -z "$handle" ]]; then
  usage >&2
  exit 1
fi

kanal_id="$(resolve_channel_id "$handle")"
if [[ -z "$kanal_id" ]]; then
  echo "ERROR: could not resolve channel id for @${handle}" >&2
  exit 1
fi

feed_key="$(feed_key_from_handle "$handle")"
url="https://www.youtube.com/channel/${kanal_id}/videos"

echo
echo "       ${url}"
print_feed_config "$feed_key" "$url"
