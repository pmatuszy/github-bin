#!/bin/bash
# 2022.01.13 - v. 0.1 - initial release (date unknown)

SKAD="http://gdansk1-1.radio.pionier.net.pl:8000/pl/tuba10-1.mp3"
DOKAD=/worek-samba/nagrania/TokFM-nagrania/tokFM-`date '+%Y.%m.%d__%H%M%S'`.mp3

timeout=24h
kill_after=1441m
wlasciciel_pliku="che:che"

czas_nagrywania="24:01:00"
# czas_nagrywania="00:00:15"

# /usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout ffmpeg -hide_banner -i "$SKAD" "$DOKAD"

ffmpeg -hide_banner -loglevel quiet -t "${czas_nagrywania}" -i "$SKAD" "$DOKAD"
chown "${wlasciciel_pliku}" "${DOKAD}"
