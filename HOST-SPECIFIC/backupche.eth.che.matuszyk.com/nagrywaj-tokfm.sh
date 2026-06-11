#!/bin/bash

# 2026.06.11 - v. 1.4 - print ffmpeg path/version at start; FFMPEG_BIN; mkdir output dir; -nostdin; quote vars
# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.07.08 - v. 1.3 - bugfix: forced aktualny dzien to be a number in 10 base
# 2023.05.22 - v. 1.2 - added NO_STARTUP_DELAY parameters to /root/bin/_script_header.sh
# 2023.05.16 - v. 1.1 - bugfix: functional change of the script
# 2023.05.15 - v. 1.0 - bugfix: functional change of the script
# 2023.04.11 - v. 0.9 - bugfix: removed second invocation of /root/bin/_script_header.sh
# 2023.02.14 - v. 0.8 - removed sending of healthchecks status
# 2022.05.23 - v. 0.7 - dodane 2>/dev/null po wywolaniu curl by nie dostawac maili z crona o timeoucie
# 2022.05.16 - v. 0.6 - eliminacja curla by nie startowac "$url/start" 2x, poprawne badanie kodu powrotu ffmpeg przez dodanie exit $?
# 2022.05.10 - v. 0.5 - dodalem obsluge healthchecks
# 2022.02.04 - v. 0.4 - jak ffmpeg skonczy sie przedwczesnie to wprowadzilem opoznienie 60s, by nie podejmowac proby od razu po niepowodzeniu
# 2022.01.30 - v. 0.3 - zmiana sprawdzania czy dzialamy interaktywnie
# 2022.01.26 - v. 0.2 - jak ffmpeg sie skonczy wczesniej to restartujemy nagrywanie do polnocy + 1 minuta
# 2022.01.13 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh --no_startup_delay

# SKAD="http://gdansk1-1.radio.pionier.net.pl:8000/pl/tuba10-1.mp3"
SKAD="http://poznan5-4.radio.pionier.net.pl:8000/tuba10-1.mp3"
export DOKAD_PREFIX="/worek-samba/nagrania/TokFM-nagrania/tokFM"
DOKAD_DIR="$(dirname -- "${DOKAD_PREFIX}")"

wlasciciel_pliku="che:che"
opoznienie_miedzy_wywolaniami=60s
ile_wiecej_sek_nagrywac=120
ile_sek_przed_polnoca_nie_nagrywamy_juz=10

log_file="/tmp/$(basename "$0")_$(date '+%Y.%m.%d__%H%M%S').log"

resolve_ffmpeg_bin() {
    local candidate=""

    if [[ -n "${FFMPEG_BIN:-}" && -x "${FFMPEG_BIN}" ]]; then
        echo "${FFMPEG_BIN}"
        return 0
    fi
    for candidate in /usr/local/bin/ffmpeg /usr/bin/ffmpeg; do
        if [[ -x "${candidate}" ]]; then
            echo "${candidate}"
            return 0
        fi
    done
    command -v ffmpeg 2>/dev/null || return 1
}

print_ffmpeg_in_use() {
    local ffmpeg_bin="" resolved="" version_line=""

    ffmpeg_bin="$(resolve_ffmpeg_bin)" || {
        echo "ERROR: ffmpeg not found (set FFMPEG_BIN or install ffmpeg)." | tee -a "${log_file}" >&2
        exit 1
    }
    FFMPEG_BIN="${ffmpeg_bin}"
    resolved="$(readlink -f "${ffmpeg_bin}" 2>/dev/null || echo "${ffmpeg_bin}")"
    version_line="$("${ffmpeg_bin}" -hide_banner -version 2>/dev/null | head -n1)"
    echo "ffmpeg in use: ${resolved}"
    echo "  ${version_line}"
    echo "ffmpeg in use: ${resolved}" >> "${log_file}"
    echo "  ${version_line}" >> "${log_file}"
}

mkdir -p "${DOKAD_DIR}" || {
    echo "ERROR: cannot create output directory ${DOKAD_DIR}" | tee -a "${log_file}" >&2
    exit 1
}

print_ffmpeg_in_use | tee -a "${log_file}"

dzien_wywolania=$(date '+%d')
aktualny_dzien=${dzien_wywolania}

echo "0. $(date '+%Y.%m.%d__%H:%M:%S') dzien_wywolania = ${dzien_wywolania} , aktualny_dzien = ${aktualny_dzien}" | tee -a "${log_file}"

secs_to_midnight=$(( $(date -d "tomorrow 00:00" +%s) - $(date +%s) ))
echo "1. $(date '+%Y.%m.%d__%H:%M:%S') secs_to_midnight = ${secs_to_midnight}" | tee -a "${log_file}"

while (( secs_to_midnight > ile_sek_przed_polnoca_nie_nagrywamy_juz )) && (( 10#${dzien_wywolania} == 10#${aktualny_dzien} )); do
    # 10# forces day-of-month as decimal (08 would otherwise be invalid octal in arithmetic)
    echo "2. $(date '+%Y.%m.%d__%H:%M:%S') (loop start) secs_to_midnight = ${secs_to_midnight}" | tee -a "${log_file}"
    echo "2. $(date '+%Y.%m.%d__%H:%M:%S') dzien_wywolania = ${dzien_wywolania} , aktualny_dzien = ${aktualny_dzien}" | tee -a "${log_file}"

    secs_nagrywania=$(( secs_to_midnight + ile_wiecej_sek_nagrywac ))
    DOKAD="${DOKAD_PREFIX}-$(date '+%Y.%m.%d__%H%M%S').mp3"
    echo "${FFMPEG_BIN} -hide_banner -loglevel quiet -nostdin -t ${secs_nagrywania} -i \"${SKAD}\" \"${DOKAD}\"" | tee -a "${log_file}"
    "${FFMPEG_BIN}" -hide_banner -loglevel quiet -nostdin -t "${secs_nagrywania}" -i "${SKAD}" "${DOKAD}" 2>>"${log_file}"

    kod_powrotu=$?
    chown "${wlasciciel_pliku}" "${DOKAD}" 2>/dev/null
    echo "$(date '+%Y.%m.%d__%H:%M:%S') exit code is ${kod_powrotu}" | tee -a "${log_file}"
    if (( kod_powrotu != 0 )); then
        echo "$(date '+%Y.%m.%d__%H:%M:%S') WARNING: ffmpeg exited non-zero; retrying after ${opoznienie_miedzy_wywolaniami}" | tee -a "${log_file}" >&2
    fi

    secs_to_midnight=$(( $(date -d "tomorrow 00:00" +%s) - $(date +%s) ))
    echo "3. $(date '+%Y.%m.%d__%H:%M:%S') (loop end) secs_to_midnight = ${secs_to_midnight}" | tee -a "${log_file}"
    sleep "${opoznienie_miedzy_wywolaniami}"
    aktualny_dzien=$(date '+%d')
    echo "4. $(date '+%Y.%m.%d__%H:%M:%S') dzien_wywolania = ${dzien_wywolania} , aktualny_dzien = ${aktualny_dzien}" | tee -a "${log_file}"
done

echo "$(date '+%Y.%m.%d__%H:%M:%S') finished running $0" | tee -a "${log_file}"
. /root/bin/_script_footer.sh
