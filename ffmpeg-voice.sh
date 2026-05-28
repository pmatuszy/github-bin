#!/usr/bin/env bash
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
  -h, --help    Show this help and exit.
  -- FILE       Explicit file operand (use when the name starts with -).

Transcription (when enabled):
  Each *_ORG.* and *_OUTPUT.flac gets two transcripts: *_VAD.txt (whisper with VAD)
  and *_noVAD.txt (whisper without VAD), e.g. stem_ORG_VAD.txt and stem_OUTPUT_noVAD.txt.
  Loop detection may rename to *_POSSIBLE_LOOP.txt.

Whisper servers (defaults below; override with environment variables):
  WHISPER_VAD_HOST / WHISPER_VAD_PORT       Server with VAD (default port 8080).
  WHISPER_NOVAD_HOST / WHISPER_NOVAD_PORT   Server without VAD (default port 8081).

Other environment variables:
  TRANSCRIBE_CMD          Full path to transcribe-server.sh (skips mount lookup).
  TRANSCRIBE_SCRIPT_REL   Relative path under mount (default: whisper.cpp/transcribe-server.sh).
  Legacy: TRANSCRIBE_HOST and TRANSCRIBE_PORT apply to the VAD server only if
          WHISPER_VAD_HOST / WHISPER_VAD_PORT are unset.
EOF
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

parse_cli_args "$@"

# ============================================================
# DEFAULT SETTINGS
# ============================================================
BATCH_SIZE=50
MIN_FREE_KB=1048576   # 1 GiB
DO_TRANSCRIPTION=yes
TRANSCRIBE_SCRIPT_REL="${TRANSCRIBE_SCRIPT_REL:-whisper.cpp/transcribe-server.sh}"
TRANSCRIBE_CMD="${TRANSCRIBE_CMD:-}"
# Whisper servers — edit here or set WHISPER_VAD_* / WHISPER_NOVAD_* in the environment.
WHISPER_VAD_HOST="${WHISPER_VAD_HOST:-${TRANSCRIBE_HOST:-192.168.200.134}}"
WHISPER_VAD_PORT="${WHISPER_VAD_PORT:-${TRANSCRIBE_PORT:-8080}}"
WHISPER_NOVAD_HOST="${WHISPER_NOVAD_HOST:-192.168.200.134}"
WHISPER_NOVAD_PORT="${WHISPER_NOVAD_PORT:-8081}"
TRANSCRIPT_VAD_SUFFIX="VAD"
TRANSCRIPT_NOVAD_SUFFIX="noVAD"
declare -a TRANSCRIPT_VARIANT_SUFFIXES=("$TRANSCRIPT_VAD_SUFFIX" "$TRANSCRIPT_NOVAD_SUFFIX")
PARTIAL_TXT_DELETE_MAX_BYTES=127
TRANSCRIPT_LOOP_MARKER="_POSSIBLE_LOOP"

# ============================================================
# COLOR SELECTION
# ============================================================
echo
echo "Use colors?"
echo "  [Y] Yes (default)"
echo "  [N] No"
echo "  [Q] Quit"
echo -n "Choice [Y/n/q]: "

use_colors=yes
input=""

read -t 60 -n 1 input || true
echo

if [[ "$input" =~ [Qq] ]]; then
    echo "Quitting."
    exit 0
elif [[ "$input" =~ [Nn] ]]; then
    use_colors=no
fi

if [[ "$use_colors" == "yes" ]]; then
    RED='\e[31m'
    GREEN='\e[32m'
    CYAN='\e[36m'
    YELLOW='\e[33m'
    RESET='\e[0m'
else
    RED=''
    GREEN=''
    CYAN=''
    YELLOW=''
    RESET=''
fi

ARROW="→"

# ============================================================
# MODE SELECTION
# ============================================================
echo
echo "Select mode:"
echo "  [D] Dry-run (default)"
echo "  [R] Real processing (interactive)"
echo "  [Q] Quit"
echo -n "Choice [D/r/q]: "

mode="dry-run"
input=""

read -t 60 -n 1 input || true
echo

if [[ "$input" =~ [Qq] ]]; then
    echo "Quitting."
    exit 0
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
    echo "Enable transcription (ORG/OUTPUT x VAD/noVAD whisper servers)?"
    echo "  [Y] Yes (default)"
    echo "  [N] No"
    echo "  [Q] Quit"
    echo -n "Choice [Y/n/q]: "
else
    echo "Include transcription step in dry-run (ORG/OUTPUT x VAD/noVAD)?"
    echo "  [Y] Yes (default)"
    echo "  [N] No"
    echo "  [Q] Quit"
    echo -n "Choice [Y/n/q]: "
fi

input=""
read -t 60 -n 1 input || true
echo

if [[ "$input" =~ [Qq] ]]; then
    echo "Quitting."
    exit 0
elif [[ "$input" =~ [Nn] ]]; then
    DO_TRANSCRIPTION=no
fi

echo -e "Transcription enabled: ${CYAN}$DO_TRANSCRIPTION${RESET}"

# ============================================================
# BATCH SIZE - ONLY FOR REAL MODE
# ============================================================
if [[ "$mode" == "real" ]]; then
    echo
    echo "Batch size for asking before processing?"
    echo "  Default: 50"
    echo "  Enter a positive number, or press Enter for default."
    echo -n "Batch size [50]: "

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

# <mount>/whisper.cpp/transcribe-server.sh on the filesystem holding cwd (or TRANSCRIBE_CMD if preset).
init_transcribe_cmd() {
    local base_path="${1:-.}"
    local mount_point=""

    if [[ -n "$TRANSCRIBE_CMD" ]]; then
        return 0
    fi

    mount_point="$(filesystem_mount_for_path "$base_path")" || return 1
    TRANSCRIBE_CMD="${mount_point}/${TRANSCRIBE_SCRIPT_REL}"
}

if [[ "$DO_TRANSCRIPTION" == "yes" ]]; then
    if init_transcribe_cmd "."; then
        echo
        echo -e "Transcribe command:  ${CYAN}$TRANSCRIBE_CMD${RESET}"
        echo -e "Whisper VAD:         ${CYAN}${WHISPER_VAD_HOST}:${WHISPER_VAD_PORT}${RESET}"
        echo -e "Whisper noVAD:       ${CYAN}${WHISPER_NOVAD_HOST}:${WHISPER_NOVAD_PORT}${RESET}"
    else
        echo
        echo -e "${YELLOW}Warning:${RESET} could not resolve mount point for transcribe-server.sh (cwd: $PWD)"
    fi
fi

sleep 1

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
        [[ -n "$removed_msg" ]] && echo -e "${YELLOW}${removed_msg}${RESET}"
        [[ -n "$restored_msg" ]] && echo -e "${YELLOW}${restored_msg}${RESET}"
        [[ -n "$txt_removed_msg" ]] && echo -e "${YELLOW}${txt_removed_msg}${RESET}"
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

print_transcription_pair_block() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"
    local tag variant_path

    if [[ "$have_boxes" == "yes" ]]; then
        {
            printf "ORG AUDIO:    %s\n" "$org_file"
            for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
                variant_path="$(transcript_variant_path_for_audio "$org_file" "$tag")"
                printf "ORG TRANSCRIPT (%s): %s\n" "$tag" "$variant_path"
            done
            printf "OUTPUT AUDIO: %s\n" "$out_file"
            for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
                variant_path="$(transcript_variant_path_for_audio "$out_file" "$tag")"
                printf "OUTPUT TRANSCRIPT (%s): %s\n" "$tag" "$variant_path"
            done
            printf "SHA512 FILE:  %s\n" "$sha_file"
        } | boxes -d stone
    else
        echo -e "${CYAN}ORG AUDIO:${RESET}     $org_file"
        for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
            variant_path="$(transcript_variant_path_for_audio "$org_file" "$tag")"
            echo -e "${CYAN}ORG TRANSCRIPT (${tag}):${RESET} $variant_path"
        done
        echo -e "${CYAN}OUTPUT AUDIO:${RESET}  $out_file"
        for tag in "${TRANSCRIPT_VARIANT_SUFFIXES[@]}"; do
            variant_path="$(transcript_variant_path_for_audio "$out_file" "$tag")"
            echo -e "${CYAN}OUTPUT TRANSCRIPT (${tag}):${RESET} $variant_path"
        done
        echo -e "${CYAN}SHA512 FILE:${RESET}   $sha_file"
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

check_transcribe_endpoint_or_exit() {
    local host="$1"
    local port="$2"
    local label="${3:-whisper}"

    if ! ping -c 1 -W 1 "$host" >/dev/null 2>&1; then
        echo
        echo -e "${YELLOW}TRANSCRIPTION UNAVAILABLE:${RESET} host not reachable (ping): $host (${label})"
        echo "Cannot continue because transcription cannot be done."
        exit 1
    fi

    if ! transcribe_host_port_open "$host" "$port"; then
        echo
        echo -e "${YELLOW}TRANSCRIPTION UNAVAILABLE:${RESET} port ${port} not open on ${host} (${label})"
        echo "Cannot continue because transcription cannot be done."
        exit 1
    fi
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
        check_transcribe_endpoint_or_exit "$host" "$port" "${tag} @ ${endpoint_key}"
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

verify_sha512_file() {
    local sha_file="$1"
    sha512sum -c --quiet -- "$sha_file"
}

# Path transcribe-server writes before rename (…_ORG.txt / …_OUTPUT.txt).
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
            echo -e "${CYAN}TRANSCRIPTION:${RESET} Missing transcript: $variant_txt"
        fi
    done
}

migrate_legacy_transcript_to_vad_variant() {
    local audio_file="$1"
    local base vad_txt

    base="$(txt_file_for_audio "$audio_file")"
    vad_txt="$(transcript_variant_path_for_audio "$audio_file" "$TRANSCRIPT_VAD_SUFFIX")"
    [[ -e "$base" && ! -e "$vad_txt" ]] || return 0
    [[ "$mode" == "dry-run" ]] && return 0
    mv -f -- "$base" "$vad_txt"
    echo -e "${CYAN}TRANSCRIPTION:${RESET} Migrated legacy transcript $base $ARROW $vad_txt"
}

transcript_has_repetition_loop() {
    local txt_file="$1"

    [[ -e "$txt_file" ]] || return 1

    awk '
    /^\[/ {
        t = $0
        sub(/^\[[^]]*\][[:space:]]*/, "", t)
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", t)
        if (t == "") next
        if (t == prev) {
            rep++
            if (rep >= 2) { found = 1; exit }
        } else {
            rep = 1
        }
        prev = t
    }
    END { exit(found ? 0 : 1 }
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
        echo -e "${YELLOW}POSSIBLE LOOP:${RESET} would rename: $txt_file $ARROW $loop_txt"
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
        migrate_legacy_transcript_to_vad_variant "$audio_file"
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
            echo "TRANSCRIBE_HOST=$host TRANSCRIBE_PORT=$port \"$TRANSCRIBE_CMD\" \"$audio_file\""
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

    migrate_legacy_transcript_to_vad_variant "$audio_file"
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

    ensure_pair_sha_file "$org_file" "$out_file" "$sha_file" || return 1
    append_transcript_variant_hashes_for_audio "$org_file" "$sha_file"
    append_transcript_variant_hashes_for_audio "$out_file" "$sha_file"
    check_transcript_loops_for_pair "$org_file" "$out_file" "$sha_file"
    append_transcript_variant_hashes_for_audio "$org_file" "$sha_file"
    append_transcript_variant_hashes_for_audio "$out_file" "$sha_file"
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

run_one_transcription_variant() {
    local audio_file="$1"
    local sha_file="$2"
    local variant_suffix="$3"
    local whisper_host="$4"
    local whisper_port="$5"
    local server_base variant_txt resolved_txt

    migrate_legacy_transcript_to_vad_variant "$audio_file"

    if transcript_variant_exists_for_audio "$audio_file" "$variant_suffix"; then
        variant_txt="$(transcript_variant_path_for_audio "$audio_file" "$variant_suffix")"
        [[ -e "$variant_txt" ]] && flag_transcript_loop_if_needed "$variant_txt" "$sha_file"
        resolved_txt="$(transcript_variant_resolved_path "$variant_txt")"
        append_sha512_for_file_if_missing "$sha_file" "$resolved_txt"
        return 0
    fi

    if [[ ! -x "$TRANSCRIBE_CMD" ]]; then
        echo -e "${YELLOW}TRANSCRIPTION SKIPPED:${RESET} command not found or not executable: $TRANSCRIBE_CMD"
        return 0
    fi

    check_transcribe_endpoint_or_exit "$whisper_host" "$whisper_port" "${variant_suffix}"
    check_free_space_or_exit "."

    server_base="$(txt_file_for_audio "$audio_file")"
    variant_txt="$(transcript_variant_path_for_audio "$audio_file" "$variant_suffix")"
    current_txt_file="$variant_txt"

    echo -e "${CYAN}TRANSCRIBE (${variant_suffix}):${RESET} ${whisper_host}:${whisper_port} $ARROW $variant_txt"

    TRANSCRIBE_HOST="$whisper_host" TRANSCRIBE_PORT="$whisper_port" \
        "$TRANSCRIBE_CMD" "$audio_file"

    if [[ ! -e "$server_base" ]]; then
        echo -e "${YELLOW}TRANSCRIPTION FAILED:${RESET} expected transcript not found: $server_base"
        exit 1
    fi

    if [[ "$server_base" != "$variant_txt" ]]; then
        mv -f -- "$server_base" "$variant_txt"
    fi

    flag_transcript_loop_if_needed "$variant_txt" "$sha_file"
    resolved_txt="$(transcript_variant_resolved_path "$variant_txt")"
    append_sha512_for_file_if_missing "$sha_file" "$resolved_txt"
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

verify_pair_sha_or_exit() {
    local sha_file="$1"

    [[ -e "$sha_file" ]] || return 0

    if verify_sha512_file "$sha_file"; then
        echo -e "${CYAN}SHA512 VERIFIED:${RESET} $sha_file"
    else
        echo -e "${YELLOW}SHA512 VERIFY FAILED:${RESET} $sha_file"
        exit 1
    fi
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
        if (( need_org || need_out )); then
            if transcript_any_variant_exists_for_audio "$org_file" && need_out -eq 1; then
                echo -e "${CYAN}TRANSCRIPTION:${RESET} Partial ORG transcripts; still need OUTPUT variants:"
                print_missing_transcript_variants_for_audio "$out_file"
            elif transcript_any_variant_exists_for_audio "$out_file" && need_org -eq 1; then
                echo -e "${CYAN}TRANSCRIPTION:${RESET} Partial OUTPUT transcripts; still need ORG variants:"
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
            echo -e "${CYAN}TRANSCRIPTION:${RESET} All transcript variants present; sync sha512 if needed"
            if [[ ! -e "$sha_file" ]]; then
                echo "sha512sum -- \"$org_file\" \"$out_file\" > \"$sha_file\""
            fi
            print_transcription_dry_run_steps "$org_file" "$out_file" "$sha_file"
        fi
        echo "----------------------------------------"
        return 0
    fi

    ensure_pair_sha_file "$org_file" "$out_file" "$sha_file"
    sync_existing_transcript_hashes "$org_file" "$out_file" "$sha_file"

    if (( ! need_org && ! need_out )); then
        verify_pair_sha_or_exit "$sha_file"
        return 0
    fi

    if transcript_any_variant_exists_for_audio "$org_file" && need_out -eq 1; then
        echo -e "${CYAN}TRANSCRIPTION:${RESET} Partial ORG transcripts; still need OUTPUT variants:"
        print_missing_transcript_variants_for_audio "$out_file"
    elif transcript_any_variant_exists_for_audio "$out_file" && need_org -eq 1; then
        echo -e "${CYAN}TRANSCRIPTION:${RESET} Partial OUTPUT transcripts; still need ORG variants:"
        print_missing_transcript_variants_for_audio "$org_file"
    else
        print_missing_transcript_variants_for_audio "$org_file"
        print_missing_transcript_variants_for_audio "$out_file"
    fi

    transcribe_queue_orgs+=("$org_file")
    transcribe_queue_outs+=("$out_file")
    transcribe_queue_shas+=("$sha_file")
}

run_transcriptions_for_pair() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    ensure_pair_sha_file "$org_file" "$out_file" "$sha_file"
    check_transcribe_hosts_or_exit
    sync_existing_transcript_hashes "$org_file" "$out_file" "$sha_file"

    run_all_transcriptions_for_audio "$org_file" "$sha_file"
    run_all_transcriptions_for_audio "$out_file" "$sha_file"

    check_transcript_loops_for_pair "$org_file" "$out_file" "$sha_file"
    sync_existing_transcript_hashes "$org_file" "$out_file" "$sha_file"
    verify_pair_sha_or_exit "$sha_file"
}

process_transcription_queue() {
    [[ "$DO_TRANSCRIPTION" == "yes" ]] || return 0
    [[ "$mode" == "real" ]] || return 0

    local total_files idx
    total_files=${#transcribe_queue_outs[@]}
    idx=0

    while (( idx < total_files )); do
        declare -a batch_orgs=()
        declare -a batch_outs=()
        declare -a batch_shas=()
        declare -a batch_selected=()

        local remaining_total batch_size_now batch_count batch_yes batch_no accept_all_remaining
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
            echo "Do transcription later in this batch?"
            echo "  [Y] Yes (default)"
            echo "  [N] No"
            echo "  [A] Yes for all remaining in this batch"
            echo "  [Q] Quit"
            echo -n "Choice [Y/n/a/q]: "
            read -t 300 -n 1 input || true
            echo

            case "$input" in
                q|Q)
                    stopped_by_user=yes
                    echo
                    echo "Quitting."
                    exit 0
                    ;;
                n|N)
                    batch_selected+=("no")
                    ((++files_skipped))
                    ((++batch_no))
                    ;;
                a|A)
                    batch_selected+=("yes")
                    ((++batch_yes))
                    accept_all_remaining=yes
                    ;;
                *)
                    batch_selected+=("yes")
                    ((++batch_yes))
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
        fi
    done

    transcribe_queue_orgs=()
    transcribe_queue_outs=()
    transcribe_queue_shas=()
}

backfill_existing_pair_sha() {
    local org_file="$1"
    local out_file="$2"
    local sha_file="$3"

    if [[ -e "$sha_file" ]]; then
        queue_or_print_missing_transcriptions "$org_file" "$out_file" "$sha_file"
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
    create_sha512_pair_file "$sha_file" "$org_file" "$out_file"

    if verify_sha512_file "$sha_file"; then
        echo -e "${CYAN}SHA512 VERIFIED:${RESET} $sha_file"
    else
        echo -e "${YELLOW}SHA512 VERIFY FAILED:${RESET} $sha_file"
        exit 1
    fi

    queue_or_print_missing_transcriptions "$org_file" "$out_file" "$sha_file"

    ((++files_affected))
}

# ============================================================
# STATE
# ============================================================
files_examined=0
files_affected=0
files_skipped=0
stopped_by_user=no

declare -a affected_list=()
declare -a transcribe_queue_orgs=()
declare -a transcribe_queue_outs=()
declare -a transcribe_queue_shas=()

current_original_in=""
current_new_in=""
current_out=""
current_renamed=no
current_txt_file=""

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

    if [[ -n "$current_txt_file" ]] && should_delete_partial_txt_on_interrupt "$current_txt_file"; then
        local txt_size
        txt_size="$(file_size_bytes "$current_txt_file")"
        rm -f -- "$current_txt_file"
        txt_removed_msg="REMOVED PARTIAL TRANSCRIPT: $current_txt_file (${txt_size} bytes)"
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

    ffmpeg -hide_banner -y -i "$new_in" \
        -map 0:a:0 -vn \
        -af "silenceremove=start_periods=1:start_silence=0.9:start_threshold=-50dB:stop_periods=-1:stop_silence=0.8:stop_threshold=-45dB,highpass=f=80,acompressor=threshold=-18dB:ratio=3:attack=20:release=250:makeup=4,dynaudnorm=f=150:g=11" \
        -c:a flac -compression_level 12 \
        "$out"

    touch -r "$new_in" "$out"

    echo
    print_sha_block "$sha_file" "$new_in" "$out"
    create_sha512_pair_file "$sha_file" "$new_in" "$out"

    if verify_sha512_file "$sha_file"; then
        echo -e "${CYAN}SHA512 VERIFIED:${RESET} $sha_file"
    else
        echo -e "${YELLOW}SHA512 VERIFY FAILED:${RESET} $sha_file"
        exit 1
    fi

    queue_or_print_missing_transcriptions "$new_in" "$out" "$sha_file"

    record_change "$original_in" "$new_in" "$out"
    ((++files_affected))

    current_original_in=""
    current_new_in=""
    current_out=""
    current_renamed=no
    current_txt_file=""
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
    create_sha512_single_file "$sha_file" "$excluded_file"

    if verify_sha512_file "$sha_file"; then
        echo -e "${CYAN}SHA512 VERIFIED:${RESET} $sha_file"
    else
        echo -e "${YELLOW}SHA512 VERIFY FAILED:${RESET} $sha_file"
        exit 1
    fi

    ((++files_affected))
}

# ============================================================
# BUILD FILE LIST + DETECT EXISTING PAIRS / EXCLUDES
# ============================================================
declare -a discovered_files=()
declare -a all_files=()
declare -a exclude_files=()
declare -a existing_pair_orgs=()
declare -a existing_pair_outs=()
declare -a existing_pair_shas=()

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
# BACKFILL SHA512 FOR EXISTING _ORG + _OUTPUT PAIRS
# ============================================================
if (( ${#existing_pair_orgs[@]} > 0 )); then
    for i in "${!existing_pair_orgs[@]}"; do
        backfill_existing_pair_sha \
            "${existing_pair_orgs[$i]}" \
            "${existing_pair_outs[$i]}" \
            "${existing_pair_shas[$i]}"
    done
fi

if [[ "$mode" == "real" ]]; then
    process_transcription_queue
fi

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
            echo "Process this file later in this batch?"
            echo "  [Y] Yes (default)"
            echo "  [N] No"
            echo "  [A] Yes for all remaining in this batch"
            echo "  [Q] Quit"
            echo -n "Choice [Y/n/a/q]: "
            read -t 300 -n 1 input || true
            echo

            case "$input" in
                q|Q)
                    stopped_by_user=yes
                    echo
                    echo "Quitting."
                    exit 0
                    ;;
                n|N)
                    batch_selected+=("no")
                    ((++files_skipped))
                    ((++batch_no))
                    ;;
                a|A)
                    batch_selected+=("yes")
                    ((++batch_yes))
                    accept_all_remaining=yes
                    ;;
                *)
                    batch_selected+=("yes")
                    ((++batch_yes))
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
        fi

        process_transcription_queue
    done
fi

# ============================================================
# SUMMARY
# ============================================================
echo
if (( files_examined == 0 )); then
    echo "No matching input files found."
    echo
fi

echo "========= SUMMARY ========="
echo "Mode:                  $mode"
if [[ -n "$TARGET_FILE" ]]; then
    echo "Scope:                 single file ($TARGET_FILE)"
else
    echo "Scope:                 current directory"
fi
if [[ "$mode" == "real" ]]; then
    echo "Batch size:            $BATCH_SIZE"
fi
echo "Boxes available:       $have_boxes"
echo "Colors enabled:        $use_colors"
echo "Transcription enabled: $DO_TRANSCRIPTION"
if [[ "$DO_TRANSCRIPTION" == "yes" && -n "$TRANSCRIBE_CMD" ]]; then
    echo "Transcribe command:    $TRANSCRIBE_CMD"
fi
echo "Whisper VAD:           ${WHISPER_VAD_HOST}:${WHISPER_VAD_PORT}"
echo "Whisper noVAD:         ${WHISPER_NOVAD_HOST}:${WHISPER_NOVAD_PORT}"
echo "Files examined:        $files_examined"
echo "Files affected:        $files_affected"
echo "Files skipped:         $files_skipped"
echo "Stopped by user:       $stopped_by_user"

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
fi
echo "==========================="
