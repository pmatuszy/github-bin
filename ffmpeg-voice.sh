#!/usr/bin/env bash
# 2026.03.27 - v. 1.3 - side-by-side boxes for prompting summary, fewer empty lines

set -euo pipefail
shopt -s nullglob nocaseglob

# ============================================================
# DEFAULT SETTINGS
# ============================================================
BATCH_SIZE=10

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

# ============================================================
# BATCH SIZE - ONLY FOR REAL MODE
# ============================================================
if [[ "$mode" == "real" ]]; then
    echo
    echo "Batch size for asking before processing?"
    echo "  Default: 10"
    echo "  Enter a positive number, or press Enter for default."
    echo -n "Batch size [10]: "

    input=""
    IFS= read -r -t 60 input || true

    if [[ -z "$input" ]]; then
        BATCH_SIZE=10
    elif [[ "$input" =~ ^[1-9][0-9]*$ ]]; then
        BATCH_SIZE="$input"
    else
        echo "Invalid batch size. Using default: 10"
        BATCH_SIZE=10
    fi

    echo -e "Batch size selected: ${CYAN}$BATCH_SIZE${RESET}"
fi

sleep 1

# ============================================================
# HELPERS
# ============================================================
have_boxes=no
if command -v boxes >/dev/null 2>&1; then
    have_boxes=yes
fi

print_file_block() {
    local original_in="$1"
    local new_in="$2"
    local out="$3"

    if [[ "$have_boxes" == "yes" ]]; then
        {
            printf "INPUT:  %s\n" "$original_in"
            printf "RENAME: %s %s %s\n" "$original_in" "$ARROW" "$new_in"
            printf "OUTPUT: %s\n" "$out"
        } | boxes -d stone
    else
        echo -e "${RED}INPUT:${RESET}  $original_in"
        echo -e "${GREEN}RENAME:${RESET} $original_in $ARROW $new_in"
        echo -e "${GREEN}OUTPUT:${RESET} $out"
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

    if [[ "$have_boxes" == "yes" ]]; then
        {
            echo "RESTORING: current file state"
            [[ -n "$removed_msg" ]] && echo "$removed_msg"
            [[ -n "$restored_msg" ]] && echo "$restored_msg"
        } | boxes -d stone
    else
        echo -e "${YELLOW}INTERRUPTED:${RESET} restoring current file state..."
        [[ -n "$removed_msg" ]] && echo -e "${YELLOW}${removed_msg}${RESET}"
        [[ -n "$restored_msg" ]] && echo -e "${YELLOW}${restored_msg}${RESET}"
    fi
}

# ============================================================
# STATE
# ============================================================
files_examined=0
files_affected=0
files_skipped=0
stopped_by_user=no

declare -a affected_list=()

current_original_in=""
current_new_in=""
current_out=""
current_renamed=no

record_change() {
    local old="$1"
    local mid="$2"
    local new="$3"
    affected_list+=("$old|$mid|$new")
}

cleanup_current_file() {
    if [[ "$current_renamed" == "yes" ]]; then
        local removed_msg=""
        local restored_msg=""

        if [[ -n "$current_out" && -e "$current_out" ]]; then
            rm -f -- "$current_out"
            removed_msg="REMOVED: $current_out"
        fi

        if [[ -n "$current_new_in" && -e "$current_new_in" && -n "$current_original_in" && ! -e "$current_original_in" ]]; then
            mv -f -- "$current_new_in" "$current_original_in"
            restored_msg="RESTORED: $current_new_in $ARROW $current_original_in"
        fi

        echo
        print_restore_block "$removed_msg" "$restored_msg"
    fi

    echo
    echo "Aborted by Ctrl-C."
    exit 130
}

trap cleanup_current_file INT

process_one_file() {
    local original_in="$1"
    local new_in="$2"
    local out="$3"

    if [[ -e "$out" ]]; then
        echo
        echo -e "${YELLOW}SKIP:${RESET} Output already exists: $out"
        ((++files_skipped))
        return 0
    fi

    if [[ -e "$new_in" || -e "$out" ]]; then
        echo
        echo -e "${YELLOW}SKIP:${RESET} Target exists: '$new_in' or '$out'"
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

    record_change "$original_in" "$new_in" "$out"
    ((++files_affected))

    current_original_in=""
    current_new_in=""
    current_out=""
    current_renamed=no
}

# ============================================================
# BUILD FILE LIST
# ============================================================
declare -a discovered_files=()
declare -a all_files=()

for f in *.wav *.mp3 *.m4a *.flac *.ogg *.opus *.aac *.mp4; do
    [[ -e "$f" ]] || continue
    discovered_files+=("$f")
done

if (( ${#discovered_files[@]} > 0 )); then
    mapfile -t all_files < <(printf '%s\n' "${discovered_files[@]}" | LC_ALL=C sort)
fi

declare -a filtered_files=()
for f in "${all_files[@]}"; do
    ((++files_examined))
    if [[ "$f" == *_ORG.* || "$f" == *_OUTPUT.* ]]; then
        ((++files_skipped))
        continue
    fi
    filtered_files+=("$f")
done
all_files=("${filtered_files[@]}")

# ============================================================
# DRY-RUN
# ============================================================
if [[ "$mode" == "dry-run" ]]; then
    for original_in in "${all_files[@]}"; do
        new_in="${original_in%.*}_ORG.${original_in##*.}"
        base="${new_in%.*}"
        base="${base%_ORG}"
        out="${base}_OUTPUT.flac"

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
        echo "----------------------------------------"

        ((++files_affected))
        record_change "$original_in" "$new_in" "$out"
    done

# ============================================================
# REAL MODE - ASK IN BATCHES, THEN PROCESS BATCH
# ============================================================
else
    total_files=${#all_files[@]}
    idx=0
    stop_after_current_batch=no

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

        while (( idx < total_files && batch_count < BATCH_SIZE )); do
            original_in="${all_files[$idx]}"
            new_in="${original_in%.*}_ORG.${original_in##*.}"
            base="${new_in%.*}"
            base="${base%_ORG}"
            out="${base}_OUTPUT.flac"

            overall_pos=$(( idx + 1 ))
            batch_pos=$(( batch_count + 1 ))
            still_after_this=$(( total_files - overall_pos ))

            echo
            print_prompt_and_decision_summary \
                "$batch_pos" "$batch_size_now" "$overall_pos" "$total_files" "$still_after_this" \
                "$batch_yes" "$batch_no"
            print_file_block "$original_in" "$new_in" "$out"
            echo -n "Process this file later in this batch? [Y/n/q]: "
            read -t 300 -n 1 input || true
            echo

            case "$input" in
                q|Q)
                    stopped_by_user=yes
                    stop_after_current_batch=yes
                    break
                    ;;
                n|N)
                    batch_selected+=("no")
                    ((++files_skipped))
                    ((++batch_no))
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

        if [[ "$stop_after_current_batch" == "yes" ]]; then
            break
        fi
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
if [[ "$mode" == "real" ]]; then
    echo "Batch size:            $BATCH_SIZE"
fi
echo "Boxes available:       $have_boxes"
echo "Colors enabled:        $use_colors"
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
