#!/bin/bash
# 2022.01.13 - v. 0.1 - initial release (date unknown)

# dobre zroda sa tutaj:
# https://gist.github.com/bpsib/67089b959e4fa898af69fea59ad74bc3

# SKAD="http://open.live.bbc.co.uk/mediaselector/5/select/version/2.0/mediaset/http-icy-mp3-a/vpid/bbc_radio_fourfm/format/pls.pls"
# SKAD="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_fourfm?s=1642067029&e=1642081429&h=b27ba5e1db5ba2f56beacf6d37b8abea"

SKAD="http://stream.live.vc.bbcmedia.co.uk/bbc_radio_fourfm"
DOKAD=/worek-samba/nagrania/BBC4/BBC4-`date '+%Y.%m.%d__%H%M%S'`.mp3

timeout=24h
kill_after=1441m
wlasciciel_pliku="che:che"

czas_nagrywania="24:01:00"
# czas_nagrywania="00:00:15"

# /usr/bin/timeout --preserve-status --kill-after=$kill_after $timeout ffmpeg -hide_banner -i "$SKAD" "$DOKAD"

ffmpeg -hide_banner -loglevel quiet -t "${czas_nagrywania}" -i "$SKAD" "$DOKAD"
chown "${wlasciciel_pliku}" "${DOKAD}"

# if [ ! -z $STY ]; then    # checking if we are running within screen

(echo "koniec wykonywania $0" && ls -lt `dirname "${DOKAD}"`) | strings | aha | mailx -r root@`hostname` -a 'Content-Type: text/html' -s "$0 (`/bin/hostname`-`date '+\%Y.\%m.\%d \%H:\%M:\%S'`)" matuszyk@matuszyk.com
# fi
