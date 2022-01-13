SKAD="http://gdansk1-1.radio.pionier.net.pl:8000/pl/tuba10-1.mp3"
DOKAD=/worek-samba/TokFM-nagrania/tokFM-`date '+%Y.%m.%d__%H%M%S'`.mp3

timeout=24h
kill_after=1441m

# /usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout ffmpeg -hide_banner -i "$SKAD" "$DOKAD"
ffmpeg -hide_banner -t 24:00:30 -i "$SKAD" "$DOKAD"
