#!/usr/bin/env bash
# 2026.03.27 - v. 1.2 - added many changes about media files
# 2026.03.27 - v. 1.3 - fixed top-level path handling: keep ./ prefix in transform_name()
# 2026.03.27 - v. 1.4 - apply special media renames after basic normalization
# 2026.03.27 - v. 1.5 - added question: current directory only vs also subdirectories
# 2026.03.27 - v. 1.6 - in real mode, default answer is YES for rename prompts
# 2026.03.27 - v. 1.7 - made Sprache/Voice/Screen_Recording patterns tolerant to -/_ after normalization
# 2026.03.27 - v. 1.8 - added Call_recording rule
# 2026.03.27 - v. 2.0 - preserve original top-level path style (with or without ./) in transform_name()
# 2026.03.31 - v. 2.6 - add .md5 support with before/after verification and content updates
# 2026.03.31 - v. 2.7 - stop the whole script immediately when checksum verification fails
# 2026.03.31 - v. 2.8 - treat .sha512 and .md5 with exactly the same logic
# 2026.03.31 - v. 3.0 - always normalize checksum files from CRLF to LF before any checks in real mode
# 2026.03.31 - v. 3.1 - print clear info after Windows to Unix checksum file conversion was actually done
# 2026.03.31 - v. 3.3 - verify checksum files from their own directory
# 2026.03.31 - v. 3.4 - added -v / --verbose logging
# 2026.03.31 - v. 3.6 - only do checksum verification when renames or checksum-file modifications are actually needed
# 2026.03.31 - v. 3.8 - added ERR trap to show line number, exit code, and failed command
# 2026.03.31 - v. 4.1 - verbose logs go to stderr so command substitutions are not corrupted
# 2026.03.31 - v. 4.2 - removed whole-tree path discovery; use local directory processing only

set -Eeuo pipefail
shopt -s nullglob

VERBOSE=0

on_err() {
    local exit_code="$1"
    local line_no="$2"
    local cmd="$3"
    echo
    echo "ERROR: command failed at line $line_no with exit code $exit_code" >&2
    echo "FAILED COMMAND: $cmd" >&2
}
trap 'on_err "$?" "$LINENO" "$BASH_COMMAND"' ERR

usage() {
    cat <<'EOF'
Usage: rename.sh [-v|--verbose] [-h|--help]

Options:
  -v, --verbose   Show extra diagnostic output
  -h, --help      Show this help
EOF
}

for arg in "$@"; do
    case "$arg" in
        -v|--verbose)
            VERBOSE=1
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            usage >&2
            exit 1
            ;;
    esac
done

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

vlog() {
    (( VERBOSE == 1 )) || return 0
    echo -e "${CYAN}[VERBOSE]${RESET} $*" >&2
}

echo
echo "Select mode:"
echo "  [D] Dry-run (default)"
echo "  [R] Real rename (interactive)"
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

echo
echo "What should be processed?"
echo "  [C] Current directory only (default)"
echo "  [S] Also subdirectories"
echo "  [Q] Quit"
echo -n "Choice [C/s/q]: "

process_scope="current"
input=""

read -t 60 -n 1 input || true
echo

if [[ "$input" =~ [Qq] ]]; then
    echo "Quitting."
    exit 0
elif [[ "$input" =~ [Ss] ]]; then
    process_scope="subdirs"
fi

echo -e "Scope selected: ${CYAN}$process_scope${RESET}"
sleep 1

vlog "Verbose mode enabled"

is_excluded_path() {
    local p="$1"
    [[ "$(basename -- "$p")" == "[Originals]" ]]
}

is_checksum_file() {
    local p="$1"
    [[ "$p" == *.sha512 || "$p" == *.md5 ]]
}

checksum_kind() {
    local p="$1"
    if [[ "$p" == *.sha512 ]]; then
        printf 'sha512'
    elif [[ "$p" == *.md5 ]]; then
        printf 'md5'
    else
        return 1
    fi
}

checksum_label() {
    local p="$1"
    case "$(checksum_kind "$p")" in
        sha512) printf 'SHA512' ;;
        md5)    printf 'MD5' ;;
    esac
}

checksum_cmd() {
    local p="$1"
    case "$(checksum_kind "$p")" in
        sha512) printf 'sha512sum' ;;
        md5)    printf 'md5sum' ;;
    esac
}

stop_on_checksum_failure() {
    local sum_file="$1"
    local phase="$2"
    local label
    label="$(checksum_label "$sum_file")"

    echo -e "${RED}${label} ERROR:${RESET} ${label} verification ${phase} failed for '$sum_file'."
    echo -e "${RED}STOPPING:${RESET} Script execution aborted because ${label} is incorrect."
    exit 1
}

transform_basename() {
    local new="$1"

    new="${new//ą/a}"
    new="${new//ć/c}"
    new="${new//ę/e}"
    new="${new//ł/l}"
    new="${new//ń/n}"
    new="${new//ó/o}"
    new="${new//ś/s}"
    new="${new//ż/z}"
    new="${new//ź/z}"

    new="${new//Ą/A}"
    new="${new//Ć/C}"
    new="${new//Ę/E}"
    new="${new//Ł/L}"
    new="${new//Ń/N}"
    new="${new//Ó/O}"
    new="${new//Ś/S}"
    new="${new//Ż/Z}"
    new="${new//Ź/Z}"

    new="${new//(/_}"
    new="${new//)/_}"
    new="${new//\{/_}"
    new="${new//\}/_}"
    new="${new//\[/_}"
    new="${new//\]/_}"
    new="${new//,/_}"

    new="${new//!/.}"
    new="${new// /_}"
    new="${new//\'/_}"
    new="${new//&/_and_}"
    new="${new//•/-}"

    new=$(printf '%s' "$new" | sed -E '
        s/__+/_/g;
        s/_\././g;
        s/_$//;
        s/\.$//;
    ')

    if [[ "$new" =~ ^signal-([0-9]{4})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{2})-[0-9]+(\.[^.]+)$ ]]; then
        printf '%s%s%s_%s%s%s-signal%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}" \
            "${BASH_REMATCH[7]}"
        return
    fi

    if [[ "$new" =~ ^Screenshot_([0-9]{8}_[0-9]{6}_.+)(\.[^.]+)$ ]]; then
        printf '%s-screenshot%s' \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[2]}"
        return
    fi

    if [[ "$new" =~ ^Screen_Recording_([0-9]{8})[-_]([0-9]{6})[-_](.+)(\.[^.]+)$ ]]; then
        printf '%s_%s_-_Screen_Recording_-_%s%s' \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[2]}" \
            "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}"
        return
    fi

    if [[ "$new" =~ ^Call_recording_(.+)_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_Call_recording_-_%s%s' \
            "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[6]}"
        return
    fi

    if [[ "$new" =~ ^Call_recording_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})[-_](.+)(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_Call_recording_-_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[6]}"
        return
    fi

    if [[ "$new" =~ ^Sprache_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})[-_](.+)(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_VoiceRecorder_-_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[6]}"
        return
    fi

    if [[ "$new" =~ ^Sprache_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_VoiceRecorder%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}"
        return
    fi

    if [[ "$new" =~ ^Voice_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})[-_](.+)(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_VoiceRecorder_-_%s%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}" \
            "${BASH_REMATCH[6]}"
        return
    fi

    if [[ "$new" =~ ^Voice_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})(\.[^.]+)$ ]]; then
        printf '20%s%s%s_%s_-_VoiceRecorder%s' \
            "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}" \
            "${BASH_REMATCH[5]}"
        return
    fi

    printf '%s' "$new"
}

transform_name() {
    local f="$1"
    local dir base newbase

    dir="$(dirname -- "$f")"
    base="$(basename -- "$f")"
    newbase="$(transform_basename "$base")"

    if [[ "$dir" == "." ]]; then
        if [[ "$f" == ./* ]]; then
            printf './%s' "$newbase"
        else
            printf '%s' "$newbase"
        fi
    else
        printf '%s/%s' "$dir" "$newbase"
    fi
}

preserve_timestamps_inplace() {
    local file="$1"; shift
    local ref
    ref="$(mktemp)"
    touch -r "$file" "$ref"
    "$@"
    touch -r "$ref" "$file"
    rm -f "$ref"
}

checksum_file_has_crlf() {
    local sum_file="$1"
    LC_ALL=C grep -q $'\r' -- "$sum_file"
}

normalize_checksum_file() {
    local sum_file="$1"

    if command -v dos2unix >/dev/null 2>&1; then
        preserve_timestamps_inplace "$sum_file" dos2unix -q -- "$sum_file"
    else
        preserve_timestamps_inplace "$sum_file" sed -i 's/\r$//' -- "$sum_file"
    fi
}

ensure_checksum_file_unix_format() {
    local sum_file="$1"
    local label
    label="$(checksum_label "$sum_file")"

    if checksum_file_has_crlf "$sum_file"; then
        if [[ "$mode" == "dry-run" ]]; then
            echo -e "${CYAN}[DRY-RUN] Would convert ${label} file from CRLF to LF:${RESET} $sum_file"
        else
            echo -e "${CYAN}${label} NORMALIZE:${RESET} converting CRLF to LF: $sum_file"
            normalize_checksum_file "$sum_file"
            echo -e "${CYAN}${label} NORMALIZE DONE:${RESET} converted from Windows format to Unix format: $sum_file"
        fi
    fi
}

extract_checksum_entries() {
    local sum_file="$1"
    sed -E 's/\r$//' -- "$sum_file" | while IFS= read -r line; do
        [[ -n "$line" ]] || continue
        if [[ "$line" =~ ^([0-9a-fA-F]+)[[:space:]]+\*?(.*)$ ]]; then
            printf '%s\t%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
        fi
    done
}

checksum_check() {
    local sum_file="$1"
    local kind sum_dir sum_base
    kind="$(checksum_kind "$sum_file")"
    sum_dir="$(dirname -- "$sum_file")"
    sum_base="$(basename -- "$sum_file")"

    ensure_checksum_file_unix_format "$sum_file"
    vlog "Running $(checksum_cmd "$sum_file") check in directory '$sum_dir' for file '$sum_base'"

    if [[ "$mode" == "dry-run" ]]; then
        (
            cd "$sum_dir"
            case "$kind" in
                sha512) sha512sum -c --quiet -- <(sed 's/\r$//' -- "$sum_base") ;;
                md5)    md5sum    -c --quiet -- <(sed 's/\r$//' -- "$sum_base") ;;
            esac
        )
    else
        (
            cd "$sum_dir"
            case "$kind" in
                sha512) sha512sum -c --quiet -- "$sum_base" ;;
                md5)    md5sum    -c --quiet -- "$sum_base" ;;
            esac
        )
    fi
}

checksum_of_file() {
    local kind="$1"
    local file="$2"

    case "$kind" in
        sha512) sha512sum -- "$file" | awk '{print tolower($1)}' ;;
        md5)    md5sum    -- "$file" | awk '{print tolower($1)}' ;;
    esac
}

sed_escape_regex() {
    printf '%s' "$1" | sed -e 's/[.[\*^$()+?{}|\\/]/\\&/g'
}

sed_escape_repl() {
    printf '%s' "$1" | sed -e 's/[&\\/]/\\&/g'
}

strip_leading_dot_slash() {
    local p="$1"
    printf '%s' "${p#./}"
}

relative_path() {
    local from_dir="$1"
    local target="$2"
    python3 - "$from_dir" "$target" <<'PY'
import os, sys
from_dir = sys.argv[1]
target = sys.argv[2]
print(os.path.relpath(target, from_dir))
PY
}

format_ref_for_checksum_file() {
    local sum_file="$1"
    local original_ref="$2"
    local actual_path="$3"
    local sum_dir rel

    sum_dir="$(dirname -- "$sum_file")"

    if [[ "$original_ref" == /* ]]; then
        python3 - "$actual_path" <<'PY'
import os, sys
print(os.path.abspath(sys.argv[1]))
PY
        return
    fi

    rel="$(relative_path "$sum_dir" "$actual_path")"

    if [[ "$original_ref" == ./* ]]; then
        printf './%s' "$rel"
    else
        printf '%s' "$rel"
    fi
}

update_checksum_content_refs() {
    local sum_file="$1"
    local old_name="$2"
    local new_name="$3"

    local old_re1 new_re1 old_re2 new_re2
    old_re1="$(sed_escape_regex "$old_name")"
    new_re1="$(sed_escape_repl "$new_name")"

    old_re2="$(sed_escape_regex "$(strip_leading_dot_slash "$old_name")")"
    new_re2="$(sed_escape_repl "$(strip_leading_dot_slash "$new_name")")"

    vlog "Updating checksum content in '$sum_file': '$old_name' -> '$new_name'"

    preserve_timestamps_inplace "$sum_file" \
        sed -i -E \
            -e "s|([[:space:]]\\*?)${old_re1}\$|\\1${new_re1}|g" \
            -e "s|([[:space:]]\\*?)${old_re2}\$|\\1${new_re2}|g" \
            -- "$sum_file"
}

resolve_checksum_ref_path() {
    local sum_file="$1"
    local ref="$2"
    local sum_dir candidate

    sum_dir="$(dirname -- "$sum_file")"

    if [[ "$ref" == /* ]]; then
        printf '%s' "$ref"
        return
    fi

    if [[ "$ref" == ./* ]]; then
        if [[ "$sum_dir" == "." ]]; then
            printf '%s' "$ref"
        else
            printf '%s/%s' "$sum_dir" "${ref#./}"
        fi
        return
    fi

    if [[ "$sum_dir" == "." ]]; then
        if [[ -e "./$ref" ]]; then
            printf './%s' "$ref"
        else
            printf '%s' "$ref"
        fi
    else
        candidate="$sum_dir/$ref"
        printf '%s' "$candidate"
    fi
}

variant_family_info() {
    local p="$1"
    local base stem variant ext

    base="$(basename -- "$p")"
    if [[ "$base" =~ ^(.+)_((ORG)|(OUTPUT)|(EXCLUDE))(\.[^.]+)$ ]]; then
        stem="${BASH_REMATCH[1]}"
        variant="${BASH_REMATCH[2]}"
        ext="${BASH_REMATCH[6]}"
        printf '%s|%s|%s' "$stem" "$variant" "$ext"
        return 0
    fi
    return 1
}

print_grouped_checksum_missing_warning() {
    local sum_file="$1"
    shift
    local -a refs=( "$@" )

    local ref info stem variant ext key rest
    local -A family_variants=()
    local found_group=no

    for ref in "${refs[@]}"; do
        if info="$(variant_family_info "$ref")"; then
            stem="${info%%|*}"
            rest="${info#*|}"
            variant="${rest%%|*}"
            ext="${rest##*|}"
            key="$stem"
            family_variants["$key"]+="${variant} "
            found_group=yes
        fi
    done

    [[ "$found_group" == "yes" ]] || return 0

    echo -e "${YELLOW}CHECKSUM GROUP WARNING:${RESET} '$sum_file' contains grouped ORG/OUTPUT/EXCLUDE-style references."

    local family present_variants expected_variants expected_variant
    for family in "${!family_variants[@]}"; do
        present_variants="${family_variants[$family]}"
        expected_variants="ORG OUTPUT"

        for expected_variant in $expected_variants; do
            [[ "$present_variants" == *"${expected_variant} "* ]] && continue
            echo -e "  ${YELLOW}Missing reference in group:${RESET} ${family}_${expected_variant}.*"
        done
    done
}

find_best_path_for_missing_ref() {
    local missing_ref="$1"
    local expected_hash="$2"
    local sum_file="$3"

    local kind wanted_base wanted_norm missing_dir
    local fast_base fast_path fast_hash

    kind="$(checksum_kind "$sum_file")"
    wanted_base="$(basename -- "$missing_ref")"
    wanted_norm="$(transform_basename "$wanted_base")"
    missing_dir="$(dirname -- "$missing_ref")"

    vlog "Trying to recover missing ref '$missing_ref' (expected hash: ${expected_hash:-none})"

    fast_base="$wanted_norm"
    fast_path="${missing_dir}/${fast_base}"

    if [[ -f "$fast_path" ]]; then
        vlog "Fast recovery candidate in same directory: '$fast_path'"
        if [[ -n "$expected_hash" ]]; then
            fast_hash="$(checksum_of_file "$kind" "$fast_path")"
            vlog "Fast recovery candidate has $kind=$fast_hash"
            if [[ "${fast_hash,,}" == "${expected_hash,,}" ]]; then
                vlog "Fast recovery candidate checksum matches"
                printf '%s' "$fast_path"
                return 0
            else
                vlog "Fast recovery candidate checksum does not match"
            fi
        else
            vlog "Fast recovery candidate accepted (no expected hash available)"
            printf '%s' "$fast_path"
            return 0
        fi
    fi

    vlog "Fast same-directory recovery failed for '$missing_ref'"
    return 1
}

files_examined=0
files_affected=0
files_skipped=0
stopped_by_user=no
rename_all=no

declare -a renamed_list=()
declare -A recorded
declare -A processed

record_rename() {
    local old="$1" new="$2"
    local key="$old|$new"
    [[ -n "${recorded[$key]+x}" ]] && return 0
    recorded["$key"]=1
    renamed_list+=("$key")
}

if [[ "$process_scope" == "current" ]]; then
    mapfile -d '' -t ordered_paths < <(find . -mindepth 1 -maxdepth 1 -depth -print0)
else
    mapfile -d '' -t ordered_paths < <(find . -depth -mindepth 1 -print0)
fi

vlog "Discovered entries to process: ${#ordered_paths[@]}"

main_index=0
for f in "${ordered_paths[@]}"; do
    ((++main_index))
    if (( VERBOSE == 1 && main_index % VERBOSE_MAIN_EVERY == 0 )); then
        vlog "Main loop progress: $main_index / ${#ordered_paths[@]} (current: '$f')"
    fi

    [[ -n "${processed[$f]+x}" ]] && continue
    ((++files_examined))

    if is_excluded_path "$f"; then
        vlog "Skipping excluded path '$f'"
        ((++files_skipped))
        continue
    fi

    if [[ -f "$f" ]] && is_checksum_file "$f"; then
        sum_file="$f"
        label="$(checksum_label "$sum_file")"

        vlog "Processing checksum file '$sum_file'"

        if [[ "$mode" == "real" ]] && checksum_file_has_crlf "$sum_file"; then
            ensure_checksum_file_unix_format "$sum_file"
        fi

        refs_raw=()
        refs=()
        expected_hashes=()

        while IFS=$'\t' read -r hash ref; do
            [[ -n "$ref" ]] || continue
            expected_hashes+=( "$hash" )
            refs_raw+=( "$ref" )
            refs+=( "$(resolve_checksum_ref_path "$sum_file" "$ref")" )
            vlog "Resolved ref '$ref' -> '${refs[-1]}'"
        done < <(extract_checksum_entries "$sum_file")

        if (( ${#refs[@]} == 0 )) || [[ -z "${refs[0]}" ]]; then
            vlog "Checksum file '$sum_file' has no valid refs"
            ((++files_skipped))
            processed["$sum_file"]=1
            continue
        fi

        declare -a recovered_old_refs=()
        declare -a recovered_new_real_refs=()
        declare -a recovered_new_written_refs=()
        checksum_content_modified=no

        for i in "${!refs[@]}"; do
            ref="${refs[$i]}"
            if [[ -e "$ref" ]]; then
                vlog "Ref exists already: '$ref'"
                continue
            fi

            vlog "Ref missing, trying recovery: '$ref'"
            found_ref="$(find_best_path_for_missing_ref "$ref" "${expected_hashes[$i]}" "$sum_file" || true)"
            if [[ -n "$found_ref" ]]; then
                replacement_ref="$(format_ref_for_checksum_file "$sum_file" "${refs_raw[$i]}" "$found_ref")"
                recovered_old_refs+=( "${refs_raw[$i]}" )
                recovered_new_real_refs+=( "$found_ref" )
                recovered_new_written_refs+=( "$replacement_ref" )
                refs_raw[$i]="$replacement_ref"
                refs[$i]="$found_ref"
                checksum_content_modified=yes
                vlog "Recovery success: '$ref' -> '$found_ref' (write as '$replacement_ref')"
            else
                vlog "Recovery failed for '$ref'"
            fi
        done

        if (( ${#recovered_old_refs[@]} > 0 )); then
            echo
            echo -e "${CYAN}${label} RECOVERY:${RESET} '$sum_file' references missing file(s), but replacement file(s) were found."
            for i in "${!recovered_old_refs[@]}"; do
                echo -e "  ${RED}OLD REF:${RESET} ${recovered_old_refs[$i]}"
                echo -e "  ${GREEN}FOUND:${RESET}   ${recovered_new_real_refs[$i]}"
                echo -e "  ${GREEN}WRITE:${RESET}   ${recovered_new_written_refs[$i]}"
            done

            if [[ "$mode" == "real" ]]; then
                ensure_checksum_file_unix_format "$sum_file"
                for i in "${!recovered_old_refs[@]}"; do
                    update_checksum_content_refs "$sum_file" "${recovered_old_refs[$i]}" "${recovered_new_written_refs[$i]}"
                done
                echo -e "${CYAN}${label} RECOVERY UPDATED:${RESET} '$sum_file' was updated to point to the found file(s)."
            else
                echo -e "${CYAN}[DRY-RUN] Would update ${label,,} content to use the found file(s) above.${RESET}"
            fi
        fi

        missing=no
        declare -a missing_refs=()
        for ref in "${refs[@]}"; do
            if [[ ! -e "$ref" ]]; then
                missing=yes
                missing_refs+=( "$ref" )
            fi
        done

        if [[ "$missing" == "yes" ]]; then
            echo
            echo -e "${YELLOW}${label} SKIP:${RESET} '$sum_file' still references missing file(s)."
            for ref in "${missing_refs[@]}"; do
                echo -e "  ${YELLOW}MISSING:${RESET} $ref"
            done
            print_grouped_checksum_missing_warning "$sum_file" "${refs[@]}"
            ((++files_skipped))
            processed["$sum_file"]=1
            continue
        fi

        new_sum="$(transform_name "$sum_file")"
        declare -a new_refs=()
        refs_need_rename=no
        for ref in "${refs[@]}"; do
            new_ref="$(transform_name "$ref")"
            new_refs+=( "$new_ref" )
            [[ "$new_ref" != "$ref" ]] && refs_need_rename=yes
        done

        sum_file_needs_rename=no
        [[ "$new_sum" != "$sum_file" ]] && sum_file_needs_rename=yes

        action_needed=no
        [[ "$refs_need_rename" == "yes" ]] && action_needed=yes
        [[ "$sum_file_needs_rename" == "yes" ]] && action_needed=yes
        [[ "$checksum_content_modified" == "yes" ]] && action_needed=yes

        if [[ "$action_needed" == "no" ]]; then
            vlog "All referenced files exist and no rename/update is needed for '$sum_file' - skipping without checksum verification"
            ((++files_skipped))
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        if [[ "$mode" == "dry-run" ]]; then
            echo
            if [[ "$checksum_content_modified" == "yes" ]]; then
                echo -e "${CYAN}[DRY-RUN] Would check ${label} because checksum content would be modified:${RESET} $sum_file"
            else
                echo -e "${CYAN}[DRY-RUN] Would check ${label} because rename is needed:${RESET} $sum_file"
            fi
            echo -e "${RED}OLD ${label}:${RESET} $sum_file"
            echo -e "${GREEN}NEW ${label}:${RESET} $new_sum"
            for i in "${!refs[@]}"; do
                echo -e "${RED}OLD FILE:${RESET} ${refs[$i]}"
                echo -e "${GREEN}NEW FILE:${RESET} ${new_refs[$i]}"
            done
            echo -e "${CYAN}[DRY-RUN] Would update ${label,,} content references inside:${RESET} $sum_file"
            echo -e "${CYAN}[DRY-RUN] Would check ${label} after rename:${RESET} $new_sum"
            echo "----------------------------------------"

            ((++files_affected))
            record_rename "$sum_file" "$new_sum"
            for i in "${!refs[@]}"; do
                record_rename "${refs[$i]}" "${new_refs[$i]}"
            done

            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        ensure_checksum_file_unix_format "$sum_file"

        echo
        echo -e "${RED}OLD ${label}:${RESET} $sum_file"
        echo -e "${GREEN}NEW ${label}:${RESET} $new_sum"
        for i in "${!refs[@]}"; do
            echo -e "${RED}OLD FILE:${RESET} ${refs[$i]}"
            echo -e "${GREEN}NEW FILE:${RESET} ${new_refs[$i]}"
        done

        do_rename=no
        if [[ "$rename_all" == "yes" ]]; then
            do_rename=yes
        else
            echo -n "Rename this ${label,,} + referenced file(s)? [Y/n/a/q]: "
            read -t 300 -n 1 input || true
            echo

            case "$input" in
                q|Q)
                    stopped_by_user=yes
                    break
                    ;;
                n|N)
                    ((++files_skipped))
                    do_rename=no
                    ;;
                a|A)
                    echo
                    echo "⚠️  This will rename ALL remaining files/directories."
                    echo -n "Are you sure? [y/N]: "
                    read -n 1 confirm || true
                    echo
                    if [[ "$confirm" =~ [Yy] ]]; then
                        rename_all=yes
                        do_rename=yes
                    else
                        ((++files_skipped))
                        do_rename=no
                    fi
                    ;;
                *)
                    do_rename=yes
                    ;;
            esac
        fi

        if [[ "$do_rename" != "yes" ]]; then
            vlog "User skipped checksum group '$sum_file'"
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        echo -e "${CYAN}${label} check (before rename) in progress...${RESET} $sum_file"
        if ! checksum_check "$sum_file"; then
            echo -e "${YELLOW}${label} FAIL:${RESET} checksum mismatch for '$sum_file' (won't rename pair)"
            stop_on_checksum_failure "$sum_file" "before rename"
        fi
        echo -e "${CYAN}${label} VERIFIED (before rename):${RESET} $sum_file"

        collision=no
        [[ "$new_sum" != "$sum_file" && -e "$new_sum" ]] && collision=yes
        for i in "${!refs[@]}"; do
            [[ "${new_refs[$i]}" != "${refs[$i]}" && -e "${new_refs[$i]}" ]] && collision=yes
        done

        if [[ "$collision" == "yes" ]]; then
            echo -e "${YELLOW}SKIP:${RESET} Target file already exists."
            vlog "Collision detected in checksum group '$sum_file'"
            ((++files_skipped))
            processed["$sum_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        for i in "${!refs[@]}"; do
            if [[ "${new_refs[$i]}" != "${refs[$i]}" ]]; then
                vlog "Renaming referenced file '${refs[$i]}' -> '${new_refs[$i]}'"
                mv -i -- "${refs[$i]}" "${new_refs[$i]}"
                ((++files_affected))
                record_rename "${refs[$i]}" "${new_refs[$i]}"
            else
                ((++files_skipped))
            fi
        done

        for i in "${!refs[@]}"; do
            old_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "${refs_raw[$i]}" "${refs[$i]}")"
            new_ref_for_write="$(format_ref_for_checksum_file "$sum_file" "${refs_raw[$i]}" "${new_refs[$i]}")"
            if [[ "$old_ref_for_write" != "$new_ref_for_write" ]]; then
                update_checksum_content_refs "$sum_file" "$old_ref_for_write" "$new_ref_for_write"
            fi
        done

        final_sum="$sum_file"
        if [[ "$new_sum" != "$sum_file" ]]; then
            vlog "Renaming checksum file '$sum_file' -> '$new_sum'"
            mv -i -- "$sum_file" "$new_sum"
            ((++files_affected))
            record_rename "$sum_file" "$new_sum"
            final_sum="$new_sum"
        else
            ((++files_skipped))
        fi

        echo -e "${CYAN}${label} check (after rename) in progress...${RESET} $final_sum"
        if checksum_check "$final_sum"; then
            echo -e "${CYAN}${label} VERIFIED (after rename):${RESET} $final_sum"
            echo -e "${GREEN}${label} OK:${RESET} referenced file name(s) were updated inside '$final_sum' and ${label,,} checksum(s) are correct."
        else
            echo -e "${YELLOW}${label} FAIL (after rename):${RESET} '$final_sum' does not validate."
            echo -e "${YELLOW}NOTE:${RESET} Files were renamed, but checksum verification after update failed."
            stop_on_checksum_failure "$final_sum" "after rename"
        fi

        vlog "Finished checksum group '$sum_file'"

        processed["$sum_file"]=1
        processed["$final_sum"]=1
        for ref in "${refs[@]}"; do processed["$ref"]=1; done
        for ref in "${new_refs[@]}"; do processed["$ref"]=1; done

        continue
    fi

    if [[ -f "$f" ]]; then
        base="${f%.*}"
        if [[ -e "$base.sha512" || -e "$base.md5" ]]; then
            vlog "Skipping '$f' because sibling checksum file exists"
            ((++files_skipped))
            continue
        fi
    fi

    new="$(transform_name "$f")"
    [[ "$f" == "$new" ]] && {
        vlog "No rename needed for '$f'"
        ((++files_skipped))
        continue
    }

    if [[ "$mode" == "dry-run" ]]; then
        echo
        echo -e "${RED}OLD:${RESET} $f"
        echo -e "${GREEN}NEW:${RESET} $new"
        echo "----------------------------------------"
        ((++files_affected))
        record_rename "$f" "$new"
        continue
    fi

    echo
    echo -e "${RED}OLD:${RESET} $f"
    echo -e "${GREEN}NEW:${RESET} $new"

    if [[ "$rename_all" == "yes" ]]; then
        vlog "Renaming '$f' -> '$new' due to rename_all"
        if mv -i -- "$f" "$new"; then
            ((++files_affected))
            record_rename "$f" "$new"
        else
            ((++files_skipped))
        fi
        continue
    fi

    echo -n "Rename this entry? [Y/n/a/q]: "
    read -t 300 -n 1 input || true
    echo

    case "$input" in
        q|Q)
            stopped_by_user=yes
            break
            ;;
        n|N)
            ((++files_skipped))
            ;;
        a|A)
            echo
            echo "⚠️  This will rename ALL remaining files/directories."
            echo -n "Are you sure? [y/N]: "
            read -n 1 confirm || true
            echo

            if [[ "$confirm" =~ [Yy] ]]; then
                rename_all=yes
                vlog "rename_all enabled by user"
                if mv -i -- "$f" "$new"; then
                    ((++files_affected))
                    record_rename "$f" "$new"
                else
                    ((++files_skipped))
                fi
            else
                ((++files_skipped))
            fi
            ;;
        *)
            vlog "Renaming '$f' -> '$new'"
            if mv -i -- "$f" "$new"; then
                ((++files_affected))
                record_rename "$f" "$new"
            else
                ((++files_skipped))
            fi
            ;;
    esac
done

echo
echo "========= SUMMARY ========="
echo "Mode:                  $mode"
echo "Colors enabled:        $use_colors"
echo "Verbose:               $VERBOSE"
echo "Scope:                 $process_scope"
echo "Entries examined:      $files_examined"
echo "Entries affected:      $files_affected"
echo "Entries skipped:       $files_skipped"
echo "Stopped by user:       $stopped_by_user"

if (( files_affected > 0 )); then
    echo
    echo "Affected entries:"
    for r in "${renamed_list[@]}"; do
        old=${r%%|*}
        new=${r#*|}
        printf "  %s %b%s%b %s\n" \
            "$old" \
            "$RED" "$ARROW" "$RESET" \
            "$new"
    done
fi
echo "==========================="
