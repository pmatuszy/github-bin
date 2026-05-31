#!/usr/bin/env bash
# 2026.05.31 - v. 3.46 - server down: prompt [W]ait / [C]ontinue without transcription / [Q]uit
# 2026.05.30 - v. 3.45 - Saved: print final variant transcript path (not intermediate *_ORG.txt)
# 2026.05.30 - v. 3.44 - terminal title: [cwd] full script path; restore on exit
# 2026.05.30 - v. 3.43 - selected existing pair Yes: redo all four transcripts (not skip present variants)
# 2026.05.30 - v. 3.42 - drop redundant TRANSCRIBE URL line (endpoint OK + host:port already shown)
# 2026.05.30 - v. 3.41 - Ctrl-C: remove in-flight transcript (server .txt path); quiet python on interrupt
# 2026.05.30 - v. 3.40 - print Whisper endpoint OK (ping + TCP) before each transcribe when already up
# 2026.05.30 - v. 3.39 - compact one-line OK for complete existing pairs (no huge pair block / double boxes)
# 2026.05.30 - v. 3.38 - drop redundant "not auto-skipped" line; short hint when legacy .txt will be removed
# 2026.05.30 - v. 3.37 - process selected existing pairs after each prompt batch (not only at the end)
# 2026.05.30 - v. 3.36 - defer existing-pair work until after prompts; legacy .txt does not block transcription
# 2026.05.28 - v. 3.35 - do not exit on sha512 repair fail; run transcription after existing-pair Yes
# 2026.05.28 - v. 3.34 - inline whisper HTTP transcription; VAD/noVAD host:port (no hardcoded transcribe-server.sh curl)
# 2026.05.28 - v. 3.33 - pair block: ***MISSING*** on absent paths; list legacy *_ORG.txt / *_OUTPUT.txt as no longer needed
# 2026.05.28 - v. 3.32 - pair block shows (missing); skip existing batch if transcription off; show why not skipped
# 2026.05.28 - v. 3.31 - auto-skip existing pairs when ORG/OUTPUT/transcripts on disk (ignore stale .sha512 lines)
# 2026.05.28 - v. 3.30 - no sha/transcript checks at startup; prepare existing pairs only when selected in batch
# 2026.05.28 - v. 3.29 - skip startup backfill for complete existing pairs; media hash not on redo-offer alone
# 2026.05.28 - v. 3.28 - sha512sum -c only when hash file lists missing paths; media hash check only without/redo transcripts
# 2026.05.28 - v. 3.27 - prune missing paths from sha512 (legacy .txt); repair instead of hang/exit; backfill progress
# 2026.05.28 - v. 3.26 - skip existing-pair prompt when transcripts and sha512 are already complete
# 2026.05.28 - v. 3.25 - source _script_header.sh / _script_footer.sh; add -v/--version
# 2026.05.28 - v. 3.24 - align filenames in transcription pair block (ORG/OUTPUT/transcripts/sha512)
# 2026.05.28 - v. 3.23 - print run summary when user quits with [Q] (EXIT trap)
# 2026.05.28 - v. 3.22 - fix literal ANSI escapes in choice prompts (printf %b, not echo -n)
# 2026.05.28 - v. 3.21 - show (OK / NOT OK) next to Whisper VAD and noVAD endpoints at startup
# 2026.05.28 - v. 3.20 - log when a transcript variant is skipped (already on disk); echo env for transcribe call
# 2026.05.28 - v. 3.19 - always prompt per pair before transcription (include/re-do only marks active scope)
# 2026.05.28 - v. 3.18 - timestamp (YYYY.MM.DD HH:MM:SS) before each interactive question
# 2026.05.28 - v. 3.17 - existing-pair Yes runs transcription/re-do without a second prompt batch
# 2026.05.28 - v. 3.16 - batch prompts for existing ORG/OUTPUT pairs when nothing left to convert
# 2026.05.27 - v. 3.15 - transcription/re-do prompts only for pairs selected in this run (not whole directory)
# 2026.05.27 - v. 3.14 - [F] finish-batch skips unasked slots; re-do [F] then transcription prompts; re-do/transcribe after file loop
# 2026.05.27 - v. 3.13 - end-of-run timing and statistics summary (like video-pgm-merge.sh)
# 2026.05.27 - v. 3.12.3 - green suggestions/questions, red deletion prompts in ffmpeg-voice
# 2026.05.27 - v. 3.12.2 - fix transcript re-do filename column when label fills width (no extra space)
# 2026.05.27 - v. 3.12.1 - align transcript re-do detail lines (ORG/OUTPUT/SHA512 + legacy/loop)
# 2026.05.27 - v. 3.12 - batch transcript re-do prompts with F/G (not one Y/N/Q per pair inline)
# 2026.05.27 - v. 3.11 - batch prompts: finish batch now [F] or skip all further prompts [G]
# 2026.05.27 - v. 3.10 - before each transcription: recheck whisper server; wait or quit if down
# 2026.05.27 - v. 3.9.1 - fix loop-detection awk for mawk/busybox (no ternary in exit)
# 2026.05.27 - v. 3.9 - prompt redo when legacy/unflagged-loop transcripts; keep valid ORG/OUTPUT sha hashes
# 2026.05.27 - v. 3.8 - four transcripts per pair (ORG/OUTPUT x VAD/noVAD); dual whisper host/port config
# 2026.05.27 - v. 3.7 - detect repeated transcript lines; rename to *_ORG/_OUTPUT_POSSIBLE_LOOP.txt
# 2026.05.27 - v. 3.6 - complete missing transcript when only _ORG or _OUTPUT .txt exists; sync sha512
# 2026.05.27 - v. 3.5 - optional command-line file: process only that file, not whole directory
# 2026.05.27 - v. 3.4 - transcribe _ORG then _OUTPUT audio; transcripts as *_ORG.txt and *_OUTPUT.txt
# 2026.05.27 - v. 3.3 - transcription host check: ping and TCP port (default 8080) open
# 2026.05.27 - v. 3.2 - transcribe-server.sh path from cwd filesystem mount (not hardcoded /mnt/temp)
# 2026.03.30 - v. 3.1 - default batch size changed to 50
# 2026.03.30 - v. 3.0 - add [a] accept-all-remaining-in-batch to main file-processing prompts too
# 2026.03.30 - v. 2.9 - add [a] answer for transcription batch prompts to accept all remaining in current batch
# 2026.03.30 - v. 2.8 - remove extra blank line before missing transcript messages
# 2026.03.30 - v. 2.7 - check transcription host reachability before running transcription
# 2026.03.30 - v. 2.6 - batch prompting for missing transcriptions in real mode; change history kept only in script comments
# 2026.03.30 - v. 2.5 - Ctrl-C cleanup removes empty or tiny partial transcript files
# 2026.03.30 - v. 2.4 - per-missing-transcript prompt in real mode, cleanup empty transcript on Ctrl-C
# 2026.03.30 - v. 2.3 - transcript file mapped to *_OUTPUT.txt, transcription prompt default yes, append transcript sha512
# 2026.03.27 - v. 2.1 - backfill sha512 for existing _ORG/_OUTPUT pairs and *_EXCLUDE.* files

set -euo pipefail
shopt -s nullglob nocaseglob

TARGET_FILE=""

show_help() {
    cat <<EOF
Usage: $(basename "$0") [-h|--help] [FILE]

Process voice/audio files in the current directory: rename to *_ORG.*,
create *_OUTPUT.flac, sha512 sidecars, and optional transcription.

With FILE, only that file is processed (no directory scan). FILE must exist
and be a supported audio type (.wav .mp3 .m4a .flac .ogg .opus .aac .mp4).

Without FILE, all matching audio files in the current directory are candidates
(excluding existing *_ORG.*, *_OUTPUT.flac, and *_EXCLUDE.* handling as usual).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  NO_STARTUP_DELAY     Skip _script_header.sh random startup delay (non-tty runs).
  -- FILE              Explicit file operand (use when the name starts with -).

Interactive batch prompts (real mode; file processing, transcript re-do, transcription):
  [F] Finish batch now — process only items you already answered in this batch.
  [G] Process selected; skip all further prompts of that kind (files / re-do / transcription).

Transcription (when enabled):
  Each *_ORG.* and *_OUTPUT.flac gets two transcripts: *_VAD.txt (whisper with VAD)
  and *_noVAD.txt (whisper without VAD), e.g. stem_ORG_VAD.txt and stem_OUTPUT_noVAD.txt.
  Loop detection may rename to *_POSSIBLE_LOOP.txt.

  If old transcripts (no _VAD/_noVAD) or an unflagged loop are found, the script asks
  whether to redo all four transcripts. When the sha512 file already matches ORG and
  OUTPUT media, only transcript lines are replaced; otherwise the hash file is rebuilt.

Whisper servers (defaults below; override with environment variables):
  WHISPER_VAD_HOST / WHISPER_VAD_PORT       Server with VAD (default port 8080).
  WHISPER_NOVAD_HOST / WHISPER_NOVAD_PORT   Server without VAD (default port 8081).
  WHISPER_WAIT_POLL_SEC                     Seconds between retries when waiting for a down server (default: 10).

Transcription HTTP (built into this script; requires curl and python3):
  TRANSCRIBE_MAX_CHARS                      Max characters per transcript line (default: 100).
  TRANSCRIBE_LANGUAGE                       Whisper language (default: pl).
  TRANSCRIBE_TRANSLATE                      Whisper translate flag (default: false).

  Legacy: TRANSCRIBE_HOST and TRANSCRIBE_PORT apply to the VAD server only if
          WHISPER_VAD_HOST / WHISPER_VAD_PORT are unset.
EOF
}

script_version() {
    local ver=unknown date=

    while IFS= read -r line; do
        if [[ "$line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*) ]]; then
            date="${BASH_REMATCH[1]}"
            ver="${BASH_REMATCH[2]}"
            break
        fi
    done < "$0"
    if [[ -n "$date" ]]; then
        printf '%s version %s (%s)\n' "$(basename "$0")" "$ver" "$date"
    else
        printf '%s version %s\n' "$(basename "$0")" "$ver"
    fi
}

is_supported_audio() {
    local path="$1"
    local ext="${path##*.}"
    ext="${ext,,}"
    case "$ext" in
        wav|mp3|m4a|flac|ogg|opus|aac|mp4) return 0 ;;
        *) return 1 ;;
    esac
}

parse_cli_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                script_version
                exit 0
                ;;
            NO_STARTUP_DELAY)
                HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY)
                shift
                ;;
            --)
                shift
                if [[ $# -ne 1 ]]; then
                    echo "Expected exactly one file after --." >&2
                    exit 1
                fi
                TARGET_FILE=$1
                return 0
                ;;
            -*)
                echo "Unknown option: $1 (try --help)" >&2
                exit 1
                ;;
            *)
                if [[ -n "$TARGET_FILE" ]]; then
                    echo "Only one file may be specified (try --help)." >&2
                    exit 1
                fi
                TARGET_FILE=$1
                shift
                ;;
        esac
    done
}

HEADER_EXTRA_ARGS=()
parse_cli_args "$@"

# shellcheck disable=SC1091
. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

VOICE_WINDOW_TITLE_PUSHED=0

# xterm-style title: [cwd] /full/path/to/script.sh (see rename.sh); no-op without a tty.
voice_window_title_restore() {
    (( VOICE_WINDOW_TITLE_PUSHED == 1 )) || return 0
    if [[ -w /dev/tty ]] 2>/dev/null; then
        printf '\033[23t' >/dev/tty 2>/dev/null || true
    fi
    VOICE_WINDOW_TITLE_PUSHED=0
}

voice_window_title_apply() {
    local title="" script_path="$0" cwd max_len=400

    cwd="$(pwd -P 2>/dev/null || pwd)"
    if [[ -e "$script_path" ]]; then
        if command -v realpath >/dev/null 2>&1; then
            script_path="$(realpath "$script_path" 2>/dev/null)" || script_path="$0"
        else
            script_path="$(cd "$(dirname -- "$script_path")" 2>/dev/null && pwd -P)/$(basename -- "$script_path")" \
                2>/dev/null || script_path="$0"
        fi
    fi
    title="[${cwd}] ${script_path}"
    if (( ${#title} > max_len )); then
        title="${title:0:$(( max_len - 3 ))}..."
    fi

    if [[ -n "${STY:-}" ]]; then
        echo -ne "${tcScrTitleStart}${title}${tcScrTitleEnd}"
    fi

    [[ -w /dev/tty ]] 2>/dev/null || return 0
    printf '\033[22t' >/dev/tty 2>/dev/null || true
    printf '\033]0;%s\033\\' "$title" >/dev/tty 2>/dev/null \
        || printf '\033]0;%s\a' "$title" >/dev/tty 2>/dev/null || true
    printf '\033]2;%s\033\\' "$title" >/dev/tty 2>/dev/null \
        || printf '\033]2;%s\a' "$title" >/dev/tty 2>/dev/null || true
    VOICE_WINDOW_TITLE_PUSHED=1
}

voice_window_title_apply

# ============================================================
# DEFAULT SETTINGS
# ============================================================
BATCH_SIZE=50
MIN_FREE_KB=1048576   # 1 GiB
DO_TRANSCRIPTION=yes
# Whisper servers — edit here or set WHISPER_VAD_* / WHISPER_NOVAD_* in the environment.
WHISPER_VAD_HOST="${WHISPER_VAD_HOST:-${TRANSCRIBE_HOST:-192.168.200.134}}"
WHISPER_VAD_PORT="${WHISPER_VAD_PORT:-${TRANSCRIBE_PORT:-8080}}"
WHISPER_NOVAD_HOST="${WHISPER_NOVAD_HOST:-192.168.200.134}"
WHISPER_NOVAD_PORT="${WHISPER_NOVAD_PORT:-8081}"
WHISPER_WAIT_POLL_SEC="${WHISPER_WAIT_POLL_SEC:-10}"
TRANSCRIBE_MAX_CHARS="${TRANSCRIBE_MAX_CHARS:-100}"
TRANSCRIBE_LANGUAGE="${TRANSCRIBE_LANGUAGE:-pl}"
TRANSCRIBE_TRANSLATE="${TRANSCRIBE_TRANSLATE:-false}"
TRANSCRIPT_VAD_SUFFIX="VAD"
TRANSCRIPT_NOVAD_SUFFIX="noVAD"
declare -a TRANSCRIPT_VARIANT_SUFFIXES=("$TRANSCRIPT_VAD_SUFFIX" "$TRANSCRIPT_NOVAD_SUFFIX")
PARTIAL_TXT_DELETE_MAX_BYTES=127
TRANSCRIPT_LOOP_MARKER="_POSSIBLE_LOOP"

voice_ts() {
    date '+%Y.%m.%d %H:%M:%S'
}

ARROW="→"

print_suggestion() {
    printf '%b%s%b\n' "$GREEN" "$*" "$RESET"
}

print_question() {
    print_suggestion "$(voice_ts) $*"
}

print_choice_prompt() {
    printf '%b%s Choice %s%b' "$GREEN" "$(voice_ts)" "$1" "$RESET"
}

print_input_prompt() {
    printf '%b%s%s%b' "$GREEN" "$(voice_ts)" "$1" "$RESET"
}

print_deletion() {
    printf '%b%s%b\n' "$RED" "$*" "$RESET"
}

# After [F] finish-batch: skip unasked slots in the current prompt window.
batch_prompt_finish_skip_idx() {
    local idx="$1" batch_size_now="$2" batch_count="$3"
    echo $(( idx + batch_size_now - batch_count ))
}

VOICE_SCRIPT_START_NS=""
VOICE_PROCESSING_SEC=0
VOICE_PROCESSING_SLICE_START=""

voice_log_kv() {
    local label="$1"
    shift
    printf '%s %-*s  %s\n' "$(voice_ts)" 26 "${label}:" "$*"
}

voice_time_now_ns() {
    date +%s.%N 2>/dev/null || date +%s
}

voice_record_script_start() {
    VOICE_SCRIPT_START_NS=$(voice_time_now_ns)
    VOICE_PROCESSING_SEC=0
}

voice_processing_begin() {
    VOICE_PROCESSING_SLICE_START=$(voice_time_now_ns)
}

voice_processing_end() {
    local t_end
    t_end=$(voice_time_now_ns)
    VOICE_PROCESSING_SEC=$(awk -v acc="${VOICE_PROCESSING_SEC:-0}" -v t0="${VOICE_PROCESSING_SLICE_START}" -v t1="${t_end}" \
        'BEGIN { printf "%.6f", acc + (t1 - t0) }')
}

voice_format_wall_clock() {
    local ns="$1"
    date -d "@${ns%.*}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
        || date -r "${ns%.*}" '+%Y.%m.%d %H:%M:%S' 2>/dev/null \
        || printf '%s\n' "${ns%.*}"
}

format_duration_sec() {
    local sec="$1"
    awk -v s="${sec}" 'BEGIN {
        if (s < 0) s = 0
        h = int(s / 3600)
        m = int((s - h * 3600) / 60)
        x = s - h * 3600 - m * 60
        if (h > 0) printf "%dh %02dm %05.2fs", h, m, x
        else if (m > 0) printf "%dm %05.2fs", m, x
        else printf "%.2f s", s
    }'
}

file_size_bytes() {
    local f="$1"
    if [[ ! -f "$f" ]]; then
        printf '0\n'
        return 0
    fi
    stat -c %s -- "$f" 2>/dev/null || stat -f %z -- "$f" 2>/dev/null || printf '0\n'
}

format_bytes_human() {
    local bytes="$1"
    awk -v b="$bytes" 'BEGIN {
        printf "%d bytes | %.2f kB | %.2f MB", b, b/1024.0, b/1048576.0
    }'
}

format_voice_size_comparison_line() {
    local input_total="$1" output_bytes="$2"
    local diff note
    if (( input_total > output_bytes )); then
        diff=$(( input_total - output_bytes ))
        note="OUTPUT is smaller than ORG total"
    elif (( output_bytes > input_total )); then
        diff=$(( output_bytes - input_total ))
        note="OUTPUT is larger than ORG total"
    else
        printf '  Difference: 0 bytes | 0.00 kB | 0.00 MB — ORG total and OUTPUT are the same size\n'
        return 0
    fi
    printf '  Difference: %s (%s)\n' "$(format_bytes_human "$diff")" "$note"
}

transcribe_host_port_open() {
    local host="$1" port="$2"

    if command -v nc >/dev/null 2>&1; then
        nc -z -w 2 "$host" "$port" >/dev/null 2>&1
        return $?
    fi
    if command -v timeout >/dev/null 2>&1; then
        timeout 2 bash -c "exec 3<>/dev/tcp/${host}/${port}" >/dev/null 2>&1
        return $?
    fi
    bash -c "exec 3<>/dev/tcp/${host}/${port}" >/dev/null 2>&1
}

transcribe_endpoint_is_up() {
    local host="$1"
    local port="$2"

    ping -c 1 -W 1 "$host" >/dev/null 2>&1 && transcribe_host_port_open "$host" "$port"
}

whisper_endpoint_status_label() {
    local host="$1"
    local port="$2"

    if transcribe_endpoint_is_up "$host" "$port"; then
        printf '%bOK%b' "$GREEN" "$RESET"
    else
        printf '%bNOT OK%b' "$RED" "$RESET"
    fi
}

print_whisper_endpoint_ok() {
    local host="$1"
    local port="$2"

    echo -e "Whisper endpoint: ${CYAN}${host}:${port}${RESET} — ${GREEN}OK${RESET} (ping + TCP)"
}

transcription_dependencies_ok() {
    command -v curl >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1
}

whisper_inference_url() {
    local host="$1"
    local port="$2"
    printf 'http://%s:%s/inference' "$host" "$port"
}

# Python segment merge (same logic as whisper.cpp/transcribe-server.sh).
run_whisper_transcription_to_file() {
    local host="$1"
    local port="$2"
    local input_audio="$3"
    local output_txt="$4"
    local max_chars="${5:-$TRANSCRIBE_MAX_CHARS}"
    local url

    if [[ ! -f "$input_audio" ]]; then
        echo -e "${YELLOW}TRANSCRIPTION FAILED:${RESET} file not found: $input_audio" >&2
        return 1
    fi

    url="$(whisper_inference_url "$host" "$port")"

    curl -s "$url" \
        -F "file=@${input_audio}" \
        -F "language=${TRANSCRIBE_LANGUAGE}" \
        -F "translate=${TRANSCRIBE_TRANSLATE}" \
        -F "response_format=verbose_json" \
        | python3 -c '
import sys, json

def fmt(x):
    h = int(x // 3600)
    m = int((x % 3600) // 60)
    sec = int(x % 60)
    ms = int(round((x - int(x)) * 1000))
    return f"{h:02d}:{m:02d}:{sec:02d}.{ms:03d}"

try:
    MAX_CHARS = int(sys.argv[1])
    d = json.load(sys.stdin)
    segments = d["segments"]
    merged = []

    cur_start = None
    cur_end = None
    cur_text = ""

    for s in segments:
        text = " ".join(s["text"].split()).strip()
        if not text:
            continue

        if cur_text == "":
            cur_start = s["start"]
            cur_end = s["end"]
            cur_text = text
        elif len(cur_text) + 1 + len(text) <= MAX_CHARS:
            cur_text += " " + text
            cur_end = s["end"]
        else:
            merged.append((cur_start, cur_end, cur_text))
            cur_start = s["start"]
            cur_end = s["end"]
            cur_text = text

    if cur_text:
        merged.append((cur_start, cur_end, cur_text))

    for start, end, text in merged:
        print(f"[{fmt(start)} --> {fmt(end)}]   {text}")
except KeyboardInterrupt:
    sys.exit(130)
' "$max_chars" >"$output_txt"

    if [[ ! -s "$output_txt" ]]; then
        echo -e "${YELLOW}TRANSCRIPTION FAILED:${RESET} empty transcript from ${host}:${port}" >&2
        rm -f -- "$output_txt"
        return 1
    fi

    return 0
}

# ============================================================
# STATE (early — summary on [Q] quit must see these)
# ============================================================
files_examined=0
files_affected=0
files_skipped=0
stats_new_files_processed=0
stats_sha_backfilled=0
stats_pairs_transcribed=0
stats_transcript_redos=0
stopped_by_user=no
skip_remaining_file_prompts=no
skip_remaining_transcription_prompts=no
skip_remaining_redo_prompts=no
skip_remaining_existing_pair_prompts=no
VOICE_SUMMARY_DONE=no
whisper_endpoint_announced_key=""

declare -a affected_list=()
declare -a all_files=()
declare -a exclude_files=()
declare -a existing_pair_orgs=()
declare -a existing_pair_outs=()
declare -a existing_pair_shas=()
declare -a transcribe_queue_orgs=()
declare -a transcribe_queue_outs=()
declare -a transcribe_queue_shas=()
declare -a transcript_redo_orgs=()
declare -a transcript_redo_outs=()
declare -a transcript_redo_shas=()
declare -a voice_active_orgs=()
declare -a voice_active_outs=()
declare -a voice_active_shas=()
declare -A voice_active_stem_seen=()

current_original_in=""
current_new_in=""
current_out=""
current_renamed=no
current_txt_file=""
transcription_in_flight=no
current_transcription_write_path=""
current_transcription_target_path=""
transcription_force_redo=no

print_voice_size_summary() {
    local r old rest mid new org_total=0 out_total=0 sz

    for r in "${affected_list[@]}"; do
        old=${r%%|*}
        rest=${r#*|}
        mid=${rest%%|*}
        new=${rest#*|}
        if [[ -f "$mid" ]]; then
            sz=$(file_size_bytes "$mid")
            (( org_total += sz ))
        fi
        if [[ -f "$new" ]]; then
            sz=$(file_size_bytes "$new")
            (( out_total += sz ))
        fi
    done

    (( org_total == 0 && out_total == 0 )) && return 0

    echo "=== Size summary (new conversions) ==="
    voice_log_kv "ORG audio total" "$(format_bytes_human "$org_total")"
    voice_log_kv "OUTPUT FLAC total" "$(format_bytes_human "$out_total")"
    format_voice_size_comparison_line "$org_total" "$out_total"
    echo
}

print_voice_timing_summary() {
    local end_ns total_sec wait_sec

    [[ -n "${VOICE_SCRIPT_START_NS}" ]] || return 0
    end_ns=$(voice_time_now_ns)
    total_sec=$(awk -v s0="${VOICE_SCRIPT_START_NS}" -v s1="${end_ns}" 'BEGIN { printf "%.6f", s1 - s0 }')
    wait_sec=$(awk -v t="${total_sec}" -v p="${VOICE_PROCESSING_SEC:-0}" \
        'BEGIN { w = t - p; if (w < 0) w = 0; printf "%.6f", w }')

    echo
    echo "$(voice_ts) --- Timing ---"
    voice_log_kv "Started" "$(voice_format_wall_clock "${VOICE_SCRIPT_START_NS}")"
    voice_log_kv "Finished" "$(date '+%Y.%m.%d %H:%M:%S')"
    voice_log_kv "Total wall time" "$(format_duration_sec "${total_sec}")"
    voice_log_kv "Processing time" "$(format_duration_sec "${VOICE_PROCESSING_SEC:-0}")  (ffmpeg, sha512, transcription, re-do)"
    voice_log_kv "Other/wait time" "$(format_duration_sec "${wait_sec}")  (prompts, startup delay, overhead)"
    echo
}

print_voice_statistics_summary() {
    local scope_line summary_line
    local existing_pairs=${#existing_pair_orgs[@]}
    local exclude_count=${#exclude_files[@]}
    local candidates=${#all_files[@]}

    echo
    if (( files_examined == 0 )); then
        echo "$(voice_ts) No matching input files found."
        echo
    fi

    if [[ -n "$TARGET_FILE" ]]; then
        scope_line="single file ($TARGET_FILE)"
    else
        scope_line="current directory"
    fi

    echo "$(voice_ts) --- Run summary ---"
    voice_log_kv "Mode" "${mode:-not selected}"
    voice_log_kv "Scope" "$scope_line"
    if [[ "${mode:-}" == "real" ]]; then
        voice_log_kv "Batch size" "${BATCH_SIZE:-}"
    fi
    voice_log_kv "Boxes available" "${have_boxes:-no}"
    voice_log_kv "Colors enabled" "${use_colors:-yes}"
    voice_log_kv "Transcription enabled" "${DO_TRANSCRIPTION:-}"
    if [[ "${DO_TRANSCRIPTION:-}" == "yes" ]]; then
        voice_log_kv "Transcription" "HTTP inference (curl + python3)"
        voice_log_kv "Transcribe max chars" "$TRANSCRIBE_MAX_CHARS"
    fi
    if [[ "${DO_TRANSCRIPTION:-}" == "yes" ]]; then
        if transcribe_endpoint_is_up "$WHISPER_VAD_HOST" "$WHISPER_VAD_PORT"; then
            voice_log_kv "Whisper VAD" "${WHISPER_VAD_HOST}:${WHISPER_VAD_PORT} (OK)"
        else
            voice_log_kv "Whisper VAD" "${WHISPER_VAD_HOST}:${WHISPER_VAD_PORT} (NOT OK)"
        fi
        if transcribe_endpoint_is_up "$WHISPER_NOVAD_HOST" "$WHISPER_NOVAD_PORT"; then
            voice_log_kv "Whisper noVAD" "${WHISPER_NOVAD_HOST}:${WHISPER_NOVAD_PORT} (OK)"
        else
            voice_log_kv "Whisper noVAD" "${WHISPER_NOVAD_HOST}:${WHISPER_NOVAD_PORT} (NOT OK)"
        fi
    fi
    voice_log_kv "Files examined" "$files_examined"
    voice_log_kv "Active pairs (this run)" "${#voice_active_orgs[@]}"
    voice_log_kv "Candidates to convert" "$candidates"
    voice_log_kv "Existing ORG/OUTPUT pairs" "$existing_pairs"
    voice_log_kv "EXCLUDE files" "$exclude_count"
    voice_log_kv "Files affected" "$files_affected"
    voice_log_kv "New conversions" "$stats_new_files_processed"
    voice_log_kv "SHA512 backfilled" "$stats_sha_backfilled"
    voice_log_kv "Files skipped" "$files_skipped"
    if [[ "${DO_TRANSCRIPTION:-}" == "yes" ]]; then
        voice_log_kv "Transcription pairs run" "$stats_pairs_transcribed"
        voice_log_kv "Transcript re-dos" "$stats_transcript_redos"
    fi
    voice_log_kv "Stopped by user" "$stopped_by_user"
    if [[ "${mode:-}" == "real" ]]; then
        voice_log_kv "Skipped file prompts" "$skip_remaining_file_prompts"
        voice_log_kv "Skipped transcribe prompts" "$skip_remaining_transcription_prompts"
        voice_log_kv "Skipped re-do prompts" "$skip_remaining_redo_prompts"
        voice_log_kv "Skipped existing-pair prompts" "$skip_remaining_existing_pair_prompts"
    fi

    summary_line="${files_examined} examined"
    summary_line+=", ${stats_new_files_processed} new conversion(s)"
    summary_line+=", ${existing_pairs} existing pair(s)"
    if [[ "${DO_TRANSCRIPTION:-}" == "yes" ]]; then
        summary_line+=", ${stats_pairs_transcribed} transcribed pair(s)"
        summary_line+=", ${stats_transcript_redos} transcript re-do(s)"
    fi
    summary_line+=", ${files_skipped} skipped"
    echo "$(voice_ts) Summary: ${summary_line}."

    if (( ${#affected_list[@]} > 0 )); then
        echo
        echo "Planned/performed changes:"
        for r in "${affected_list[@]}"; do
            old=${r%%|*}
            rest=${r#*|}
            mid=${rest%%|*}
            new=${rest#*|}
            printf "  %s %b%s%b %s %b%s%b %s\n" \
                "$old" \
                "$RED" "$ARROW" "$RESET" \
                "$mid" \
                "$RED" "$ARROW" "$RESET" \
                "$new"
        done
        echo
        print_voice_size_summary
    fi
}

voice_finish_run() {
    [[ "$VOICE_SUMMARY_DONE" == yes ]] && return 0
    VOICE_SUMMARY_DONE=yes
    voice_window_title_restore
    print_voice_statistics_summary
    print_voice_timing_summary
    # shellcheck disable=SC1091
    . /root/bin/_script_footer.sh
}

voice_quit() {
    stopped_by_user=yes
    echo "Quitting."
    exit 0
}

trap voice_finish_run EXIT

# ============================================================
# COLOR SELECTION
# ============================================================
echo
echo "$(voice_ts) Use colors?"
echo "  [Y] Yes (default)"
echo "  [N] No"
echo "  [Q] Quit"
echo -n "$(voice_ts) Choice [Y/n/q]: "

use_colors=yes
input=""

read -r -t 60 -n 1 input || true
printf '\n'

if [[ "$input" =~ [Qq] ]]; then
    voice_quit
elif [[ "$input" =~ [Nn] ]]; then
    use_colors=no
fi

if [[ "$use_colors" == "yes" ]]; then
    RED=$'\033[31m'
    GREEN=$'\033[32m'
    CYAN=$'\033[36m'
    YELLOW=$'\033[33m'
    RESET=$'\033[0m'
else
    RED=''
    GREEN=''
    CYAN=''
    YELLOW=''
    RESET=''
fi

# ============================================================
# MODE SELECTION
# ============================================================
echo
print_question "Select mode:"
print_suggestion "  [D] Dry-run (default)"
print_suggestion "  [R] Real processing (interactive)"
print_suggestion "  [Q] Quit"
print_choice_prompt "[D/r/q]: "

mode="dry-run"
input=""

read -r -t 60 -n 1 input || true
printf '\n'

if [[ "$input" =~ [Qq] ]]; then
    voice_quit
elif [[ "$input" =~ [Rr] ]]; then
    mode="real"
fi

echo -e "Mode selected: ${CYAN}$mode${RESET}"
if [[ -n "$TARGET_FILE" ]]; then
    echo -e "Scope: ${CYAN}single file${RESET} — $TARGET_FILE"
else
    echo -e "Scope: ${CYAN}current directory${RESET}"
fi

# ============================================================
# TRANSCRIPTION SELECTION
# ============================================================
echo
if [[ "$mode" == "real" ]]; then
    print_question "Enable transcription (ORG/OUTPUT x VAD/noVAD whisper servers)?"
    print_suggestion "  [Y] Yes (default)"
    print_suggestion "  [N] No"
    print_suggestion "  [Q] Quit"
    print_choice_prompt "[Y/n/q]: "
else
    print_question "Include transcription step in dry-run (ORG/OUTPUT x VAD/noVAD)?"
    print_suggestion "  [Y] Yes (default)"
    print_suggestion "  [N] No"
    print_suggestion "  [Q] Quit"
    print_choice_prompt "[Y/n/q]: "
fi

input=""
read -r -t 60 -n 1 input || true
printf '\n'

if [[ "$input" =~ [Qq] ]]; then
    voice_quit
elif [[ "$input" =~ [Nn] ]]; then
    DO_TRANSCRIPTION=no
fi

echo -e "Transcription enabled: ${CYAN}$DO_TRANSCRIPTION${RESET}"

# ============================================================
# BATCH SIZE - ONLY FOR REAL MODE
# ============================================================
if [[ "$mode" == "real" ]]; then
    echo
    print_question "Batch size for asking before processing?"
    print_suggestion "  Default: 50"
    print_suggestion "  Enter a positive number, or press Enter for default."
    print_input_prompt "Batch size [50]: "

    input=""
    IFS= read -r -t 60 input || true

    if [[ -z "$input" ]]; then
        BATCH_SIZE=50
    elif [[ "$input" =~ ^[1-9][0-9]*$ ]]; then
        BATCH_SIZE="$input"
    else
        echo "Invalid batch size. Using default: 50"
        BATCH_SIZE=50
    fi

    echo -e "Batch size selected: ${CYAN}$BATCH_SIZE${RESET}"
fi

# ============================================================
# HELPERS
# ============================================================
have_boxes=no
if command -v boxes >/dev/null 2>&1; then
    have_boxes=yes
fi

# Mount point for path (findmnt, else df — same idea as check_free_space_or_exit).
filesystem_mount_for_path() {
    local target_path="$1"
    local mount_point=""

    if command -v findmnt >/dev/null 2>&1; then
        mount_point="$(findmnt -n -o TARGET --target "$target_path" 2>/dev/null)" || mount_point=""
        if [[ -n "$mount_point" ]]; then
            printf '%s' "${mount_point%/}"
            return 0
        fi
    fi

    mount_point="$(
        LC_ALL=C /bin/df -Pk -- "$target_path" 2>/dev/null \
        | awk 'NR==2 {print $6}'
    )"
    if [[ -n "$mount_point" ]]; then
        printf '%s' "${mount_point%/}"
        return 0
    fi
    return 1
}

print_transcribe_whisper_servers_info() {
    local deps_status

    echo
    if transcription_dependencies_ok; then
        deps_status="${GREEN}OK${RESET}"
    else
        deps_status="${RED}NOT OK (need curl and python3)${RESET}"
    fi
    echo -e "Transcription:       ${CYAN}HTTP inference (curl + python3)${RESET} (${deps_status})"
    echo -e "Whisper VAD:         ${CYAN}${WHISPER_VAD_HOST}:${WHISPER_VAD_PORT}${RESET} ($(whisper_endpoint_status_label "$WHISPER_VAD_HOST" "$WHISPER_VAD_PORT"))"
    echo -e "Whisper noVAD:       ${CYAN}${WHISPER_NOVAD_HOST}:${WHISPER_NOVAD_PORT}${RESET} ($(whisper_endpoint_status_label "$WHISPER_NOVAD_HOST" "$WHISPER_NOVAD_PORT"))"
}

if [[ "$DO_TRANSCRIPTION" == "yes" ]]; then
    print_transcribe_whisper_servers_info
fi

voice_record_script_start

print_file_block() {
    local original_in="$1"
    local new_in="$2"
    local out="$3"

    if [[ "$have_boxes" == "yes" ]]; then
        {
            printf "INPUT:   %s\n" "$original_in"
            printf "RENAME:  %s %s %s\n" "$original_in" "$ARROW" "$new_in"
            printf "OUTPUT:  %s\n" "$out"
        } | boxes -d stone
    else
        echo -e "${RED}INPUT:${RESET}   $original_in"
        echo -e "${GREEN}RENAME:${RESET}  $original_in $ARROW $new_in"
        echo -e "${GREEN}OUTPUT:${RESET}  $out"
    fi
}

print_sha_block() {
    local sha_file="$1"
    local entry1="$2"
    local entry2="${3:-}"

    if [[ "$have_boxes" == "yes" ]]; then
        {
            printf "SHA512:  %s\n" "$sha_file"
            printf "ENTRY 1: %s\n" "$entry1"
            [[ -n "$entry2" ]] && printf "ENTRY 2: %s\n" "$entry2"
        } | boxes -d stone
    else
        echo -e "${CYAN}SHA512:${RESET}  $sha_file"
        echo -e "${CYAN}ENTRY 1:${RESET} $entry1"
        [[ -n "$entry2" ]] && echo -e "${CYAN}ENTRY 2:${RESET} $entry2"
    fi
}

print_prompt_progress_box() {
    local batch_pos="$1"
    local batch_size_now="$2"
    local overall_pos="$3"
    local total_files="$4"
    local still_after_this="$5"

    {
        printf "PROMPTING: batch file %s/%s\n" "$batch_pos" "$batch_size_now"
        printf "OVERALL:   file %s/%s\n" "$overall_pos" "$total_files"
        printf "STILL TO BE ASKED AFTER THIS ONE: %s\n" "$still_after_this"
    }
}

print_decision_summary_box() {
    local batch_size_now="$1"
    local yes_count="$2"
    local no_count="$3"

    local undecided
    undecided=$(( batch_size_now - yes_count - no_count ))
    (( undecided < 0 )) && undecided=0

    {
        printf "WILL BE PROCESSED IN THIS BATCH: %s\n" "$yes_count"
        printf "WILL BE SKIPPED IN THIS BATCH:   %s\n" "$no_count"
        printf "ANSWERS STILL MISSING:           %s\n" "$undecided"
    }
}

print_prompt_and_decision_summary() {
    local batch_pos="$1"
    local batch_size_now="$2"
    local overall_pos="$3"
    local total_files="$4"
    local still_after_this="$5"
    local yes_count="$6"
    local no_count="$7"

    if [[ "$have_boxes" == "yes" ]]; then
        local left right
        left="$(mktemp)"
        right="$(mktemp)"

        print_prompt_progress_box \
            "$batch_pos" "$batch_size_now" "$overall_pos" "$total_files" "$still_after_this" \
            | boxes -d stone > "$left"

        print_decision_summary_box \
            "$batch_size_now" "$yes_count" "$no_count" \
            | boxes -d stone > "$right"

        paste -d ' ' "$left" "$right"
        rm -f "$left" "$right"
    else
        local undecided
        undecided=$(( batch_size_now - yes_count - no_count ))
        (( undecided < 0 )) && undecided=0

        echo -e "${CYAN}PROMPTING:${RESET} batch file $batch_pos/$batch_size_now"
        echo -e "${CYAN}OVERALL:${RESET}   file $overall_pos/$total_files"
        echo -e "${CYAN}LEFT TO ASK AFTER THIS:${RESET} $still_after_this"
        echo -e "${GREEN}WILL BE PROCESSED IN THIS BATCH:${RESET} $yes_count"
        echo -e "${YELLOW}WILL BE SKIPPED IN THIS BATCH:${RESET}   $no_count"
        echo -e "${CYAN}ANSWERS STILL MISSING:${RESET}           $undecided"
    fi
}

# Sets BATCH_CHOICE_DECISION (yes|no) and BATCH_CHOICE_ACTION:
#   decided | accept_all | finish_batch | skip_all | quit
read_batch_choice() {
    local prompt_line="$1"
    local input=""

    BATCH_CHOICE_DECISION=""
    BATCH_CHOICE_ACTION=""

    print_question "$prompt_line"
    print_suggestion "  [Y] Yes (default)"
    print_suggestion "  [N] No"
    print_suggestion "  [A] Yes for all remaining in this batch"
    print_suggestion "  [F] Finish batch now (process selected only; stop asking for rest of batch)"
    print_suggestion "  [G] Process selected; skip all further prompts this run"
    print_suggestion "  [Q] Quit"
    print_choice_prompt "[Y/n/a/f/g/q]: "

    read -r -t 300 -n 1 input || true
    printf '\n'

    case "$input" in
        q|Q)
            BATCH_CHOICE_ACTION=quit
            ;;
        n|N)
            BATCH_CHOICE_DECISION=no
            BATCH_CHOICE_ACTION=decided
            ;;
        a|A)
            BATCH_CHOICE_DECISION=yes
            BATCH_CHOICE_ACTION=accept_all
            ;;
        f|F)
            BATCH_CHOICE_ACTION=finish_batch
            ;;
        g|G)
            BATCH_CHOICE_ACTION=skip_all
            ;;
        *)
            BATCH_CHOICE_DECISION=yes
            BATCH_CHOICE_ACTION=decided
            ;;
    esac
}

print_processing_progress() {
    local selected_pos="$1"
    local selected_total="$2"
    local selected_left_after="$3"
    local overall_total="$4"

    if [[ "$have_boxes" == "yes" ]]; then
        {
            printf "PROCESSING: selected file %s/%s in current batch\n" "$selected_pos" "$selected_total"
            printf "REMAINING SELECTED IN THIS BATCH AFTER THIS ONE: %s\n" "$selected_left_after"
            printf "TOTAL ELIGIBLE FILES: %s\n" "$overall_total"
        } | boxes -d stone
    else
        echo -e "${CYAN}PROCESSING:${RESET} selected file $selected_pos/$selected_total in current batch"
        echo -e "${CYAN}REMAINING SELECTED IN THIS BATCH AFTER THIS:${RESET} $selected_left_after"
        echo -e "${CYAN}TOTAL ELIGIBLE FILES:${RESET} $overall_total"
    fi
}

print_restore_block() {
    local removed_msg="$1"
    local restored_msg="$2"
    local txt_removed_msg="$3"

    if [[ "$have_boxes" == "yes" ]]; then
        {
            echo "RESTORING: current file state"
            [[ -n "$removed_msg" ]] && echo "$removed_msg"
            [[ -n "$restored_msg" ]] && echo "$restored_msg"
            [[ -n "$txt_removed_msg" ]] && echo "$txt_removed_msg"
        } | boxes -d stone
    else
        echo -e "${YELLOW}INTERRUPTED:${RESET} restoring current file state..."
        [[ -n "$removed_msg" ]] && print_deletion "$removed_msg"
        [[ -n "$restored_msg" ]] && echo -e "${YELLOW}${restored_msg}${RESET}"
        [[ -n "$txt_removed_msg" ]] && print_deletion "$txt_removed_msg"
    fi
}

print_low_space_block() {
    local avail_kb="$1"
    local path="$2"
    local need_kb="$3"

    if [[ "$have_boxes" == "yes" ]]; then
        {
            echo "LOW DISK SPACE"
            printf "PATH: %s\n" "$path"
            printf "AVAILABLE: %s KB\n" "$avail_kb"
            printf "REQUIRED MINIMUM: %s KB\n" "$need_kb"
            echo "EXITING."
        } | boxes -d stone
    else
        echo -e "${YELLOW}LOW DISK SPACE${RESET}"
        echo "PATH: $path"
        echo "AVAILABLE: $avail_kb KB"
        echo "REQUIRED MINIMUM: $need_kb KB"
        echo "EXITING."
    fi
}

transcription_pair_block_value_col() {
    local label_width=0 tag t

    for t in "ORG AUDIO:" "OUTPUT AUDIO:" "SHA512 FILE:"; do
        (( ${#t} > label_width )) && label_width=${#t}
    done
    for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
        t="ORG TRANSCRIPT (${tag}):"
        (( ${#t} > label_width )) && label_width=${#t}
        t="OUTPUT TRANSCRIPT (${tag}):"
        (( ${#t} > label_width )) && label_width=${#t}
    done
    t="LEGACY (removed if you include pair):"
    (( ${#t} > label_width )) && label_width=${#t}
    echo $(( label_width + 1 ))
}

print_transcription_pair_line() {
    local value_col="$1"
    local label="$2"
    local value="$3"
    local use_color="${4:-no}"
    local spaces=$(( value_col - ${#label} ))

    (( spaces < 0 )) && spaces=0

    if [[ "$use_color" == yes ]]; then
        printf '%b%s%*s%b %s\n' "$CYAN" "$label" "$spaces" "" "$RESET" "$value"
    else
        print_transcript_redo_detail_line "" "$value_col" "$label" "$value"
    fi
}

pair_block_path_status() {
    local path="$1"

    if [[ -e "$path" ]]; then
        printf '%s' "$path"
        return 0
    fi

    printf '%s ***MISSING***' "$path"
}

print_transcription_pair_legacy_lines() {
    local org_file="$1"
    local out_file="$2"
    local value_col="$3"
    local color_mode="$4"
    local -a legacy=()
    local legacy_path label_printed=no

    mapfile -t legacy < <(pair_list_legacy_transcript_files "$org_file" "$out_file")
    (( ${#legacy[@]} == 0 )) && return 0

    for legacy_path in "${legacy[@]}"; do
        if [[ "$label_printed" == no ]]; then
            print_transcription_pair_line "$value_col" "LEGACY (removed if you include pair):" \
                "$legacy_path" "$color_mode"
            label_printed=yes
        else
            print_transcript_redo_detail_line "" "$value_col" "" "$legacy_path"
        fi
    done
}

print_transcription_pair_block() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"
    local tag variant_path value_col color_mode=no

    value_col="$(transcription_pair_block_value_col)"
    [[ "$have_boxes" != "yes" ]] && color_mode=yes

    print_transcription_pair_lines() {
        print_transcription_pair_line "$value_col" "ORG AUDIO:" \
            "$(pair_block_path_status "$org_file")" "$color_mode"
        for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
            variant_path="$(transcript_variant_path_for_audio "$org_file" "$tag")"
            if transcript_variant_exists_for_audio "$org_file" "$tag"; then
                variant_path="$(transcript_variant_resolved_path "$variant_path")"
            fi
            print_transcription_pair_line "$value_col" "ORG TRANSCRIPT (${tag}):" \
                "$(pair_block_path_status "$variant_path")" "$color_mode"
        done
        print_transcription_pair_line "$value_col" "OUTPUT AUDIO:" \
            "$(pair_block_path_status "$out_file")" "$color_mode"
        for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
            variant_path="$(transcript_variant_path_for_audio "$out_file" "$tag")"
            if transcript_variant_exists_for_audio "$out_file" "$tag"; then
                variant_path="$(transcript_variant_resolved_path "$variant_path")"
            fi
            print_transcription_pair_line "$value_col" "OUTPUT TRANSCRIPT (${tag}):" \
                "$(pair_block_path_status "$variant_path")" "$color_mode"
        done
        print_transcription_pair_legacy_lines "$org_file" "$out_file" "$value_col" "$color_mode"
        print_transcription_pair_line "$value_col" "SHA512 FILE:" \
            "$(pair_block_path_status "$sha_file")" "$color_mode"
    }

    if [[ "$have_boxes" == "yes" ]]; then
        print_transcription_pair_lines | boxes -d stone
    else
        print_transcription_pair_lines
    fi
}

check_free_space_or_exit() {
    local target_path="$1"
    local avail_kb

    avail_kb="$(
        LC_ALL=C /bin/df -Pk -- "$target_path" 2>/dev/null \
        | awk 'NR==2 {gsub(/[^0-9]/, "", $4); print $4}'
    )"

    if [[ -z "$avail_kb" || ! "$avail_kb" =~ ^[0-9]+$ ]]; then
        echo
        echo "Could not determine free disk space. Exiting."
        exit 1
    fi

    if (( avail_kb < MIN_FREE_KB )); then
        echo
        print_low_space_block "$avail_kb" "$target_path" "$MIN_FREE_KB"
        exit 1
    fi
}

whisper_host_for_suffix() {
    case "$1" in
        "$TRANSCRIPT_VAD_SUFFIX") printf '%s' "$WHISPER_VAD_HOST" ;;
        "$TRANSCRIPT_NOVAD_SUFFIX") printf '%s' "$WHISPER_NOVAD_HOST" ;;
        *) return 1 ;;
    esac
}

whisper_port_for_suffix() {
    case "$1" in
        "$TRANSCRIPT_VAD_SUFFIX") printf '%s' "$WHISPER_VAD_PORT" ;;
        "$TRANSCRIPT_NOVAD_SUFFIX") printf '%s' "$WHISPER_NOVAD_PORT" ;;
        *) return 1 ;;
    esac
}

print_transcribe_connectivity_checks() {
    local tag host port
    local -A seen_hosts=()

    for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
        host="$(whisper_host_for_suffix "$tag")"
        port="$(whisper_port_for_suffix "$tag")"
        if [[ -z "${seen_hosts[$host]+x}" ]]; then
            echo "ping -c 1 -W 1 \"$host\""
            seen_hosts["$host"]=1
        fi
        if command -v nc >/dev/null 2>&1; then
            echo "nc -z -w 2 \"$host\" \"$port\"  # ${tag}"
        else
            echo "timeout 2 bash -c 'exec 3<>/dev/tcp/${host}/${port}'  # ${tag}"
        fi
    done
}

print_transcribe_endpoint_down_reason() {
    local host="$1"
    local port="$2"

    if ! ping -c 1 -W 1 "$host" >/dev/null 2>&1; then
        echo "  Host not reachable (ping)."
    elif ! transcribe_host_port_open "$host" "$port"; then
        echo "  TCP port ${port} is not open."
    fi
}

# Called before every transcription run (server may stop between runs).
ensure_transcribe_endpoint_ready() {
    local host="$1"
    local port="$2"
    local label="${3:-whisper}"
    local input poll_sec

    poll_sec="${WHISPER_WAIT_POLL_SEC:-10}"

    if transcribe_endpoint_is_up "$host" "$port"; then
        return 0
    fi

    if [[ "$mode" == "dry-run" ]]; then
        echo
        echo -e "${YELLOW}TRANSCRIPTION UNAVAILABLE:${RESET} ${host}:${port} (${label})"
        print_transcribe_endpoint_down_reason "$host" "$port"
        echo "Cannot continue because transcription cannot be done."
        exit 1
    fi

    while true; do
        echo
        echo -e "${YELLOW}TRANSCRIPTION SERVER DOWN:${RESET} ${host}:${port} (${label})"
        print_transcribe_endpoint_down_reason "$host" "$port"
        print_suggestion "  [W] Wait until the server is back (default)"
        print_suggestion "  [C] Continue without transcription (skip)"
        print_suggestion "  [Q] Quit"
        print_choice_prompt "[W/c/q]: "
        read -r -t 300 -n 1 input || true
        printf '\n'

        case "$input" in
            q|Q)
                voice_quit
                ;;
            c|C)
                echo -e "${YELLOW}TRANSCRIPTION SKIPPED:${RESET} ${host}:${port} is down — continuing without transcription."
                return 1
                ;;
        esac

        echo "Waiting for ${host}:${port} (every ${poll_sec}s)..."
        while ! transcribe_endpoint_is_up "$host" "$port"; do
            sleep "$poll_sec"
            echo "  Still waiting for ${host}:${port} (${label})..."
        done
        echo -e "${GREEN}TRANSCRIPTION SERVER UP:${RESET} ${host}:${port} (${label})"
        whisper_endpoint_announced_key="${host}:${port}"
        return 0
    done
}

check_transcribe_endpoint_or_exit() {
    ensure_transcribe_endpoint_ready "$@"
}

check_transcribe_hosts_or_exit() {
    local tag host port
    local -A checked_endpoints=()
    local endpoint_key

    [[ "$DO_TRANSCRIPTION" == "yes" ]] || return 0

    for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
        host="$(whisper_host_for_suffix "$tag")"
        port="$(whisper_port_for_suffix "$tag")"
        endpoint_key="${host}:${port}"
        if [[ -n "${checked_endpoints[$endpoint_key]+x}" ]]; then
            continue
        fi
        checked_endpoints["$endpoint_key"]=1
        if ! check_transcribe_endpoint_or_exit "$host" "$port" "${tag} @ ${endpoint_key}"; then
            return 1
        fi
    done
}

sha_file_from_pair() {
    local new_in="$1"
    local base_no_ext stem
    base_no_ext="${new_in%.*}"
    stem="${base_no_ext%_ORG}"
    printf '%s.sha512' "$stem"
}

sha_file_from_single() {
    local file="$1"
    local stem
    stem="${file%.*}"
    printf '%s.sha512' "$stem"
}

create_sha512_pair_file() {
    local sha_file="$1"
    local org_file="$2"
    local out_file="$3"
    sha512sum -- "$org_file" "$out_file" > "$sha_file"
}

create_sha512_single_file() {
    local sha_file="$1"
    local file="$2"
    sha512sum -- "$file" > "$sha_file"
}

sha512_entry_path() {
    local line="$1"
    printf '%s' "${line#*  }"
}

# Drop sha512 lines whose file no longer exists (e.g. old *_OUTPUT.txt without _VAD/_noVAD).
prune_missing_paths_from_sha512_file() {
    local sha_file="$1"
    local dropped_path line path pruned=0 tmp

    [[ -e "$sha_file" ]] || return 0

    tmp="$(mktemp)"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        path="$(sha512_entry_path "$line")"
        if [[ -e "$path" ]]; then
            printf '%s\n' "$line" >>"$tmp"
        else
            echo -e "${YELLOW}SHA512:${RESET} dropping missing entry: $path"
            ((++pruned))
        fi
    done < "$sha_file"

    if (( pruned > 0 )); then
        if [[ -s "$tmp" ]]; then
            mv -f -- "$tmp" "$sha_file"
        else
            rm -f -- "$tmp" "$sha_file"
        fi
    else
        rm -f -- "$tmp"
    fi

    return 0
}

# Returns 0 when the sha512 file lists at least one path that does not exist on disk.
sha512_file_has_missing_paths() {
    local sha_file="$1"
    local line path

    [[ -e "$sha_file" ]] || return 1

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        path="$(sha512_entry_path "$line")"
        [[ -e "$path" ]] || return 0
    done < "$sha_file"

    return 1
}

verify_sha512_file_existing_only() {
    local sha_file="$1"
    local line path tmp

    [[ -e "$sha_file" ]] || return 1

    tmp="$(mktemp)"
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -z "$line" ]] && continue
        path="$(sha512_entry_path "$line")"
        [[ -e "$path" ]] && printf '%s\n' "$line" >>"$tmp"
    done < "$sha_file"

    if [[ ! -s "$tmp" ]]; then
        rm -f -- "$tmp"
        return 1
    fi

    sha512sum -c --quiet -- "$tmp" 2>/dev/null
    local ok=$?
    rm -f -- "$tmp"
    return "$ok"
}

# Media ORG/OUTPUT hash check (sha512sum -c on media lines only) when sha is missing or transcripts need work.
pair_needs_media_hash_check() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    [[ -e "$org_file" && -e "$out_file" ]] || return 1

    if [[ ! -e "$sha_file" ]]; then
        return 0
    fi

    [[ "$DO_TRANSCRIPTION" != "yes" ]] && return 1

    transcript_all_variants_exist_for_audio "$org_file" || return 0
    transcript_all_variants_exist_for_audio "$out_file" || return 0

    return 1
}

pair_needs_transcript_loop_scan() {
    local org_file="$1"
    local out_file="$2"

    [[ "$DO_TRANSCRIPTION" == "yes" ]] || return 1
    pair_needs_transcript_redo_offer "$org_file" "$out_file" && return 0
    transcript_all_variants_exist_for_audio "$org_file" || return 0
    transcript_all_variants_exist_for_audio "$out_file" || return 0

    return 1
}

ensure_pair_media_sha_file() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    [[ -e "$org_file" && -e "$out_file" ]] || return 1

    if [[ ! -e "$sha_file" ]]; then
        if [[ "$mode" == "dry-run" ]]; then
            return 0
        fi
        create_sha512_pair_file "$sha_file" "$org_file" "$out_file"
        return 0
    fi

    if pair_media_hashes_valid_in_sha "$sha_file" "$org_file" "$out_file"; then
        return 0
    fi

    echo -e "${YELLOW}SHA512:${RESET} ORG/OUTPUT media hashes missing or invalid — rebuilding."
    create_sha512_pair_file "$sha_file" "$org_file" "$out_file"
}

maybe_repair_sha512_if_stale_references() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    [[ -e "$sha_file" ]] || return 0
    sha512_file_has_missing_paths "$sha_file" || return 0

    echo -e "${YELLOW}SHA512:${RESET} $sha_file lists file(s) missing on disk — repairing hash file."
    prune_missing_paths_from_sha512_file "$sha_file"

    if pair_needs_media_hash_check "$org_file" "$out_file" "$sha_file"; then
        ensure_pair_media_sha_file "$org_file" "$out_file" "$sha_file" || return 1
    elif [[ ! -e "$sha_file" ]]; then
        create_sha512_pair_file "$sha_file" "$org_file" "$out_file"
    fi

    append_transcript_variant_hashes_for_audio "$org_file" "$sha_file"
    append_transcript_variant_hashes_for_audio "$out_file" "$sha_file"

    if pair_needs_transcript_loop_scan "$org_file" "$out_file"; then
        check_transcript_loops_for_pair "$org_file" "$out_file" "$sha_file"
        append_transcript_variant_hashes_for_audio "$org_file" "$sha_file"
        append_transcript_variant_hashes_for_audio "$out_file" "$sha_file"
    fi

    if verify_sha512_file_existing_only "$sha_file"; then
        echo -e "${CYAN}SHA512 VERIFIED:${RESET} $sha_file (repaired)"
        return 0
    fi

    echo -e "${YELLOW}SHA512 VERIFY FAILED:${RESET} $sha_file (continuing)"
    return 1
}

pair_needs_transcription_work() {
    local org_file="$1"
    local out_file="$2"

    [[ "$DO_TRANSCRIPTION" == "yes" ]] || return 1
    transcript_all_variants_exist_for_audio "$org_file" || return 0
    transcript_all_variants_exist_for_audio "$out_file" || return 0
    return 1
}

# Path whisper inference writes before rename (…_ORG.txt / …_OUTPUT.txt).
txt_file_for_audio() {
    local audio_file="$1"
    printf '%s\n' "${audio_file%.*}.txt"
}

transcript_variant_path_for_audio() {
    local audio_file="$1"
    local variant_suffix="$2"
    printf '%s_%s.txt\n' "${audio_file%.*}" "$variant_suffix"
}

txt_file_loop_variant() {
    printf '%s%s.txt\n' "${1%.txt}" "$TRANSCRIPT_LOOP_MARKER"
}

transcript_variant_resolved_path() {
    local variant_txt="$1"
    local loop_txt

    loop_txt="$(txt_file_loop_variant "$variant_txt")"
    if [[ -e "$loop_txt" ]]; then
        printf '%s\n' "$loop_txt"
    elif [[ -e "$variant_txt" ]]; then
        printf '%s\n' "$variant_txt"
    else
        printf '%s\n' "$variant_txt"
    fi
}

transcript_variant_exists_for_audio() {
    local audio_file="$1"
    local variant_suffix="$2"
    local variant_txt loop_txt

    variant_txt="$(transcript_variant_path_for_audio "$audio_file" "$variant_suffix")"
    loop_txt="$(txt_file_loop_variant "$variant_txt")"
    [[ -e "$variant_txt" || -e "$loop_txt" ]]
}

# Remove one variant (and loop rename) before re-transcribing; optional sha512 line cleanup.
remove_transcript_variant_files_for_audio() {
    local audio_file="$1"
    local variant_suffix="$2"
    local sha_file="${3:-}"
    local variant_txt loop_txt base_txt path

    variant_txt="$(transcript_variant_path_for_audio "$audio_file" "$variant_suffix")"
    loop_txt="$(txt_file_loop_variant "$variant_txt")"
    base_txt="$(txt_file_for_audio "$audio_file")"

    for path in "$variant_txt" "$loop_txt" "$base_txt"; do
        [[ -e "$path" ]] || continue
        if [[ -n "$sha_file" ]] && sha_file_has_entry "$sha_file" "$path"; then
            remove_sha512_entry "$sha_file" "$path"
        fi
        rm -f -- "$path"
    done
}

transcript_all_variants_exist_for_audio() {
    local audio_file="$1"
    local tag

    for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
        transcript_variant_exists_for_audio "$audio_file" "$tag" || return 1
    done
}

transcript_any_variant_exists_for_audio() {
    local audio_file="$1"
    local tag

    for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
        transcript_variant_exists_for_audio "$audio_file" "$tag" && return 0
    done
    return 1
}

print_missing_transcript_variants_for_audio() {
    local audio_file="$1"
    local tag variant_txt

    for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
        if ! transcript_variant_exists_for_audio "$audio_file" "$tag"; then
            variant_txt="$(transcript_variant_path_for_audio "$audio_file" "$tag")"
            print_suggestion "TRANSCRIPTION: Missing transcript: $variant_txt"
        fi
    done
}

is_expected_transcript_path() {
    local txt_path="$1"
    local audio_file="$2"
    local tag variant_txt loop_txt

    for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
        variant_txt="$(transcript_variant_path_for_audio "$audio_file" "$tag")"
        if [[ "$txt_path" == "$variant_txt" ]]; then
            return 0
        fi
        loop_txt="$(txt_file_loop_variant "$variant_txt")"
        if [[ "$txt_path" == "$loop_txt" ]]; then
            return 0
        fi
    done
    return 1
}

collect_transcript_txt_files_for_audio() {
    local audio_file="$1"
    local -n _paths_ref="$2"
    local f prefix

    _paths_ref=()
    prefix="${audio_file%.*}"
    for f in "${prefix}"*.txt; do
        [[ -e "$f" ]] || continue
        _paths_ref+=("$f")
    done
}

pair_list_legacy_transcript_files() {
    local org_file="$1"
    local out_file="$2"
    local audio_file txt_path

    for audio_file in "$org_file" "$out_file"; do
        collect_transcript_txt_files_for_audio "$audio_file" _pair_txt_paths
        for txt_path in "${_pair_txt_paths[@]}"; do
            if ! is_expected_transcript_path "$txt_path" "$audio_file"; then
                printf '%s\n' "$txt_path"
            fi
        done
    done
}

pair_list_unflagged_loop_transcript_files() {
    local org_file="$1"
    local out_file="$2"
    local audio_file txt_path

    for audio_file in "$org_file" "$out_file"; do
        collect_transcript_txt_files_for_audio "$audio_file" _pair_txt_paths
        for txt_path in "${_pair_txt_paths[@]}"; do
            [[ "$txt_path" == *"${TRANSCRIPT_LOOP_MARKER}.txt" ]] && continue
            if transcript_has_repetition_loop "$txt_path"; then
                printf '%s\n' "$txt_path"
            fi
        done
    done
}

pair_needs_transcript_redo_offer() {
    local org_file="$1"
    local out_file="$2"
    local legacy unflagged

    mapfile -t unflagged < <(pair_list_unflagged_loop_transcript_files "$org_file" "$out_file")
    (( ${#unflagged[@]} > 0 )) && return 0

    mapfile -t legacy < <(pair_list_legacy_transcript_files "$org_file" "$out_file")
    (( ${#legacy[@]} == 0 )) && return 1

    # Legacy-only cleanup redo when new-format variants already exist.
    transcript_all_variants_exist_for_audio "$org_file" \
        && transcript_all_variants_exist_for_audio "$out_file"
}

remove_legacy_transcript_files_for_pair() {
    local org_file="$1"
    local out_file="$2"
    local -a legacy=()
    local txt_path

    mapfile -t legacy < <(pair_list_legacy_transcript_files "$org_file" "$out_file")
    for txt_path in "${legacy[@]}"; do
        [[ -e "$txt_path" ]] || continue
        rm -f -- "$txt_path"
        echo -e "${YELLOW}LEGACY REMOVED:${RESET} $txt_path"
    done
}

pair_media_hashes_valid_in_sha() {
    local sha_file="$1"
    local org_file="$2"
    local out_file="$3"
    local tmp

    [[ -e "$sha_file" && -e "$org_file" && -e "$out_file" ]] || return 1
    grep -Fq "  $org_file" "$sha_file" || return 1
    grep -Fq "  $out_file" "$sha_file" || return 1

    tmp="$(mktemp)"
    grep -F "  $org_file" "$sha_file" >"$tmp"
    grep -F "  $out_file" "$sha_file" >>"$tmp"
    sha512sum -c --quiet -- "$tmp"
    local ok=$?
    rm -f -- "$tmp"
    return "$ok"
}

prepare_sha_for_transcript_redo() {
    local sha_file="$1"
    local org_file="$2"
    local out_file="$3"
    local tmp

    if pair_media_hashes_valid_in_sha "$sha_file" "$org_file" "$out_file"; then
        echo -e "${CYAN}SHA512:${RESET} ORG and OUTPUT media hashes OK — keeping them, replacing transcript entries only."
        tmp="$(mktemp)"
        grep -F "  $org_file" "$sha_file" >"$tmp"
        grep -F "  $out_file" "$sha_file" >>"$tmp"
        mv -f -- "$tmp" "$sha_file"
        return 0
    fi

    echo -e "${YELLOW}SHA512:${RESET} ORG/OUTPUT missing or invalid — rebuilding hash file for media files."
    create_sha512_pair_file "$sha_file" "$org_file" "$out_file"
}

remove_all_transcript_files_for_pair() {
    local org_file="$1"
    local out_file="$2"
    local audio_file txt_path

    for audio_file in "$org_file" "$out_file"; do
        collect_transcript_txt_files_for_audio "$audio_file" _pair_txt_paths
        for txt_path in "${_pair_txt_paths[@]}"; do
            rm -f -- "$txt_path"
        done
    done
}

print_transcript_redo_detail_line() {
    local indent="$1"
    local value_col="$2"
    local label="$3"
    local value="$4"
    local spaces

    spaces=$(( value_col - ${#indent} - ${#label} ))
    (( spaces < 0 )) && spaces=0
    printf "%s%s%*s%s\n" "$indent" "$label" "$spaces" "" "$value"
}

print_transcript_redo_pair_details() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"
    local -a legacy=() unflagged=()
    local indent="  " label_width value_col i
    local legacy_label loop_label

    mapfile -t legacy < <(pair_list_legacy_transcript_files "$org_file" "$out_file")
    mapfile -t unflagged < <(pair_list_unflagged_loop_transcript_files "$org_file" "$out_file")

    legacy_label="Legacy (no _VAD / _noVAD):"
    loop_label="Loop (not ${TRANSCRIPT_LOOP_MARKER}):"

    label_width=0
    for i in "ORG:" "OUTPUT:" "SHA512:" "$legacy_label" "$loop_label"; do
        (( ${#i} > label_width )) && label_width=${#i}
    done
    value_col=$(( ${#indent} + label_width + 1 ))

    print_suggestion "TRANSCRIPT RE-DO SUGGESTED: ORG/OUTPUT pair needs fresh VAD + noVAD transcripts."
    print_transcript_redo_detail_line "$indent" "$value_col" "ORG:" "$org_file"
    print_transcript_redo_detail_line "$indent" "$value_col" "OUTPUT:" "$out_file"
    print_transcript_redo_detail_line "$indent" "$value_col" "SHA512:" "$sha_file"

    if (( ${#legacy[@]} > 0 )); then
        print_transcript_redo_detail_line "$indent" "$value_col" "$legacy_label" "${legacy[0]}"
        for (( i = 1; i < ${#legacy[@]}; i++ )); do
            printf "%*s%s\n" "$value_col" "" "${legacy[$i]}"
        done
    fi
    if (( ${#unflagged[@]} > 0 )); then
        print_transcript_redo_detail_line "$indent" "$value_col" "$loop_label" "${unflagged[0]}"
        for (( i = 1; i < ${#unflagged[@]}; i++ )); do
            printf "%*s%s\n" "$value_col" "" "${unflagged[$i]}"
        done
    fi
}

voice_pair_stem_from_org() {
    local org_file="$1"
    local stem="${org_file%.*}"
    stem="${stem%_ORG}"
    printf '%s' "$stem"
}

voice_mark_pair_active() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="${3:-}"
    local stem

    [[ -e "$org_file" && -e "$out_file" ]] || return 0
    stem=$(voice_pair_stem_from_org "$org_file")
    if [[ -z "$sha_file" ]]; then
        sha_file="$(sha_file_from_pair "$org_file")"
    fi
    if [[ -n "${voice_active_stem_seen[$stem]+x}" ]]; then
        return 0
    fi
    voice_active_stem_seen["$stem"]=1
    voice_active_orgs+=("$org_file")
    voice_active_outs+=("$out_file")
    voice_active_shas+=("$sha_file")
}

populate_active_transcript_redo_queue() {
    local i org_file out_file sha_file

    [[ "$DO_TRANSCRIPTION" == "yes" ]] || return 0
    (( ${#voice_active_orgs[@]} == 0 )) && return 0

    transcript_redo_orgs=()
    transcript_redo_outs=()
    transcript_redo_shas=()

    for i in "${!voice_active_orgs[@]}"; do
        org_file="${voice_active_orgs[$i]}"
        out_file="${voice_active_outs[$i]}"
        sha_file="${voice_active_shas[$i]}"
        enqueue_transcript_redo_if_needed "$org_file" "$out_file" "$sha_file"
    done
}

build_voice_transcribe_queue() {
    local i org_file out_file sha_file need_org=0 need_out=0

    [[ "$DO_TRANSCRIPTION" == "yes" ]] || return 0
    [[ "$mode" == "real" ]] || return 0
    (( ${#voice_active_orgs[@]} == 0 )) && return 0

    transcribe_queue_orgs=()
    transcribe_queue_outs=()
    transcribe_queue_shas=()

    for i in "${!voice_active_orgs[@]}"; do
        org_file="${voice_active_orgs[$i]}"
        out_file="${voice_active_outs[$i]}"
        sha_file="${voice_active_shas[$i]}"

        [[ -e "$org_file" && -e "$out_file" ]] || continue

        if transcript_all_variants_exist_for_audio "$org_file"; then
            need_org=0
        else
            need_org=1
        fi

        if transcript_all_variants_exist_for_audio "$out_file"; then
            need_out=0
        else
            need_out=1
        fi

        if (( need_org || need_out )); then
            enqueue_pair_for_transcription "$org_file" "$out_file" "$sha_file"
        fi
    done
}

pair_on_transcribe_queue() {
    local org_file="$1"
    local i

    for i in "${!transcribe_queue_orgs[@]}"; do
        [[ "${transcribe_queue_orgs[$i]}" == "$org_file" ]] && return 0
    done
    return 1
}

enqueue_pair_for_transcription() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    pair_on_transcribe_queue "$org_file" && return 0
    transcribe_queue_orgs+=("$org_file")
    transcribe_queue_outs+=("$out_file")
    transcribe_queue_shas+=("$sha_file")
}

pair_on_transcript_redo_queue() {
    local org_file="$1"
    local i

    for i in "${!transcript_redo_orgs[@]}"; do
        [[ "${transcript_redo_orgs[$i]}" == "$org_file" ]] && return 0
    done
    return 1
}

execute_transcript_redo_for_pair() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    echo
    print_deletion "TRANSCRIPT RE-DO: Removing old transcript files for this pair."
    voice_processing_begin
    remove_all_transcript_files_for_pair "$org_file" "$out_file"
    ensure_pair_media_sha_file "$org_file" "$out_file" "$sha_file"
    prepare_sha_for_transcript_redo "$sha_file" "$org_file" "$out_file"
    voice_processing_end
    enqueue_pair_for_transcription "$org_file" "$out_file" "$sha_file"
    ((++stats_transcript_redos))
}

enqueue_transcript_redo_if_needed() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    pair_needs_transcript_redo_offer "$org_file" "$out_file" || return 0
    pair_on_transcript_redo_queue "$org_file" && return 0

    transcript_redo_orgs+=("$org_file")
    transcript_redo_outs+=("$out_file")
    transcript_redo_shas+=("$sha_file")
}

process_transcript_redo_queue() {
    [[ "$DO_TRANSCRIPTION" == "yes" ]] || return 0
    (( ${#transcript_redo_orgs[@]} == 0 )) && return 0

    if [[ "$mode" == "dry-run" ]]; then
        local i
        echo
        print_suggestion "TRANSCRIPT RE-DO QUEUE: ${#transcript_redo_orgs[@]} pair(s)"
        for i in "${!transcript_redo_orgs[@]}"; do
            echo
            print_transcript_redo_pair_details \
                "${transcript_redo_orgs[$i]}" \
                "${transcript_redo_outs[$i]}" \
                "${transcript_redo_shas[$i]}"
            print_suggestion "Would prompt (with [F]/[G]): redo all four transcripts?"
            print_deletion "Would remove all transcript .txt files for this pair, then queue transcription."
        done
        transcript_redo_orgs=()
        transcript_redo_outs=()
        transcript_redo_shas=()
        return 0
    fi

    [[ "$mode" == "real" ]] || return 0

    local total_files idx
    total_files=${#transcript_redo_orgs[@]}
    idx=0

    echo
    print_suggestion "TRANSCRIPT RE-DO BATCH: ${total_files} pair(s) need legacy/loop cleanup before re-transcribing."

    while (( idx < total_files )); do
        [[ "$skip_remaining_redo_prompts" == yes ]] && break

        declare -a batch_orgs=()
        declare -a batch_outs=()
        declare -a batch_shas=()
        declare -a batch_selected=()

        local remaining_total batch_size_now batch_count batch_yes batch_no accept_all_remaining finish_batch_now
        finish_batch_now=no
        remaining_total=$(( total_files - idx ))
        batch_size_now=$BATCH_SIZE
        (( remaining_total < batch_size_now )) && batch_size_now=$remaining_total

        batch_count=0
        batch_yes=0
        batch_no=0
        accept_all_remaining=no

        while (( idx < total_files && batch_count < batch_size_now )); do
            local org_file out_file sha_file overall_pos batch_pos still_after_this

            org_file="${transcript_redo_orgs[$idx]}"
            out_file="${transcript_redo_outs[$idx]}"
            sha_file="${transcript_redo_shas[$idx]}"

            overall_pos=$(( idx + 1 ))
            batch_pos=$(( batch_count + 1 ))
            still_after_this=$(( total_files - overall_pos ))

            if [[ "$accept_all_remaining" == "yes" ]]; then
                batch_selected+=("yes")
                ((++batch_yes))
                batch_orgs+=("$org_file")
                batch_outs+=("$out_file")
                batch_shas+=("$sha_file")
                ((idx+=1))
                ((batch_count+=1))
                continue
            fi

            echo
            print_prompt_and_decision_summary \
                "$batch_pos" "$batch_size_now" "$overall_pos" "$total_files" "$still_after_this" \
                "$batch_yes" "$batch_no"
            print_transcript_redo_pair_details "$org_file" "$out_file" "$sha_file"
            read_batch_choice "Redo all four transcripts for this pair?"

            case "$BATCH_CHOICE_ACTION" in
                quit)
                    voice_quit
                    ;;
                finish_batch)
                    finish_batch_now=yes
                    echo "Finishing re-do batch — processing ${batch_yes} selected pair(s) only."
                    break
                    ;;
                skip_all)
                    skip_remaining_redo_prompts=yes
                    finish_batch_now=yes
                    echo "Skipping all further re-do prompts — processing ${batch_yes} selected pair(s) from this batch."
                    break
                    ;;
                accept_all)
                    batch_selected+=("yes")
                    ((++batch_yes))
                    accept_all_remaining=yes
                    batch_orgs+=("$org_file")
                    batch_outs+=("$out_file")
                    batch_shas+=("$sha_file")
                    ((idx+=1))
                    ((batch_count+=1))
                    continue
                    ;;
                decided)
                    if [[ "$BATCH_CHOICE_DECISION" == yes ]]; then
                        batch_selected+=("yes")
                        ((++batch_yes))
                    else
                        batch_selected+=("no")
                        ((++batch_no))
                    fi
                    ;;
            esac

            batch_orgs+=("$org_file")
            batch_outs+=("$out_file")
            batch_shas+=("$sha_file")

            ((idx+=1))
            ((batch_count+=1))
        done

        if (( ${#batch_orgs[@]} > 0 )); then
            local selected_total selected_pos i
            selected_total=0
            for decision in "${batch_selected[@]}"; do
                [[ "$decision" == "yes" ]] && ((selected_total+=1))
            done

            if (( selected_total > 0 )); then
                selected_pos=0
                for i in "${!batch_orgs[@]}"; do
                    if [[ "${batch_selected[$i]}" == "yes" ]]; then
                        ((selected_pos+=1))
                        execute_transcript_redo_for_pair \
                            "${batch_orgs[$i]}" "${batch_outs[$i]}" "${batch_shas[$i]}"
                    fi
                done
            elif (( finish_batch_now )); then
                echo "No pairs selected for re-do in this batch."
            fi
        fi

        if [[ "$finish_batch_now" == yes ]]; then
            idx=$(batch_prompt_finish_skip_idx "$idx" "$batch_size_now" "$batch_count")
            if [[ "$skip_remaining_redo_prompts" != yes ]]; then
                print_suggestion "Proceeding to transcription prompts; remaining re-do pairs deferred to a later run."
            fi
        fi

        [[ "$skip_remaining_redo_prompts" == yes ]] && break
        [[ "$finish_batch_now" == yes ]] && break
    done

    transcript_redo_orgs=()
    transcript_redo_outs=()
    transcript_redo_shas=()
}

transcript_has_repetition_loop() {
    local txt_file="$1"

    [[ -e "$txt_file" ]] || return 1

    awk '
    BEGIN { found = 0; rep = 0 }
    /^\[/ {
        t = $0
        sub(/^\[[^]]*\][[:space:]]*/, "", t)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
        if (t == "") next
        if (t == prev) {
            rep++
            if (rep >= 2) {
                found = 1
                exit 0
            }
        } else {
            rep = 1
        }
        prev = t
    }
    END {
        if (found) {
            exit 0
        }
        exit 1
    }
    ' "$txt_file"
}

remove_sha512_entry() {
    local sha_file="$1"
    local target_file="$2"
    local tmp

    [[ -e "$sha_file" ]] || return 0
    tmp="$(mktemp)"
    grep -Fv "  $target_file" "$sha_file" >"$tmp" || true
    if [[ -s "$tmp" ]]; then
        mv -f -- "$tmp" "$sha_file"
    else
        rm -f -- "$sha_file" "$tmp"
    fi
}

replace_sha512_transcript_entry() {
    local sha_file="$1"
    local old_path="$2"
    local new_path="$3"

    [[ -n "$sha_file" && -e "$sha_file" ]] || return 0
    if sha_file_has_entry "$sha_file" "$old_path"; then
        remove_sha512_entry "$sha_file" "$old_path"
    fi
    append_sha512_for_file_if_missing "$sha_file" "$new_path"
}

flag_transcript_loop_if_needed() {
    local txt_file="$1"
    local sha_file="${2:-}"
    local loop_txt

    [[ -e "$txt_file" ]] || return 0
    [[ "$txt_file" == *"${TRANSCRIPT_LOOP_MARKER}.txt" ]] && return 0

    transcript_has_repetition_loop "$txt_file" || return 0

    loop_txt="$(txt_file_loop_variant "$txt_file")"
    [[ -e "$loop_txt" ]] && return 0

    if [[ "$mode" == "dry-run" ]]; then
        print_suggestion "POSSIBLE LOOP: would rename: $txt_file $ARROW $loop_txt"
        return 0
    fi

    mv -f -- "$txt_file" "$loop_txt"
    echo -e "${YELLOW}POSSIBLE LOOP:${RESET} renamed transcript: $loop_txt"
    replace_sha512_transcript_entry "$sha_file" "$txt_file" "$loop_txt"
}

check_transcript_loops_for_audio() {
    local audio_file="$1"
    local sha_file="$2"
    local tag variant_txt txt_path

    for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
        variant_txt="$(transcript_variant_path_for_audio "$audio_file" "$tag")"
        if [[ -e "$variant_txt" ]]; then
            flag_transcript_loop_if_needed "$variant_txt" "$sha_file"
        fi
        txt_path="$(transcript_variant_resolved_path "$variant_txt")"
        if [[ -e "$txt_path" && "$txt_path" != "$variant_txt" ]]; then
            flag_transcript_loop_if_needed "$txt_path" "$sha_file"
        fi
    done
}

check_transcript_loops_for_pair() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    check_transcript_loops_for_audio "$org_file" "$sha_file"
    check_transcript_loops_for_audio "$out_file" "$sha_file"
}

print_transcription_dry_run_steps() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"
    local audio_file tag host port variant_txt

    print_transcribe_connectivity_checks
    if [[ ! -e "$sha_file" ]]; then
        echo "sha512sum -- \"$org_file\" \"$out_file\" > \"$sha_file\""
    fi

    for audio_file in "$org_file" "$out_file"; do
        for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
            variant_txt="$(transcript_variant_path_for_audio "$audio_file" "$tag")"
            if transcript_variant_exists_for_audio "$audio_file" "$tag"; then
                [[ -e "$variant_txt" ]] \
                    && flag_transcript_loop_if_needed "$variant_txt" "$sha_file"
                echo "sha512sum -- \"$(transcript_variant_resolved_path "$variant_txt")\" >> \"$sha_file\""
                continue
            fi
            host="$(whisper_host_for_suffix "$tag")"
            port="$(whisper_port_for_suffix "$tag")"
            echo "# ${tag} @ ${host}:${port}"
            echo "curl -s $(whisper_inference_url "$host" "$port") -F file=@\"$audio_file\" -F language=${TRANSCRIBE_LANGUAGE} -F translate=${TRANSCRIBE_TRANSLATE} -F response_format=verbose_json | python3 ... > $(txt_file_for_audio "$audio_file")"
            echo "# rename $(txt_file_for_audio "$audio_file") -> $variant_txt"
            echo "sha512sum -- \"$variant_txt\" >> \"$sha_file\""
        done
    done
    echo "sha512sum -c --quiet -- \"$sha_file\""
}

sha_file_has_entry() {
    local sha_file="$1"
    local target_file="$2"

    [[ -e "$sha_file" ]] || return 1
    grep -Fq "  $target_file" "$sha_file"
}

append_sha512_for_file_if_missing() {
    local sha_file="$1"
    local target_file="$2"

    [[ -e "$target_file" ]] || return 1

    if [[ -e "$sha_file" ]] && sha_file_has_entry "$sha_file" "$target_file"; then
        return 0
    fi

    sha512sum -- "$target_file" >> "$sha_file"
}

ensure_pair_sha_file() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    if pair_needs_media_hash_check "$org_file" "$out_file" "$sha_file"; then
        ensure_pair_media_sha_file "$org_file" "$out_file" "$sha_file"
        return $?
    fi

    [[ -e "$org_file" && -e "$out_file" ]] || return 1

    if [[ -e "$sha_file" ]]; then
        return 0
    fi

    if [[ "$mode" == "dry-run" ]]; then
        return 0
    fi

    create_sha512_pair_file "$sha_file" "$org_file" "$out_file"
}

append_transcript_variant_hashes_for_audio() {
    local audio_file="$1"
    local sha_file="$2"
    local tag variant_txt resolved_txt

    for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
        if transcript_variant_exists_for_audio "$audio_file" "$tag"; then
            variant_txt="$(transcript_variant_path_for_audio "$audio_file" "$tag")"
            resolved_txt="$(transcript_variant_resolved_path "$variant_txt")"
            append_sha512_for_file_if_missing "$sha_file" "$resolved_txt"
        fi
    done
}

sync_existing_transcript_hashes() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    maybe_repair_sha512_if_stale_references "$org_file" "$out_file" "$sha_file"

    if pair_needs_media_hash_check "$org_file" "$out_file" "$sha_file"; then
        ensure_pair_media_sha_file "$org_file" "$out_file" "$sha_file" || return 1
    elif [[ ! -e "$sha_file" ]]; then
        if [[ "$mode" != "dry-run" ]]; then
            create_sha512_pair_file "$sha_file" "$org_file" "$out_file"
        fi
    fi

    append_transcript_variant_hashes_for_audio "$org_file" "$sha_file"
    append_transcript_variant_hashes_for_audio "$out_file" "$sha_file"

    if pair_needs_transcript_loop_scan "$org_file" "$out_file"; then
        check_transcript_loops_for_pair "$org_file" "$out_file" "$sha_file"
        append_transcript_variant_hashes_for_audio "$org_file" "$sha_file"
        append_transcript_variant_hashes_for_audio "$out_file" "$sha_file"
    fi
}

file_size_bytes() {
    local file="$1"
    local size

    size="$(wc -c < "$file" 2>/dev/null | tr -d '[:space:]')"

    if [[ -z "$size" || ! "$size" =~ ^[0-9]+$ ]]; then
        echo 0
        return 0
    fi

    echo "$size"
}

should_delete_partial_txt_on_interrupt() {
    local txt_file="$1"
    local size_bytes

    [[ -e "$txt_file" ]] || return 1

    size_bytes="$(file_size_bytes "$txt_file")"
    (( size_bytes <= PARTIAL_TXT_DELETE_MAX_BYTES ))
}

# Remove the file whisper writes before rename (…_ORG.txt / …_OUTPUT.txt) when Ctrl-C mid-request.
remove_inflight_transcription_outputs() {
    local msg=""
    local size_bytes

    [[ "$transcription_in_flight" == yes ]] || return 0

    if [[ -n "$current_transcription_write_path" && -e "$current_transcription_write_path" ]]; then
        size_bytes="$(file_size_bytes "$current_transcription_write_path")"
        rm -f -- "$current_transcription_write_path"
        msg="REMOVED INCOMPLETE TRANSCRIPT (interrupted): $current_transcription_write_path (${size_bytes} bytes)"
    fi

    transcription_in_flight=no
    current_transcription_write_path=""
    current_transcription_target_path=""
    current_txt_file=""

    if [[ -n "$msg" ]]; then
        printf '%s\n' "$msg"
    fi
}

run_one_transcription_variant() {
    local audio_file="$1"
    local sha_file="$2"
    local variant_suffix="$3"
    local whisper_host="$4"
    local whisper_port="$5"
    local server_base variant_txt resolved_txt

    variant_txt="$(transcript_variant_path_for_audio "$audio_file" "$variant_suffix")"

    if transcript_variant_exists_for_audio "$audio_file" "$variant_suffix"; then
        if [[ "$transcription_force_redo" == yes ]]; then
            echo -e "${YELLOW}TRANSCRIPTION REDO (${variant_suffix}):${RESET} already present — ${variant_txt} — redoing"
            remove_transcript_variant_files_for_audio "$audio_file" "$variant_suffix" "$sha_file"
        else
            echo -e "${YELLOW}TRANSCRIPTION SKIP (${variant_suffix}):${RESET} already present — ${variant_txt}"
            [[ -e "$variant_txt" ]] && flag_transcript_loop_if_needed "$variant_txt" "$sha_file"
            resolved_txt="$(transcript_variant_resolved_path "$variant_txt")"
            append_sha512_for_file_if_missing "$sha_file" "$resolved_txt"
            return 0
        fi
    fi

    if ! transcription_dependencies_ok; then
        echo -e "${YELLOW}TRANSCRIPTION SKIPPED:${RESET} curl and python3 are required"
        return 0
    fi

    if ! ensure_transcribe_endpoint_ready "$whisper_host" "$whisper_port" "${variant_suffix}"; then
        echo -e "${YELLOW}TRANSCRIPTION SKIP (${variant_suffix}):${RESET} server down — ${variant_txt} not created"
        return 0
    fi
    check_free_space_or_exit "."

    server_base="$(txt_file_for_audio "$audio_file")"
    current_txt_file="$variant_txt"
    current_transcription_write_path="$server_base"
    current_transcription_target_path="$variant_txt"
    transcription_in_flight=yes

    echo -e "${CYAN}TRANSCRIBE (${variant_suffix}):${RESET} ${whisper_host}:${whisper_port} $ARROW $variant_txt"
    if [[ "$whisper_endpoint_announced_key" != "${whisper_host}:${whisper_port}" ]]; then
        print_whisper_endpoint_ok "$whisper_host" "$whisper_port"
    fi

    if ! run_whisper_transcription_to_file "$whisper_host" "$whisper_port" "$audio_file" "$server_base"; then
        transcription_in_flight=no
        current_transcription_write_path=""
        current_transcription_target_path=""
        current_txt_file=""
        exit 1
    fi

    if [[ "$server_base" != "$variant_txt" ]]; then
        mv -f -- "$server_base" "$variant_txt"
    fi
    current_transcription_write_path=""

    flag_transcript_loop_if_needed "$variant_txt" "$sha_file"
    resolved_txt="$(transcript_variant_resolved_path "$variant_txt")"
    echo -e "${CYAN}Saved:${RESET} $resolved_txt"
    append_sha512_for_file_if_missing "$sha_file" "$resolved_txt"
    transcription_in_flight=no
    current_transcription_target_path=""
    current_txt_file=""
}

run_all_transcriptions_for_audio() {
    local audio_file="$1"
    local sha_file="$2"
    local tag host port

    for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
        host="$(whisper_host_for_suffix "$tag")"
        port="$(whisper_port_for_suffix "$tag")"
        run_one_transcription_variant "$audio_file" "$sha_file" "$tag" "$host" "$port"
    done
}

queue_or_print_missing_transcriptions() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"
    local need_org=0 need_out=0

    [[ "$DO_TRANSCRIPTION" == "yes" ]] || return 0
    [[ -e "$org_file" && -e "$out_file" ]] || return 0

    if transcript_all_variants_exist_for_audio "$org_file"; then
        need_org=0
    else
        need_org=1
    fi

    if transcript_all_variants_exist_for_audio "$out_file"; then
        need_out=0
    else
        need_out=1
    fi

    if [[ "$mode" == "dry-run" ]]; then
        enqueue_transcript_redo_if_needed "$org_file" "$out_file" "$sha_file"
        if (( need_org || need_out )); then
            if transcript_any_variant_exists_for_audio "$org_file" && need_out -eq 1; then
                print_suggestion "TRANSCRIPTION: Partial ORG transcripts; still need OUTPUT variants:"
                print_missing_transcript_variants_for_audio "$out_file"
            elif transcript_any_variant_exists_for_audio "$out_file" && need_org -eq 1; then
                print_suggestion "TRANSCRIPTION: Partial OUTPUT transcripts; still need ORG variants:"
                print_missing_transcript_variants_for_audio "$org_file"
            else
                print_missing_transcript_variants_for_audio "$org_file"
                print_missing_transcript_variants_for_audio "$out_file"
            fi
            if [[ ! -e "$sha_file" ]]; then
                echo "sha512sum -- \"$org_file\" \"$out_file\" > \"$sha_file\""
            fi
            print_transcription_dry_run_steps "$org_file" "$out_file" "$sha_file"
        else
            print_suggestion "TRANSCRIPTION: All transcript variants present; sync sha512 if needed"
            if [[ ! -e "$sha_file" ]]; then
                echo "sha512sum -- \"$org_file\" \"$out_file\" > \"$sha_file\""
            fi
            print_transcription_dry_run_steps "$org_file" "$out_file" "$sha_file"
        fi
        echo "----------------------------------------"
        return 0
    fi

    sync_existing_transcript_hashes "$org_file" "$out_file" "$sha_file"
}

run_transcriptions_for_pair() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    voice_processing_begin
    ensure_pair_sha_file "$org_file" "$out_file" "$sha_file"
    if ! check_transcribe_hosts_or_exit; then
        sync_existing_transcript_hashes "$org_file" "$out_file" "$sha_file"
        voice_processing_end
        return 0
    fi
    sync_existing_transcript_hashes "$org_file" "$out_file" "$sha_file"

    run_all_transcriptions_for_audio "$org_file" "$sha_file"
    run_all_transcriptions_for_audio "$out_file" "$sha_file"

    check_transcript_loops_for_pair "$org_file" "$out_file" "$sha_file"
    sync_existing_transcript_hashes "$org_file" "$out_file" "$sha_file"
    voice_processing_end
    ((++stats_pairs_transcribed))
}

process_transcription_queue() {
    [[ "$DO_TRANSCRIPTION" == "yes" ]] || return 0

    if [[ "$mode" == "real" ]] && (( ${#voice_active_orgs[@]} == 0 )); then
        return 0
    fi

    populate_active_transcript_redo_queue
    process_transcript_redo_queue

    [[ "$mode" == "real" ]] || return 0

    build_voice_transcribe_queue

    local total_files idx
    total_files=${#transcribe_queue_outs[@]}
    idx=0

    (( total_files == 0 )) && return 0

    echo
    print_suggestion "TRANSCRIPTION BATCH: ${total_files} pair(s) queued for transcription."

    while (( idx < total_files )); do
        [[ "$skip_remaining_transcription_prompts" == yes ]] && break

        declare -a batch_orgs=()
        declare -a batch_outs=()
        declare -a batch_shas=()
        declare -a batch_selected=()

        local remaining_total batch_size_now batch_count batch_yes batch_no accept_all_remaining finish_batch_now
        finish_batch_now=no
        remaining_total=$(( total_files - idx ))
        batch_size_now=$BATCH_SIZE
        (( remaining_total < batch_size_now )) && batch_size_now=$remaining_total

        batch_count=0
        batch_yes=0
        batch_no=0
        accept_all_remaining=no

        while (( idx < total_files && batch_count < batch_size_now )); do
            local org_file out_file sha_file overall_pos batch_pos still_after_this

            org_file="${transcribe_queue_orgs[$idx]}"
            out_file="${transcribe_queue_outs[$idx]}"
            sha_file="${transcribe_queue_shas[$idx]}"

            overall_pos=$(( idx + 1 ))
            batch_pos=$(( batch_count + 1 ))
            still_after_this=$(( total_files - overall_pos ))

            if [[ "$accept_all_remaining" == "yes" ]]; then
                batch_selected+=("yes")
                ((++batch_yes))
                batch_orgs+=("$org_file")
                batch_outs+=("$out_file")
                batch_shas+=("$sha_file")
                ((idx+=1))
                ((batch_count+=1))
                continue
            fi

            echo
            print_prompt_and_decision_summary \
                "$batch_pos" "$batch_size_now" "$overall_pos" "$total_files" "$still_after_this" \
                "$batch_yes" "$batch_no"
            print_transcription_pair_block "$org_file" "$out_file" "$sha_file"
            read_batch_choice "Run transcription for this pair now?"

            case "$BATCH_CHOICE_ACTION" in
                quit)
                    voice_quit
                    ;;
                finish_batch)
                    finish_batch_now=yes
                    echo "Finishing this batch — processing ${batch_yes} selected transcription(s) only."
                    break
                    ;;
                skip_all)
                    skip_remaining_transcription_prompts=yes
                    finish_batch_now=yes
                    echo "Skipping all further transcription prompts — processing ${batch_yes} selected from this batch."
                    break
                    ;;
                accept_all)
                    batch_selected+=("yes")
                    ((++batch_yes))
                    accept_all_remaining=yes
                    batch_orgs+=("$org_file")
                    batch_outs+=("$out_file")
                    batch_shas+=("$sha_file")
                    ((idx+=1))
                    ((batch_count+=1))
                    continue
                    ;;
                decided)
                    if [[ "$BATCH_CHOICE_DECISION" == yes ]]; then
                        batch_selected+=("yes")
                        ((++batch_yes))
                    else
                        batch_selected+=("no")
                        ((++files_skipped))
                        ((++batch_no))
                    fi
                    ;;
            esac

            batch_orgs+=("$org_file")
            batch_outs+=("$out_file")
            batch_shas+=("$sha_file")

            ((idx+=1))
            ((batch_count+=1))
        done

        if (( ${#batch_outs[@]} > 0 )); then
            local selected_total selected_pos
            selected_total=0
            for decision in "${batch_selected[@]}"; do
                [[ "$decision" == "yes" ]] && ((selected_total+=1))
            done

            if (( selected_total > 0 )); then
                selected_pos=0
                for i in "${!batch_outs[@]}"; do
                    if [[ "${batch_selected[$i]}" == "yes" ]]; then
                        local selected_left_after
                        ((selected_pos+=1))
                        selected_left_after=$(( selected_total - selected_pos ))

                        echo
                        print_processing_progress "$selected_pos" "$selected_total" "$selected_left_after" "$total_files"
                        print_transcription_pair_block \
                            "${batch_orgs[$i]}" "${batch_outs[$i]}" "${batch_shas[$i]}"
                        run_transcriptions_for_pair "${batch_orgs[$i]}" "${batch_outs[$i]}" "${batch_shas[$i]}"
                    fi
                done
            elif (( finish_batch_now )); then
                echo "No transcriptions selected in this batch."
            fi
        fi

        if [[ "$finish_batch_now" == yes ]]; then
            idx=$(batch_prompt_finish_skip_idx "$idx" "$batch_size_now" "$batch_count")
        fi

        if [[ "$skip_remaining_transcription_prompts" == yes ]]; then
            (( files_skipped += total_files - idx ))
            break
        fi
        [[ "$finish_batch_now" == yes ]] && break
    done

    transcribe_queue_orgs=()
    transcribe_queue_outs=()
    transcribe_queue_shas=()
}

prepare_selected_existing_pair() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    if [[ -e "$sha_file" ]]; then
        echo "$(voice_ts) Processing selected pair: $(basename "$org_file")"
        maybe_repair_sha512_if_stale_references "$org_file" "$out_file" "$sha_file" || true
        remove_legacy_transcript_files_for_pair "$org_file" "$out_file"
        if [[ "$DO_TRANSCRIPTION" == "yes" ]]; then
            print_suggestion "Re-transcribing all variants (ORG/OUTPUT × VAD/noVAD) for this selected pair."
            prepare_sha_for_transcript_redo "$sha_file" "$org_file" "$out_file"
            transcription_force_redo=yes
            run_transcriptions_for_pair "$org_file" "$out_file" "$sha_file"
            transcription_force_redo=no
        else
            sync_existing_transcript_hashes "$org_file" "$out_file" "$sha_file"
        fi
        return 0
    fi

    if [[ "$mode" == "dry-run" ]]; then
        echo
        print_sha_block "$sha_file" "$org_file" "$out_file"
        echo "sha512sum -- \"$org_file\" \"$out_file\" > \"$sha_file\""
        echo "sha512sum -c --quiet -- \"$sha_file\""
        queue_or_print_missing_transcriptions "$org_file" "$out_file" "$sha_file"
        echo "----------------------------------------"
        ((++files_affected))
        return 0
    fi

    check_free_space_or_exit "."

    echo
    print_sha_block "$sha_file" "$org_file" "$out_file"
    voice_processing_begin
    create_sha512_pair_file "$sha_file" "$org_file" "$out_file"
    voice_processing_end

    sync_existing_transcript_hashes "$org_file" "$out_file" "$sha_file"

    ((++files_affected))
    ((++stats_sha_backfilled))
}

record_change() {
    local old="$1"
    local mid="$2"
    local new="$3"
    affected_list+=("$old|$mid|$new")
}

cleanup_current_file() {
    local removed_msg=""
    local restored_msg=""
    local txt_removed_msg=""

    txt_removed_msg="$(remove_inflight_transcription_outputs)"

    if [[ -n "$current_txt_file" ]] && should_delete_partial_txt_on_interrupt "$current_txt_file"; then
        local txt_size
        txt_size="$(file_size_bytes "$current_txt_file")"
        rm -f -- "$current_txt_file"
        if [[ -n "$txt_removed_msg" ]]; then
            txt_removed_msg+=$'\n'"REMOVED PARTIAL TRANSCRIPT: $current_txt_file (${txt_size} bytes)"
        else
            txt_removed_msg="REMOVED PARTIAL TRANSCRIPT: $current_txt_file (${txt_size} bytes)"
        fi
        current_txt_file=""
    fi

    if [[ "$current_renamed" == "yes" ]]; then
        if [[ -n "$current_out" && -e "$current_out" ]]; then
            rm -f -- "$current_out"
            removed_msg="REMOVED: $current_out"
        fi

        if [[ -n "$current_new_in" && -e "$current_new_in" && -n "$current_original_in" && ! -e "$current_original_in" ]]; then
            mv -f -- "$current_new_in" "$current_original_in"
            restored_msg="RESTORED: $current_new_in $ARROW $current_original_in"
        fi
    fi

    echo
    print_restore_block "$removed_msg" "$restored_msg" "$txt_removed_msg"

    echo
    echo "Aborted by Ctrl-C."
    exit 130
}

trap cleanup_current_file INT

process_one_file() {
    local original_in="$1"
    local new_in="$2"
    local out="$3"
    local sha_file

    check_free_space_or_exit "."

    sha_file="$(sha_file_from_pair "$new_in")"
    voice_mark_pair_active "$new_in" "$out" "$sha_file"

    if [[ -e "$out" ]]; then
        echo
        echo -e "${YELLOW}SKIP:${RESET} Output already exists: $out"
        if [[ -e "$new_in" ]]; then
            queue_or_print_missing_transcriptions "$new_in" "$out" "$sha_file"
        fi
        ((++files_skipped))
        return 0
    fi

    if [[ -e "$new_in" || -e "$out" || -e "$sha_file" ]]; then
        echo
        echo -e "${YELLOW}SKIP:${RESET} Target exists: '$new_in' or '$out' or '$sha_file'"
        ((++files_skipped))
        return 0
    fi

    echo
    print_file_block "$original_in" "$new_in" "$out"

    current_original_in="$original_in"
    current_new_in="$new_in"
    current_out="$out"
    current_renamed=no

    mv -i -- "$original_in" "$new_in"
    current_renamed=yes

    voice_processing_begin
    ffmpeg -hide_banner -y -i "$new_in" \
        -map 0:a:0 -vn \
        -af "silenceremove=start_periods=1:start_silence=0.9:start_threshold=-50dB:stop_periods=-1:stop_silence=0.8:stop_threshold=-45dB,highpass=f=80,acompressor=threshold=-18dB:ratio=3:attack=20:release=250:makeup=4,dynaudnorm=f=150:g=11" \
        -c:a flac -compression_level 12 \
        "$out"

    touch -r "$new_in" "$out"

    echo
    print_sha_block "$sha_file" "$new_in" "$out"
    create_sha512_pair_file "$sha_file" "$new_in" "$out"
    voice_processing_end

    record_change "$original_in" "$new_in" "$out"
    ((++files_affected))
    ((++stats_new_files_processed))

    current_original_in=""
    current_new_in=""
    current_out=""
    current_renamed=no
    current_txt_file=""
    transcription_in_flight=no
    current_transcription_write_path=""
    current_transcription_target_path=""
}

# Skip prompts when there is nothing this run would do for the pair.
existing_pair_is_complete_for_batch() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    [[ -e "$org_file" && -e "$out_file" ]] || return 1

    # Transcription/re-do disabled: ORG+OUTPUT on disk is enough (no batch prompts).
    [[ "$DO_TRANSCRIPTION" != "yes" ]] && return 0

    transcript_all_variants_exist_for_audio "$org_file" || return 1
    transcript_all_variants_exist_for_audio "$out_file" || return 1
    return 0
}

print_existing_pair_legacy_hint() {
    local org_file="$1"
    local out_file="$2"
    local -a legacy=()

    mapfile -t legacy < <(pair_list_legacy_transcript_files "$org_file" "$out_file")
    (( ${#legacy[@]} == 0 )) && return 0

    if (( ${#legacy[@]} == 1 )); then
        print_suggestion "The legacy transcript file above will be deleted if you include this pair."
    else
        print_suggestion "The ${#legacy[@]} legacy transcript files above will be deleted if you include this pair."
    fi
}

process_existing_pairs_batch_selections() {
    local -n _orgs=$1
    local -n _outs=$2
    local -n _shas=$3
    local -n _selected=$4
    local i selected_total=0 selected_pos=0 selected_left_after=0

    (( ${#_orgs[@]} == 0 )) && return 0

    for decision in "${_selected[@]}"; do
        [[ "$decision" == "yes" ]] && ((selected_total+=1))
    done
    (( selected_total == 0 )) && return 0

    echo
    print_suggestion "EXISTING PAIRS BATCH: processing ${selected_total} selected pair(s) from this batch (transcription / sha512)..."

    for i in "${!_orgs[@]}"; do
        [[ "${_selected[$i]:-}" == "yes" ]] || continue
        ((selected_pos+=1))
        selected_left_after=$(( selected_total - selected_pos ))
        voice_mark_pair_active "${_orgs[$i]}" "${_outs[$i]}" "${_shas[$i]}"
        echo
        print_processing_progress "$selected_pos" "$selected_total" "$selected_left_after" "${#_orgs[@]}"
        prepare_selected_existing_pair "${_orgs[$i]}" "${_outs[$i]}" "${_shas[$i]}"
    done
}

print_existing_pair_ok_line() {
    local org_file="$1"
    local out_file="$2"

    echo -e "  ${GREEN}OK:${RESET} $(basename "$org_file") + $(basename "$out_file") — media and all transcript variants on disk"
}

print_existing_pairs_skip_section() {
    local -n _skip_orgs=$1
    local -n _skip_outs=$2
    local -n _skip_shas=$3
    local i

    (( ${#_skip_orgs[@]} == 0 )) && return 0

    echo
    print_suggestion "EXISTING PAIRS — complete on disk; skipped without prompt (${#_skip_orgs[@]}):"
    for i in "${!_skip_orgs[@]}"; do
        print_existing_pair_ok_line "${_skip_orgs[$i]}" "${_skip_outs[$i]}"
    done
}

process_existing_pairs_batch() {
    local total_files idx remaining_total batch_size_now batch_count batch_yes batch_no
    local accept_all_remaining finish_batch_now overall_pos batch_pos still_after_this
    local org_file out_file sha_file i selected_total selected_pos selected_left_after
    local incomplete_summary
    local -a prompt_orgs=() prompt_outs=() prompt_shas=()
    local -a skip_orgs=() skip_outs=() skip_shas=()
    local skip_count=0

    (( ${#existing_pair_orgs[@]} == 0 )) && return 0

    if [[ "$DO_TRANSCRIPTION" != "yes" ]]; then
        echo
        print_suggestion "EXISTING PAIRS: transcription is disabled — ${#existing_pair_orgs[@]} ORG/OUTPUT pair(s) left as-is (no batch prompts)."
        return 0
    fi

    for i in "${!existing_pair_orgs[@]}"; do
        org_file="${existing_pair_orgs[$i]}"
        out_file="${existing_pair_outs[$i]}"
        sha_file="${existing_pair_shas[$i]}"

        if existing_pair_is_complete_for_batch "$org_file" "$out_file" "$sha_file"; then
            skip_orgs+=("$org_file")
            skip_outs+=("$out_file")
            skip_shas+=("$sha_file")
            ((++skip_count))
        else
            prompt_orgs+=("$org_file")
            prompt_outs+=("$out_file")
            prompt_shas+=("$sha_file")
        fi
    done

    if (( skip_count > 0 )); then
        (( files_skipped += skip_count ))
        print_existing_pairs_skip_section skip_orgs skip_outs skip_shas
    fi

    total_files=${#prompt_orgs[@]}
    (( total_files == 0 )) && return 0

    idx=0

    echo
    if (( skip_count > 0 )); then
        print_suggestion "EXISTING PAIRS BATCH: ${total_files} pair(s) still need work or your choice (${skip_count} already complete on disk, skipped above)."
    else
        print_suggestion "EXISTING PAIRS BATCH: ${total_files} ORG/OUTPUT pair(s) — choose which to include for transcription/re-do."
    fi

    while (( idx < total_files )); do
        [[ "$skip_remaining_existing_pair_prompts" == yes ]] && break

        declare -a batch_orgs=()
        declare -a batch_outs=()
        declare -a batch_shas=()
        declare -a batch_selected=()

        remaining_total=$(( total_files - idx ))
        batch_size_now=$BATCH_SIZE
        (( remaining_total < batch_size_now )) && batch_size_now=$remaining_total

        batch_count=0
        batch_yes=0
        batch_no=0
        accept_all_remaining=no
        finish_batch_now=no

        while (( idx < total_files && batch_count < batch_size_now )); do
            org_file="${prompt_orgs[$idx]}"
            out_file="${prompt_outs[$idx]}"
            sha_file="${prompt_shas[$idx]}"

            if [[ "$accept_all_remaining" == "yes" ]]; then
                batch_selected+=("yes")
                ((++batch_yes))
                batch_orgs+=("$org_file")
                batch_outs+=("$out_file")
                batch_shas+=("$sha_file")
                ((idx+=1))
                ((batch_count+=1))
                continue
            fi

            overall_pos=$(( idx + 1 ))
            batch_pos=$(( batch_count + 1 ))
            still_after_this=$(( total_files - overall_pos ))

            echo
            print_prompt_and_decision_summary \
                "$batch_pos" "$batch_size_now" "$overall_pos" "$total_files" "$still_after_this" \
                "$batch_yes" "$batch_no"
            print_transcription_pair_block "$org_file" "$out_file" "$sha_file"
            print_existing_pair_legacy_hint "$org_file" "$out_file"
            read_batch_choice "Include this existing ORG/OUTPUT pair (transcribe missing variants / re-do if needed)?"

            case "$BATCH_CHOICE_ACTION" in
                quit)
                    voice_quit
                    ;;
                finish_batch)
                    finish_batch_now=yes
                    echo "Finishing existing-pairs batch — ${batch_yes} pair(s) selected for this run."
                    break
                    ;;
                skip_all)
                    skip_remaining_existing_pair_prompts=yes
                    finish_batch_now=yes
                    echo "Skipping further existing-pair prompts — ${batch_yes} pair(s) selected for this run."
                    break
                    ;;
                accept_all)
                    batch_selected+=("yes")
                    ((++batch_yes))
                    accept_all_remaining=yes
                    batch_orgs+=("$org_file")
                    batch_outs+=("$out_file")
                    batch_shas+=("$sha_file")
                    ((idx+=1))
                    ((batch_count+=1))
                    continue
                    ;;
                decided)
                    if [[ "$BATCH_CHOICE_DECISION" == yes ]]; then
                        batch_selected+=("yes")
                        ((++batch_yes))
                    else
                        batch_selected+=("no")
                        ((++batch_no))
                    fi
                    ;;
            esac

            batch_orgs+=("$org_file")
            batch_outs+=("$out_file")
            batch_shas+=("$sha_file")

            ((idx+=1))
            ((batch_count+=1))
        done

        process_existing_pairs_batch_selections batch_orgs batch_outs batch_shas batch_selected

        if [[ "$finish_batch_now" == yes ]]; then
            idx=$(batch_prompt_finish_skip_idx "$idx" "$batch_size_now" "$batch_count")
        fi

        [[ "$skip_remaining_existing_pair_prompts" == yes ]] && break
        [[ "$finish_batch_now" == yes ]] && break
    done
}

process_exclude_sha_only() {
    local excluded_file="$1"
    local sha_file

    sha_file="$(sha_file_from_single "$excluded_file")"

    if [[ -e "$sha_file" ]]; then
        return 0
    fi

    if [[ "$mode" == "dry-run" ]]; then
        echo
        print_sha_block "$sha_file" "$excluded_file"
        echo "sha512sum -- \"$excluded_file\" > \"$sha_file\""
        echo "sha512sum -c --quiet -- \"$sha_file\""
        echo "----------------------------------------"
        ((++files_affected))
        return 0
    fi

    check_free_space_or_exit "."

    echo
    print_sha_block "$sha_file" "$excluded_file"
    voice_processing_begin
    create_sha512_single_file "$sha_file" "$excluded_file"
    voice_processing_end

    ((++files_affected))
    ((++stats_sha_backfilled))
}

# ============================================================
# BUILD FILE LIST + DETECT EXISTING PAIRS / EXCLUDES
# ============================================================
declare -a discovered_files=()

if [[ -n "$TARGET_FILE" ]]; then
    if [[ ! -e "$TARGET_FILE" ]]; then
        echo "File not found: $TARGET_FILE" >&2
        exit 1
    fi
    if [[ ! -f "$TARGET_FILE" ]]; then
        echo "Not a regular file: $TARGET_FILE" >&2
        exit 1
    fi
    if ! is_supported_audio "$TARGET_FILE"; then
        echo "Unsupported audio type: $TARGET_FILE" >&2
        echo "Supported: .wav .mp3 .m4a .flac .ogg .opus .aac .mp4" >&2
        exit 1
    fi
    discovered_files+=("$TARGET_FILE")
else
    for f in *.wav *.mp3 *.m4a *.flac *.ogg *.opus *.aac *.mp4; do
        [[ -e "$f" ]] || continue
        discovered_files+=("$f")
    done
fi

if (( ${#discovered_files[@]} > 0 )); then
    mapfile -t all_files < <(printf '%s\n' "${discovered_files[@]}" | LC_ALL=C sort)
fi

declare -A seen_pair_stems=()
declare -a filtered_files=()

for f in "${all_files[@]}"; do
    ((++files_examined))

    if [[ "$f" == *_EXCLUDE.* ]]; then
        exclude_files+=("$f")
        ((++files_skipped))
        continue
    fi

    if [[ "$f" == *_ORG.* ]]; then
        stem="${f%.*}"
        stem="${stem%_ORG}"
        out="${stem}_OUTPUT.flac"
        sha="${stem}.sha512"

        if [[ -e "$out" && -z "${seen_pair_stems[$stem]+x}" ]]; then
            existing_pair_orgs+=("$f")
            existing_pair_outs+=("$out")
            existing_pair_shas+=("$sha")
            seen_pair_stems["$stem"]=1
        fi

        ((++files_skipped))
        continue
    fi

    if [[ "$f" == *_OUTPUT.flac ]]; then
        ((++files_skipped))
        continue
    fi

    filtered_files+=("$f")
done

all_files=("${filtered_files[@]}")

# ============================================================
# HANDLE *_EXCLUDE.* SHA512 FILES
# ============================================================
if (( ${#exclude_files[@]} > 0 )); then
    for excluded_file in "${exclude_files[@]}"; do
        process_exclude_sha_only "$excluded_file"
    done
fi

# ============================================================
# DRY-RUN
# ============================================================
if [[ "$mode" == "dry-run" ]]; then
    for original_in in "${all_files[@]}"; do
        new_in="${original_in%.*}_ORG.${original_in##*.}"
        base="${new_in%.*}"
        base="${base%_ORG}"
        out="${base}_OUTPUT.flac"
        sha_file="$(sha_file_from_pair "$new_in")"
        if [[ -e "$out" ]]; then
            echo
            echo -e "${YELLOW}SKIP:${RESET} Output already exists: $out"
            ((++files_skipped))
            continue
        fi

        echo
        print_file_block "$original_in" "$new_in" "$out"
        echo "ffmpeg -hide_banner -y -i \"$new_in\" -map 0:a:0 -vn -af \"silenceremove=start_periods=1:start_silence=0.9:start_threshold=-50dB:stop_periods=-1:stop_silence=0.8:stop_threshold=-45dB,highpass=f=80,acompressor=threshold=-18dB:ratio=3:attack=20:release=250:makeup=4,dynaudnorm=f=150:g=11\" -c:a flac -compression_level 12 \"$out\""
        echo "touch -r \"$new_in\" \"$out\""
        print_sha_block "$sha_file" "$new_in" "$out"
        echo "sha512sum -- \"$new_in\" \"$out\" > \"$sha_file\""
        echo "sha512sum -c --quiet -- \"$sha_file\""
        if [[ "$DO_TRANSCRIPTION" == "yes" ]]; then
            print_transcription_dry_run_steps "$new_in" "$out" "$sha_file"
        fi
        echo "----------------------------------------"

        ((++files_affected))
        record_change "$original_in" "$new_in" "$out"
    done
else
    total_files=${#all_files[@]}
    idx=0

    while (( idx < total_files )); do
        [[ "$skip_remaining_file_prompts" == yes ]] && break

        declare -a batch_originals=()
        declare -a batch_newins=()
        declare -a batch_outputs=()
        declare -a batch_selected=()

        remaining_total=$(( total_files - idx ))
        batch_size_now=$BATCH_SIZE
        (( remaining_total < batch_size_now )) && batch_size_now=$remaining_total

        batch_count=0
        batch_yes=0
        batch_no=0
        accept_all_remaining=no
        finish_batch_now=no

        while (( idx < total_files && batch_count < batch_size_now )); do
            original_in="${all_files[$idx]}"
            new_in="${original_in%.*}_ORG.${original_in##*.}"
            base="${new_in%.*}"
            base="${base%_ORG}"
            out="${base}_OUTPUT.flac"

            if [[ "$accept_all_remaining" == "yes" ]]; then
                batch_selected+=("yes")
                ((++batch_yes))
                batch_originals+=("$original_in")
                batch_newins+=("$new_in")
                batch_outputs+=("$out")
                ((idx+=1))
                ((batch_count+=1))
                continue
            fi

            overall_pos=$(( idx + 1 ))
            batch_pos=$(( batch_count + 1 ))
            still_after_this=$(( total_files - overall_pos ))

            echo
            print_prompt_and_decision_summary \
                "$batch_pos" "$batch_size_now" "$overall_pos" "$total_files" "$still_after_this" \
                "$batch_yes" "$batch_no"
            print_file_block "$original_in" "$new_in" "$out"
            read_batch_choice "Process this file later in this batch?"

            case "$BATCH_CHOICE_ACTION" in
                quit)
                    voice_quit
                    ;;
                finish_batch)
                    finish_batch_now=yes
                    echo "Finishing this batch — processing ${batch_yes} selected file(s) only."
                    break
                    ;;
                skip_all)
                    skip_remaining_file_prompts=yes
                    finish_batch_now=yes
                    echo "Skipping all further file prompts — processing ${batch_yes} selected file(s) from this batch."
                    break
                    ;;
                accept_all)
                    batch_selected+=("yes")
                    ((++batch_yes))
                    accept_all_remaining=yes
                    voice_mark_pair_active "$new_in" "$out" "$(sha_file_from_pair "$new_in")"
                    batch_originals+=("$original_in")
                    batch_newins+=("$new_in")
                    batch_outputs+=("$out")
                    ((idx+=1))
                    ((batch_count+=1))
                    continue
                    ;;
                decided)
                    if [[ "$BATCH_CHOICE_DECISION" == yes ]]; then
                        batch_selected+=("yes")
                        ((++batch_yes))
                        voice_mark_pair_active "$new_in" "$out" "$(sha_file_from_pair "$new_in")"
                    else
                        batch_selected+=("no")
                        ((++files_skipped))
                        ((++batch_no))
                    fi
                    ;;
            esac

            batch_originals+=("$original_in")
            batch_newins+=("$new_in")
            batch_outputs+=("$out")

            ((idx+=1))
            ((batch_count+=1))
        done

        if (( ${#batch_originals[@]} > 0 )); then
            selected_total=0
            for decision in "${batch_selected[@]}"; do
                [[ "$decision" == "yes" ]] && ((selected_total+=1))
            done

            if (( selected_total > 0 )); then
                selected_pos=0
                for i in "${!batch_originals[@]}"; do
                    if [[ "${batch_selected[$i]}" == "yes" ]]; then
                        ((selected_pos+=1))
                        selected_left_after=$(( selected_total - selected_pos ))
                        echo
                        print_processing_progress "$selected_pos" "$selected_total" "$selected_left_after" "$total_files"
                        process_one_file "${batch_originals[$i]}" "${batch_newins[$i]}" "${batch_outputs[$i]}"
                    fi
                done
            elif (( finish_batch_now )); then
                echo "No files selected in this batch."
            fi
        fi

        if [[ "$finish_batch_now" == yes ]]; then
            idx=$(batch_prompt_finish_skip_idx "$idx" "$batch_size_now" "$batch_count")
        fi

        if [[ "$skip_remaining_file_prompts" == yes ]]; then
            (( files_skipped += total_files - idx ))
            break
        fi
        [[ "$finish_batch_now" == yes ]] && break
    done

    if (( ${#existing_pair_orgs[@]} > 0 && ${#all_files[@]} == 0 )); then
        process_existing_pairs_batch
    fi
fi

if [[ "$mode" == "real" && "$DO_TRANSCRIPTION" == "yes" ]]; then
    process_transcription_queue
elif [[ "$mode" == "real" ]] && (( ${#voice_active_orgs[@]} > 0 )); then
    print_suggestion "Pairs were selected but transcription is disabled — no transcription/re-do prompts."
fi
