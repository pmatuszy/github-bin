#!/usr/bin/env bash
# 2026.03.27 - v. 1.2 - added many changes about media files

# 2026.02.26 - v. 1.1 - Restored full-feature script (counters/summary/rename_all/processed); REAL sha: ask->verify(before)->rename+update->verify(after) + progress msg
# 2026.02.26 - v. 1.0 - REAL mode: verify BEFORE rename and AFTER rename (full integrity check); ask before hashing; show progress messages
# 2026.02.26 - v. 0.9 - Ask first in REAL mode (verify only if user agrees); show "sha512 check in progress..."
# 2026.02.26 - v. 0.8 - Fix real-mode ordering for naming: skip normal rename if sibling "${base}.sha512" exists
# 2026.02.26 - v. 0.7 - Fix real-mode ordering: normal files with matching .sha512 skipped (pair handled only via .sha512)
# 2026.02.26 - v. 0.6 - Dry-run sha512 verification is read-only (CRLF stripped in-memory); real mode normalizes on-disk w/ timestamp preserved
# 2026.02.26 - v. 0.5 - Fix set -e + ((var++)) issue (use ++var)
# 2026.02.26 - v. 0.4 - Preserve sha512 timestamps when normalizing/updating
# 2026.02.26 - v. 0.3 - Added sha512 pair verification + rename + update sha content + CRLF normalize (real mode only)
# 2025.12.22 - v. 0.2 - Bash-only version, UTF-8 safe (no perl, no tr on diacritics)
# 2025.12.15 - v. 0.1 - initial release (some work with ChatGPT)

set -euo pipefail
shopt -s nullglob

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

# -------- COLORS SETUP --------
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
sleep 1

# ============================================================
# HELPERS
# ============================================================

is_excluded_path() {
    local p="$1"
    [[ "$p" == "[Originals]" || "$p" == "[Originals]/"* ]]
}

transform_name() {
    local f="$1"
    local new="$f"

    # -------- SPECIAL MEDIA RENAMES --------
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

    if [[ "$new" =~ ^Screen_Recording_([0-9]{8})_([0-9]{6})_(.+)(\.[^.]+)$ ]]; then
        printf '%s_%s_-_Screen_Recording_-_%s%s' \
            "${BASH_REMATCH[1]}" \
            "${BASH_REMATCH[2]}" \
            "${BASH_REMATCH[3]}" \
            "${BASH_REMATCH[4]}"
        return
    fi

    if [[ "$new" =~ ^Sprache_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})_(.+)(\.[^.]+)$ ]]; then
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

    if [[ "$new" =~ ^Voice_([0-9]{2})([0-9]{2})([0-9]{2})_([0-9]{6})_(.+)(\.[^.]+)$ ]]; then
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

    # -------- POLISH DIACRITICS (UTF-8 SAFE) --------
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

    # -------- STRUCTURAL CHARACTERS --------
    new="${new//(/_}"
    new="${new//)/_}"
    new="${new//\{/_}"
    new="${new//\}/_}"
    new="${new//\[/_}"
    new="${new//\]/_}"
    new="${new//,/_}"

    # -------- OTHER NORMALIZATION --------
    new="${new//!/.}"
    new="${new// /_}"
    new="${new//\'/_}"
    new="${new//&/_and_}"
    new="${new//•/-}"

    # -------- CLEANUP --------
    new=$(printf '%s' "$new" | sed -E '
        s/__+/_/g;
        s/_\././g;
        s/_$//;
        s/\.$//;
    ')

    printf '%s' "$new"
}

# Preserve atime+mtime across an in-place modification
preserve_timestamps_inplace() {
    local file="$1"; shift
    local ref
    ref="$(mktemp)"
    touch -r "$file" "$ref"
    "$@"
    touch -r "$ref" "$file"
    rm -f "$ref"
}

# Normalize sha file line endings (CRLF -> LF) ON DISK, preserving timestamps.
normalize_sha_file() {
    local sha_file="$1"

    if command -v dos2unix >/dev/null 2>&1; then
        preserve_timestamps_inplace "$sha_file" dos2unix -q -- "$sha_file"
    else
        preserve_timestamps_inplace "$sha_file" sed -i 's/\r$//' -- "$sha_file"
    fi
}

# sha512 verification:
# - dry-run: do NOT touch files; strip CRLF in-memory only
# - real: normalize on disk (timestamp preserved), then verify
sha512_check() {
    local sha_file="$1"
    if [[ "$mode" == "dry-run" ]]; then
        sha512sum -c --quiet -- <(sed 's/\r$//' -- "$sha_file")
    else
        normalize_sha_file "$sha_file"
        sha512sum -c --quiet -- "$sha_file"
    fi
}

# Extract referenced filename(s) from sha512 file (supports multiple lines).
# Handles:
#   HASH *filename
#   HASH  filename
# Also strips trailing CR in-memory.
extract_refs_from_sha512() {
    local sha_file="$1"
    sed -E 's/^[0-9a-fA-F]+[[:space:]]+\*?//; s/\r$//' -- "$sha_file"
}

# Escape a string for sed regex
sed_escape_regex() {
    printf '%s' "$1" | sed -e 's/[.[\*^$()+?{}|\\/]/\\&/g'
}

# Escape replacement string for sed replacement
sed_escape_repl() {
    printf '%s' "$1" | sed -e 's/[&\\/]/\\&/g'
}

# Update sha512 file content so any line referencing old name now references new name.
# Preserves "*old" vs " old" by capturing the optional "*".
# Preserves original timestamps.
update_sha512_content_refs() {
    local sha_file="$1"
    local old_name="$2"
    local new_name="$3"

    local old_re new_re
    old_re="$(sed_escape_regex "$old_name")"
    new_re="$(sed_escape_repl "$new_name")"

    preserve_timestamps_inplace "$sha_file" \
        sed -i -E "s|([[:space:]]\\*?)${old_re}\$|\\1${new_re}|g" -- "$sha_file"
}

# ============================================================
# STATE
# ============================================================
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

# ============================================================
# MAIN LOOP
# ============================================================
for f in *; do
    [[ -n "${processed[$f]+x}" ]] && continue
    ((++files_examined))

    if is_excluded_path "$f"; then
        ((++files_skipped))
        continue
    fi

    # ------------------------------------------------------------
    # SPECIAL CASE: .sha512 files (pair handling)
    # ------------------------------------------------------------
    if [[ "$f" == *.sha512 ]]; then
        sha_file="$f"

        mapfile -t refs < <(extract_refs_from_sha512 "$sha_file")

        if (( ${#refs[@]} == 0 )) || [[ -z "${refs[0]}" ]]; then
            ((++files_skipped))
            processed["$sha_file"]=1
            continue
        fi

        missing=no
        for ref in "${refs[@]}"; do
            if is_excluded_path "$ref"; then
                missing=yes
                break
            fi
            [[ -e "$ref" ]] || { missing=yes; break; }
        done

        if [[ "$missing" == "yes" ]]; then
            echo
            echo -e "${YELLOW}SHA512 SKIP:${RESET} '$sha_file' references missing or excluded file(s)."
            ((++files_skipped))
            processed["$sha_file"]=1
            continue
        fi

        new_sha="$(transform_name "$sha_file")"
        declare -a new_refs=()
        for ref in "${refs[@]}"; do
            new_refs+=( "$(transform_name "$ref")" )
        done

        nothing_changes=yes
        [[ "$new_sha" != "$sha_file" ]] && nothing_changes=no
        for i in "${!refs[@]}"; do
            [[ "${new_refs[$i]}" != "${refs[$i]}" ]] && nothing_changes=no
        done
        if [[ "$nothing_changes" == "yes" ]]; then
            ((++files_skipped))
            processed["$sha_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        if [[ "$mode" == "dry-run" ]]; then
            echo
            echo -e "${CYAN}SHA512 check in progress...${RESET} $sha_file"
            if sha512_check "$sha_file"; then
                echo -e "${CYAN}SHA512 VERIFIED:${RESET} $sha_file"
            else
                echo -e "${YELLOW}SHA512 FAIL:${RESET} checksum mismatch for '$sha_file' (won't rename pair)"
                ((++files_skipped))
                processed["$sha_file"]=1
                continue
            fi

            echo -e "${RED}OLD SHA:${RESET} $sha_file"
            echo -e "${GREEN}NEW SHA:${RESET} $new_sha"
            for i in "${!refs[@]}"; do
                echo -e "${RED}OLD FILE:${RESET} ${refs[$i]}"
                echo -e "${GREEN}NEW FILE:${RESET} ${new_refs[$i]}"
            done
            echo "  (sha512 content will be updated to reference renamed file(s))"
            echo "----------------------------------------"

            ((++files_affected))
            record_rename "$sha_file" "$new_sha"
            for i in "${!refs[@]}"; do
                record_rename "${refs[$i]}" "${new_refs[$i]}"
            done

            processed["$sha_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        echo
        echo -e "${RED}OLD SHA:${RESET} $sha_file"
        echo -e "${GREEN}NEW SHA:${RESET} $new_sha"
        for i in "${!refs[@]}"; do
            echo -e "${RED}OLD FILE:${RESET} ${refs[$i]}"
            echo -e "${GREEN}NEW FILE:${RESET} ${new_refs[$i]}"
        done

        do_rename=no
        if [[ "$rename_all" == "yes" ]]; then
            do_rename=yes
        else
            echo -n "Rename this sha512 + referenced file(s)? [y/N/a/q]: "
            read -t 300 -n 1 input || true
            echo

            case "$input" in
                q|Q)
                    stopped_by_user=yes
                    break
                    ;;
                y|Y)
                    do_rename=yes
                    ;;
                a|A)
                    echo
                    echo "⚠️  This will rename ALL remaining files."
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
                    ((++files_skipped))
                    do_rename=no
                    ;;
            esac
        fi

        if [[ "$do_rename" != "yes" ]]; then
            processed["$sha_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        echo -e "${CYAN}SHA512 check (before rename) in progress...${RESET} $sha_file"
        if ! sha512_check "$sha_file"; then
            echo -e "${YELLOW}SHA512 FAIL:${RESET} checksum mismatch for '$sha_file' (won't rename pair)"
            ((++files_skipped))
            processed["$sha_file"]=1
            continue
        fi
        echo -e "${CYAN}SHA512 VERIFIED (before rename):${RESET} $sha_file"

        collision=no
        [[ "$new_sha" != "$sha_file" && -e "$new_sha" ]] && collision=yes
        for i in "${!refs[@]}"; do
            if is_excluded_path "${new_refs[$i]}"; then
                collision=yes
            fi
            [[ "${new_refs[$i]}" != "${refs[$i]}" && -e "${new_refs[$i]}" ]] && collision=yes
        done

        if [[ "$collision" == "yes" ]]; then
            echo -e "${YELLOW}SKIP:${RESET} Target file already exists or is excluded."
            ((++files_skipped))
            processed["$sha_file"]=1
            for ref in "${refs[@]}"; do processed["$ref"]=1; done
            continue
        fi

        for i in "${!refs[@]}"; do
            if [[ "${new_refs[$i]}" != "${refs[$i]}" ]]; then
                mv -i -- "${refs[$i]}" "${new_refs[$i]}"
                ((++files_affected))
                record_rename "${refs[$i]}" "${new_refs[$i]}"
            else
                ((++files_skipped))
            fi
        done

        for i in "${!refs[@]}"; do
            if [[ "${new_refs[$i]}" != "${refs[$i]}" ]]; then
                update_sha512_content_refs "$sha_file" "${refs[$i]}" "${new_refs[$i]}"
            fi
        done

        final_sha="$sha_file"
        if [[ "$new_sha" != "$sha_file" ]]; then
            mv -i -- "$sha_file" "$new_sha"
            ((++files_affected))
            record_rename "$sha_file" "$new_sha"
            final_sha="$new_sha"
        else
            ((++files_skipped))
        fi

        echo -e "${CYAN}SHA512 check (after rename) in progress...${RESET} $final_sha"
        if sha512_check "$final_sha"; then
            echo -e "${CYAN}SHA512 VERIFIED (after rename):${RESET} $final_sha"
        else
            echo -e "${YELLOW}SHA512 FAIL (after rename):${RESET} '$final_sha' does not validate."
            echo -e "${YELLOW}NOTE:${RESET} Files were renamed, but checksum verification after update failed."
            ((++files_skipped))
        fi

        processed["$sha_file"]=1
        processed["$final_sha"]=1
        for ref in "${refs[@]}"; do processed["$ref"]=1; done
        for ref in "${new_refs[@]}"; do processed["$ref"]=1; done

        continue
    fi

    # ------------------------------------------------------------
    # NORMAL FILES
    # ------------------------------------------------------------
    if [[ -d "$f" ]]; then
        ((++files_skipped))
        continue
    fi

    base="${f%.*}"
    if [[ -e "$base.sha512" ]]; then
        ((++files_skipped))
        continue
    fi

    new="$(transform_name "$f")"
    [[ "$f" == "$new" ]] && { ((++files_skipped)); continue; }

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
        if mv -i -- "$f" "$new"; then
            ((++files_affected))
            record_rename "$f" "$new"
        else
            ((++files_skipped))
        fi
        continue
    fi

    echo -n "Rename this file? [y/N/a/q]: "
    read -t 300 -n 1 input || true
    echo

    case "$input" in
        q|Q)
            stopped_by_user=yes
            break
            ;;
        y|Y)
            if mv -i -- "$f" "$new"; then
                ((++files_affected))
                record_rename "$f" "$new"
            else
                ((++files_skipped))
            fi
            ;;
        a|A)
            echo
            echo "⚠️  This will rename ALL remaining files."
            echo -n "Are you sure? [y/N]: "
            read -n 1 confirm || true
            echo

            if [[ "$confirm" =~ [Yy] ]]; then
                rename_all=yes
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
            ((++files_skipped))
            ;;
    esac
done

# ============================================================
# SUMMARY
# ============================================================
echo
echo "========= SUMMARY ========="
echo "Mode:                  $mode"
echo "Colors enabled:        $use_colors"
echo "Files examined:        $files_examined"
echo "Files affected:        $files_affected"
echo "Files skipped:         $files_skipped"
echo "Stopped by user:       $stopped_by_user"

if (( files_affected > 0 )); then
    echo
    echo "Affected files:"
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
