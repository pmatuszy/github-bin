#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.06.12 - v. 1.14 - partial files use .partial.mp3 (ffmpeg needs .mp3 extension); log ffmpeg stderr on failure
# 2026.06.11 - v. 1.13 - write .part files in output directory, not /tmp
# 2026.06.11 - v. 1.12 - disk check uses /bin/df when df is a shell function
# 2026.06.11 - v. 1.11 - remove return_code; use exit_code only
# 2026.06.11 - v. 1.10 - translate remaining Polish changelog comments; drop legacy SKAD/DOKAD env names
# 2026.06.11 - v. 1.9 - rename Polish config/internal variables to English names
# 2026.06.11 - v. 1.8 - flock, partial files, disk check, stream failover/probe, traps, summary
# 2026.06.11 - v. 1.7 - -c copy / -t after -i (input -c treats copy as decoder); reconnect for live HTTP
# 2026.06.11 - v. 1.6 - -c copy: official static ffmpeg 8.x has no mp3 encoder (stream is already mp3)
# 2026.06.11 - v. 1.5 - bugfix: FFMPEG_BIN lost when print_ffmpeg_in_use was piped to tee (subshell + nounset)
# 2026.06.11 - v. 1.4 - print ffmpeg path/version at start; FFMPEG_BIN; mkdir output dir; -nostdin; quote vars
# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.07.08 - v. 1.3 - bugfix: force day-of-month as base-10 in arithmetic (08 is invalid octal)
# 2023.05.22 - v. 1.2 - added NO_STARTUP_DELAY parameters to /root/bin/_script_header.sh
# 2023.05.16 - v. 1.1 - bugfix: functional change of the script
# 2023.05.15 - v. 1.0 - bugfix: functional change of the script
# 2023.04.11 - v. 0.9 - bugfix: removed second invocation of /root/bin/_script_header.sh
# 2023.02.14 - v. 0.8 - removed sending of healthchecks status
# 2022.05.23 - v. 0.7 - append 2>/dev/null to curl so cron does not email on timeout
# 2022.05.16 - v. 0.6 - remove curl to avoid starting "$url/start" twice; check ffmpeg exit code via exit $?
# 2022.05.10 - v. 0.5 - add healthchecks support
# 2022.02.04 - v. 0.4 - on premature ffmpeg exit, wait 60s before retrying
# 2022.01.30 - v. 0.3 - change interactive-session detection
# 2022.01.26 - v. 0.2 - on early ffmpeg exit, restart recording until midnight + 1 minute
# 2022.01.13 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh --no_startup_delay

STREAM_URL="${STREAM_URL:-http://poznan5-4.radio.pionier.net.pl:8000/tuba10-1.mp3}"
STREAM_URL_FALLBACK="${STREAM_URL_FALLBACK:-http://gdansk1-1.radio.pionier.net.pl:8000/pl/tuba10-1.mp3}"
export OUTPUT_PREFIX="${OUTPUT_PREFIX:-/worek-samba/nagrania/TokFM-nagrania/tokFM}"
OUTPUT_DIR="$(dirname -- "${OUTPUT_PREFIX}")"
LOCK_FILE="${LOCK_FILE:-/tmp/nagrywaj-tokfm.lock}"

FILE_OWNER="${FILE_OWNER:-che:che}"
RETRY_DELAY="${RETRY_DELAY:-60s}"
EXTRA_SECONDS_AFTER_MIDNIGHT="${EXTRA_SECONDS_AFTER_MIDNIGHT:-120}"
SECONDS_BEFORE_MIDNIGHT_STOP="${SECONDS_BEFORE_MIDNIGHT_STOP:-10}"

MIN_FREE_KB="${MIN_FREE_KB:-1048576}"
MIN_SUCCESS_BYTES="${MIN_SUCCESS_BYTES:-65536}"
MAX_CONSECUTIVE_FAILURES="${MAX_CONSECUTIVE_FAILURES:-10}"
LOG_RETENTION_DAYS="${LOG_RETENTION_DAYS:-14}"
STREAM_PROBE_TIMEOUT="${STREAM_PROBE_TIMEOUT:-15}"
HTTP_TIMEOUT_US="${HTTP_TIMEOUT_US:-15000000}"

LOG_FILE="/tmp/$(basename "$0")_$(date '+%Y.%m.%d__%H%M%S').log"
FFMPEG_BIN="${FFMPEG_BIN:-}"
SCRIPT_START_TIME="$(date '+%Y-%m-%d %H:%M:%S')"

segments_ok=0
segments_failed=0
consecutive_failures=0
bytes_recorded_total=0
exit_code=0
CURRENT_PART=""
ACTIVE_STREAM_URL=""
LOCK_FD=9
DF_FUNCTION_NOTE_LOGGED=0

log_line() {
    echo "$1" | tee -a "${LOG_FILE}"
}

cleanup_partial_recording() {
    if [[ -n "${CURRENT_PART:-}" && -f "${CURRENT_PART}" ]]; then
        log_line "$(date '+%Y.%m.%d__%H:%M:%S') removing incomplete partial file ${CURRENT_PART}"
        rm -f "${CURRENT_PART}"
    fi
    CURRENT_PART=""
}

cleanup_on_signal() {
    log_line "$(date '+%Y.%m.%d__%H:%M:%S') received signal, stopping (partial recording discarded)"
    cleanup_partial_recording
    exit_code=130
    print_summary
    exit "${exit_code}"
}

trap cleanup_on_signal INT TERM

prune_old_logs() {
    find /tmp -maxdepth 1 -name "$(basename "$0")_*.log" -mtime +"${LOG_RETENTION_DAYS}" -delete 2>/dev/null || true
}

acquire_lock() {
    exec {LOCK_FD}>"${LOCK_FILE}"
    if ! flock -n "${LOCK_FD}"; then
        echo "Another instance is already running (lock: ${LOCK_FILE}). Exiting."
        exit 0
    fi
}

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
        echo "ERROR: ffmpeg not found (set FFMPEG_BIN or install ffmpeg)." | tee -a "${LOG_FILE}" >&2
        exit 1
    }
    FFMPEG_BIN="${ffmpeg_bin}"
    resolved="$(readlink -f "${ffmpeg_bin}" 2>/dev/null || echo "${ffmpeg_bin}")"
    version_line="$("${ffmpeg_bin}" -hide_banner -version 2>/dev/null | head -n1)"
    log_line "ffmpeg in use: ${resolved}"
    log_line "  ${version_line}"
}

resolve_df_bin() {
    if [[ "$(type -t df 2>/dev/null)" == "function" ]]; then
        if [[ -x /bin/df ]]; then
            echo "/bin/df"
            return 0
        fi
        return 1
    fi
    if [[ -x /bin/df ]]; then
        echo "/bin/df"
        return 0
    fi
    command -v df 2>/dev/null || return 1
}

check_disk_space() {
    local target_dir="$1"
    local avail_kb=""
    local df_bin=""

    df_bin="$(resolve_df_bin)" || {
        log_line "ERROR: cannot find df binary (df is a shell function and /bin/df is missing)"
        return 1
    }
    if [[ "$(type -t df 2>/dev/null)" == "function" && DF_FUNCTION_NOTE_LOGGED -eq 0 ]]; then
        log_line "df is a shell function; using ${df_bin} for disk space check"
        DF_FUNCTION_NOTE_LOGGED=1
    fi

    avail_kb="$("${df_bin}" -Pk -- "${target_dir}" 2>/dev/null | awk 'NR==2 {print $4}')"
    if [[ -z "${avail_kb}" || ! "${avail_kb}" =~ ^[0-9]+$ ]]; then
        log_line "ERROR: cannot determine free disk space for ${target_dir}"
        return 1
    fi
    if (( avail_kb < MIN_FREE_KB )); then
        log_line "ERROR: low disk space on ${target_dir}: ${avail_kb} KiB free, need at least ${MIN_FREE_KB} KiB"
        return 1
    fi
    log_line "disk space OK on ${target_dir}: ${avail_kb} KiB free (minimum ${MIN_FREE_KB} KiB)"
    return 0
}

probe_stream_url() {
    local url="$1"

    if command -v curl >/dev/null 2>&1; then
        curl -fsS --max-time "${STREAM_PROBE_TIMEOUT}" -I "${url}" >/dev/null 2>&1 && return 0
    fi
    if [[ -n "${FFMPEG_BIN:-}" && -x "${FFMPEG_BIN}" ]]; then
        "${FFMPEG_BIN}" -hide_banner -loglevel error -nostdin \
            -timeout "${HTTP_TIMEOUT_US}" -rw_timeout "${HTTP_TIMEOUT_US}" \
            -i "${url}" -t 1 -f null - >/dev/null 2>&1 && return 0
    fi
    return 1
}

resolve_stream_url() {
    local url=""

    for url in "${STREAM_URL}" "${STREAM_URL_FALLBACK}"; do
        [[ -z "${url}" ]] && continue
        if probe_stream_url "${url}"; then
            echo "${url}"
            return 0
        fi
        log_line "$(date '+%Y.%m.%d__%H:%M:%S') stream probe failed: ${url}"
    done
    return 1
}

file_size_bytes() {
    local path="$1"
    local size=""

    size="$(stat -c '%s' "${path}" 2>/dev/null || echo 0)"
    [[ "${size}" =~ ^[0-9]+$ ]] || size=0
    echo "${size}"
}

partial_output_path() {
    printf '%s.partial.mp3' "${1%.mp3}"
}

finalize_recording() {
    local part_path="$1"
    local final_path="$2"
    local part_size=0

    part_size="$(file_size_bytes "${part_path}")"
    if (( part_size < MIN_SUCCESS_BYTES )); then
        log_line "$(date '+%Y.%m.%d__%H:%M:%S') recording too small (${part_size} bytes < ${MIN_SUCCESS_BYTES}), discarding ${part_path}"
        rm -f "${part_path}"
        return 1
    fi

    mv -f "${part_path}" "${final_path}"
    chown "${FILE_OWNER}" "${final_path}" 2>/dev/null || true
    log_line "$(date '+%Y.%m.%d__%H:%M:%S') saved ${final_path} (${part_size} bytes)"
    bytes_recorded_total=$(( bytes_recorded_total + part_size ))
    return 0
}

run_ffmpeg_recording() {
    local stream_url="$1"
    local duration_sec="$2"
    local part_path="$3"
    local ffmpeg_stderr="" ffmpeg_rc=0

    local -a ffmpeg_cmd=(
        "${FFMPEG_BIN}"
        -hide_banner -loglevel error -nostdin -y
        -reconnect 1 -reconnect_streamed 1 -reconnect_at_eof 1 -reconnect_delay_max 5
        -timeout "${HTTP_TIMEOUT_US}" -rw_timeout "${HTTP_TIMEOUT_US}"
        -i "${stream_url}"
        -t "${duration_sec}"
        -map 0:a:0
        -c copy
        -fflags +genpts
        -f mp3
        "${part_path}"
    )

    printf -v ffmpeg_cmd_line '%q ' "${ffmpeg_cmd[@]}"
    log_line "${ffmpeg_cmd_line}"

    ffmpeg_stderr="$(mktemp)"
    "${ffmpeg_cmd[@]}" 2>"${ffmpeg_stderr}"
    ffmpeg_rc=$?
    if [[ -s "${ffmpeg_stderr}" ]]; then
        cat "${ffmpeg_stderr}" >>"${LOG_FILE}"
        if (( ffmpeg_rc != 0 )); then
            log_line "ffmpeg stderr:"
            while IFS= read -r line || [[ -n "${line}" ]]; do
                [[ -z "${line}" ]] && continue
                log_line "  ${line}"
            done <"${ffmpeg_stderr}"
        fi
    fi
    rm -f "${ffmpeg_stderr}"
    return "${ffmpeg_rc}"
}

print_summary() {
    local script_end_time=""

    script_end_time="$(date '+%Y-%m-%d %H:%M:%S')"
    log_line ""
    log_line "========= SUMMARY ========="
    log_line "Script start time:     ${SCRIPT_START_TIME}"
    log_line "Script finish time:    ${script_end_time}"
    log_line "Stream primary:        ${STREAM_URL}"
    log_line "Stream fallback:       ${STREAM_URL_FALLBACK:-<none>}"
    log_line "Stream used last:      ${ACTIVE_STREAM_URL:-<none>}"
    log_line "Output prefix:         ${OUTPUT_PREFIX}"
    log_line "Output directory:      ${OUTPUT_DIR}"
    log_line "Segments saved:        ${segments_ok}"
    log_line "Segments failed:       ${segments_failed}"
    log_line "Bytes recorded:        ${bytes_recorded_total}"
    log_line "Consecutive failures:  ${consecutive_failures}"
    log_line "Exit code:             ${exit_code}"
    log_line "Log file:              ${LOG_FILE}"
    log_line "Day boundary note:     loop stops when day-of-month changes; last segment may run ${EXTRA_SECONDS_AFTER_MIDNIGHT}s past midnight"
    log_line "==========================="
}

maybe_ping_healthcheck() {
    local hc_url="" hc_message=""

    [[ -f "${HEALTHCHECKS_FILE:-}" ]] || return 0
    hc_url="$(grep -m1 "^$(basename "$0")" "${HEALTHCHECKS_FILE}" | awk '{print $2}')"
    [[ -n "${hc_url}" ]] || return 0

    hc_message=$(
        echo "script name: $0"
        echo "current date: $(date '+%Y.%m.%d %H:%M')"
        grep -E -m1 '^# *[0-9]{4}\.[0-9]{2}\.[0-9]{2}' "$0" | awk '{print "script version: " $5 " (dated "$2")"}'
        echo "segments saved: ${segments_ok}"
        echo "segments failed: ${segments_failed}"
        echo "bytes recorded: ${bytes_recorded_total}"
        echo "exit code: ${exit_code}"
    )
    echo "${hc_message}" | /usr/bin/curl -fsS -m 100 --retry 3 --retry-delay 5 \
        --data-binary @- -o /dev/null "${hc_url}/${exit_code}" 2>/dev/null || true
}

prune_old_logs
acquire_lock

mkdir -p "${OUTPUT_DIR}" || {
    echo "ERROR: cannot create output directory" | tee -a "${LOG_FILE}" >&2
    exit 1
}

# Do not pipe this function: a pipeline runs in a subshell, so FFMPEG_BIN would not
# reach the main script (_script_header.sh enables nounset).
print_ffmpeg_in_use

invocation_day=$(date '+%d')
current_day=${invocation_day}

log_line "0. $(date '+%Y.%m.%d__%H:%M:%S') invocation_day = ${invocation_day} , current_day = ${current_day}"

secs_to_midnight=$(( $(date -d "tomorrow 00:00" +%s) - $(date +%s) ))
log_line "1. $(date '+%Y.%m.%d__%H:%M:%S') secs_to_midnight = ${secs_to_midnight}"

while (( secs_to_midnight > SECONDS_BEFORE_MIDNIGHT_STOP )) && (( 10#${invocation_day} == 10#${current_day} )); do
    # 10# forces day-of-month as decimal (08 would otherwise be invalid octal in arithmetic)
    log_line "2. $(date '+%Y.%m.%d__%H:%M:%S') (loop start) secs_to_midnight = ${secs_to_midnight}"
    log_line "2. $(date '+%Y.%m.%d__%H:%M:%S') invocation_day = ${invocation_day} , current_day = ${current_day}"

    if ! check_disk_space "${OUTPUT_DIR}"; then
        exit_code=1
        ((++segments_failed))
        ((++consecutive_failures))
        if (( consecutive_failures >= MAX_CONSECUTIVE_FAILURES )); then
            log_line "ERROR: reached ${MAX_CONSECUTIVE_FAILURES} consecutive failures, stopping"
            break
        fi
        sleep "${RETRY_DELAY}"
        current_day=$(date '+%d')
        continue
    fi

    ACTIVE_STREAM_URL="$(resolve_stream_url)" || {
        log_line "$(date '+%Y.%m.%d__%H:%M:%S') ERROR: no stream URL reachable (primary and fallback failed)"
        exit_code=1
        ((++segments_failed))
        ((++consecutive_failures))
        if (( consecutive_failures >= MAX_CONSECUTIVE_FAILURES )); then
            log_line "ERROR: reached ${MAX_CONSECUTIVE_FAILURES} consecutive failures, stopping"
            break
        fi
        sleep "${RETRY_DELAY}"
        current_day=$(date '+%d')
        continue
    }
    log_line "$(date '+%Y.%m.%d__%H:%M:%S') using stream ${ACTIVE_STREAM_URL}"

    record_duration_sec=$(( secs_to_midnight + EXTRA_SECONDS_AFTER_MIDNIGHT ))
    output_path="${OUTPUT_PREFIX}-$(date '+%Y.%m.%d__%H%M%S').mp3"
    CURRENT_PART="$(partial_output_path "${output_path}")"
    rm -f "${CURRENT_PART}"

    if run_ffmpeg_recording "${ACTIVE_STREAM_URL}" "${record_duration_sec}" "${CURRENT_PART}"; then
        if finalize_recording "${CURRENT_PART}" "${output_path}"; then
            ((++segments_ok))
            consecutive_failures=0
        else
            exit_code=1
            ((++segments_failed))
            ((++consecutive_failures))
        fi
    else
        exit_code=1
        cleanup_partial_recording
        log_line "$(date '+%Y.%m.%d__%H:%M:%S') WARNING: ffmpeg exited non-zero; retrying after ${RETRY_DELAY}"
        ((++segments_failed))
        ((++consecutive_failures))
    fi
    CURRENT_PART=""

    if (( consecutive_failures >= MAX_CONSECUTIVE_FAILURES )); then
        log_line "ERROR: reached ${MAX_CONSECUTIVE_FAILURES} consecutive failures, stopping"
        break
    fi

    secs_to_midnight=$(( $(date -d "tomorrow 00:00" +%s) - $(date +%s) ))
    log_line "3. $(date '+%Y.%m.%d__%H:%M:%S') (loop end) secs_to_midnight = ${secs_to_midnight}"
    sleep "${RETRY_DELAY}"
    current_day=$(date '+%d')
    log_line "4. $(date '+%Y.%m.%d__%H:%M:%S') invocation_day = ${invocation_day} , current_day = ${current_day}"
done

if (( segments_ok > 0 )); then
    exit_code=0
elif (( segments_failed > 0 )); then
    exit_code=1
fi

log_line "$(date '+%Y.%m.%d__%H:%M:%S') finished running $0"
print_summary
maybe_ping_healthcheck
. /root/bin/_script_footer.sh
exit "${exit_code}"
