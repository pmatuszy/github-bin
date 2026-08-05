#!/bin/bash
# v. 20260805.182700 - Step 6 fails only on unresolved names; damage goes to repair step
# v. 20260803.213000 - prompt to repair when damage is fixable; --no-repair; verify after repair
# v. 20260803.073000 - rename prompt: single-key y/n/q; q quits multi-set run
# v. 20260803.072500 - after PAR2 rename re-verify Step 2; Step 6 must pass before OK
# v. 20260802.154500 - exclude misnamed targets from missing-file count/list
# v. 20260802.135100 - interactive prompts wait indefinitely by default (no timeout)
# v. 20260802.114532 - PROMPT_TIMEOUT default 900s (was 100s)
# v. 20260801.115737 - list missing PAR2 targets in summary and after final verify
# v. 20260731.205848 - report and skip *_old.par2 backup files from prior metadata updates
# v. 20260730.114155 - parse Target/perfect-match par2 lines for misnamed-file rename prompt
# v. 20260725.191229 - discover volume-only PAR2 sets when no index .par2 exists
# v. 20260721.154223 - fix ARG_MAX: chunk par2 verify; filter rename pairs; pairs-file
# v. 20260721.150446 - defer subtree scan to Step 3; progress msg; faster nested-set skip
# v. 20260721.144524 - recursive data scan; detect dir+file renames for par2 metadata fix
# v. 20260719.140918 - nicer PAR2 discovery summary; skip redundant single-set breakdown
# v. 20260719.134000 - --scope subdirs|current: discover PAR2 sets in directory tree
# v. 20260719.114307 - set-selection prompt: q/A single key, no Enter required
# v. 20260719.112833 - timing section: wall clock only; step durations outside
# v. 20260719.112526 - timing summary: add script start and end wall-clock times
# v. 20260719.105611 - batch rename default N; print Run settings block at startup
# v. 20260719.103506 - fix no-arg run: empty POSITIONAL[@]:- became one "" element
# v. 20260719.102800 - multi-set selection: A/a, ranges 1-4, --all, multiple paths

# 2026.08.05 - v. 0.1.37 - Rename step no longer fails on unrelated damage; detect "no data found"
# 2026.08.03 - v. 0.1.36 - Ask to repair damaged files; --no-repair; re-verify after repair
# 2026.08.03 - v. 0.1.35 - Rename prompt: single-key y/n/q; q quits run
# 2026.08.03 - v. 0.1.34 - Re-verify after PAR2 metadata rename; Step 6 must pass
# 2026.08.02 - v. 0.1.33 - Do not list misnamed PAR2 targets as missing files
# 2026.08.02 - v. 0.1.32 - Interactive prompts wait indefinitely unless PROMPT_TIMEOUT is set
# 2026.08.02 - v. 0.1.31 - Interactive prompt timeout default 900s (was 100s)
# 2026.08.01 - v. 0.1.30 - Print consolidated list of missing PAR2 target files
# 2026.07.31 - v. 0.1.29 - Report and skip *_old.par2 backups left from prior PAR2 metadata updates
# 2026.07.30 - v. 0.1.28 - Parse Target/perfect-match par2 lines; misnamed rename prompt
# 2026.07.25 - v. 0.1.27 - Discover PAR2 sets from volume files when index .par2 is missing
# 2026.07.21 - v. 0.1.26 - Fix ARG_MAX on large trees: chunk verify; filter/dedupe rename pairs
# 2026.07.21 - v. 0.1.25 - Defer data-file tree scan to Step 3; show progress on large trees
# 2026.07.21 - v. 0.1.24 - Step 3 scans subdirs; fix PAR2 paths after dir/file renames
# 2026.07.19 - v. 0.1.23 - Discovery summary: plain English, no lone "." line for 1 set
# 2026.07.19 - v. 0.1.22 - --scope subdirs|current; discover PAR2 sets under start directory
# 2026.07.19 - v. 0.1.21 - Set-selection q/A cancel/default without pressing Enter
# 2026.07.19 - v. 0.1.20 - Timing block: start/end/wall only; step durations separate
# 2026.07.19 - v. 0.1.19 - Timing block shows script start and end wall-clock times
# 2026.07.19 - v. 0.1.18 - Run settings banner; multi-set rename prompt defaults to no
# 2026.07.19 - v. 0.1.17 - Fix cwd-only run: drop POSITIONAL[@]:- reassign (empty-array trap)
# 2026.07.19 - v. 0.1.16 - Prompt or CLI-select multiple PAR2 sets; verify each in turn
# 2026.07.19 - v. 0.1.15 - PROMPT_TIMEOUT default 100s (was 20s)
# 2026.07.19 - v. 0.1.12 - Timing summary (hash/PAR2/total); renumber steps from 1 not 0
# 2026.07.19 - v. 0.1.11 - Suppress duplicate par2 OK line above RESULT banner
# 2026.07.19 - v. 0.1.10 - Scope summary: data/hash counts; list only in-scope hash manifests
# 2026.07.19 - v. 0.1.9 - Resolve PAR2 set from user path (volume ok); fix die-in-subshell fallback
# 2026.07.19 - v. 0.1.8 - Accept PAR2 volume/hash/data entry points; print detected files at start
# 2026.07.19 - v. 0.1.7 - Step/RESULT lines use boxes (Unicode fallback) for visibility on PuTTY
# 2026.07.19 - v. 0.1.6 - Step 0: scan all hash files; report how many list in-scope PAR2 entries
# 2026.07.19 - v. 0.1.5 - Step 0: verify only in-scope PAR2 set in hash file; skip if hash has no .par2 lines
# 2026.07.18 - v. 0.1.4 - Step 3b: keep active .par2 dates matching original *_old.par2 backups
# 2026.07.18 - v. 0.1.1 - github-bin consistency: show_help, print_version_banner, script footer
# 2026.07.18 - v. 0.1.0 - initial release: misnamed-file detection, hash gate, interactive PAR2 metadata update
#
# par2-pgm-check.sh
#
# Verify a PAR2 set and detect misnamed files in a directory.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay] [path] [directory] [options]

  [path] ...      One or more PAR2 index/volume paths (shell globs OK when unquoted)
  [directory]     Start directory (default: directory of [path] or cwd).
                  PAR2 sets are discovered per scope (--scope or interactive prompt).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
  --scope subdirs|current
                       subdirs: start directory and all subdirectories (default)
                       current: start directory only (no recursion)
  --all                Verify every discovered PAR2 index (no set-selection prompt).
  --repair             Repair damaged data without asking (also renames disk files)
  --no-repair          Report damage but never offer/run repair
  --yes, -y            Auto-yes for prompts (--all when many sets; auto-rename metadata)
  --no-rename          Detect misnamed files but do not offer/run PAR2 metadata update

Rename and repair prompts take one key: y, n, or q (q cancels the whole run).
Multi-set batch: both prompts default to no unless --yes / --repair is given.
Single set: both prompts default to yes.

Environment:
  PAR2_CMD             par2 executable (default: par2)
  PYTHON_CMD           python3 executable (default: python3)
  PROMPT_TIMEOUT       Seconds to wait for interactive prompts (unset = no timeout)

If a .sha512 / .sha256 / .md5 file exists in the directory, Step 1 scans all
hash manifests, reports how many list in-scope PAR2 archives for this set, and
verifies checksums only in those file(s). Other hash entries are ignored.

Step 3 scans data files in the PAR2 directory and its subdirectories (skipping
nested PAR2-set folders) to find content matches when paths on disk differ from
names stored inside the PAR2 set (including renamed subdirectories and files).

Examples:
  $(basename "$0")
  $(basename "$0") "_2015.07.19_-_kosciol,_Santa_Monica.par2"
  $(basename "$0") "archive.vol0+1.par2"
  $(basename "$0") "archive.sha512"
  $(basename "$0") "archive.par2" /path/to/files --yes
  $(basename "$0") /path/to/dir --all
  $(basename "$0") /path/to/dir --scope subdirs --all
  $(basename "$0") set1.par2 set2.par2 '202606*.par2'
EOF
}

pgm_arg_has_glob() {
    case $1 in
        *\**|*\?*|*\[*) return 0 ;;
    esac
    return 1
}

pgm_resolve_par2_index_path() {
    local input="$1"
    local ap base member mb idx=""
    local -a members=()

    RESOLVE_PAR2_ERROR=""
    PAR2_RESOLVED_FROM=""

    [[ -e "$input" ]] || {
        RESOLVE_PAR2_ERROR="PAR2 file not found: $input"
        return 1
    }

    ap="$(abs_path "$input")"
    base="$(basename "$ap")"
    if is_par2_backup_file "$base"; then
        RESOLVE_PAR2_ERROR="PAR2 backup file ignored (use the active .par2, not *_old.par2): $input"
        return 1
    fi
    if ! is_par2_any_active_file "$base"; then
        RESOLVE_PAR2_ERROR="Not a PAR2 file: $input"
        return 1
    fi

    collect_par2_set_for_ref_file "$ap" members

    for member in "${members[@]}"; do
        mb="$(basename "$member")"
        if is_par2_index_file "$mb"; then
            idx="$member"
            break
        fi
    done

    if [[ -z "$idx" ]]; then
        idx="$ap"
    fi

    idx="$(abs_path "$idx")"
    if [[ "$ap" != "$idx" ]]; then
        PAR2_RESOLVED_FROM="$ap"
    fi
    printf '%s\n' "$idx"
    return 0
}

pgm_queue_contains_par2_path() {
    local needle="$1"
    local existing

    needle="$(abs_path "$needle")"
    for existing in "${PAR2_SET_QUEUE[@]}"; do
        [[ "$(abs_path "$existing")" == "$needle" ]] && return 0
    done
    return 1
}

pgm_queue_add_par2_path() {
    local input="$1"
    local ap idx

    ap="$(abs_path "$input")"
    if ! idx="$(pgm_resolve_par2_index_path "$ap")"; then
        die "$RESOLVE_PAR2_ERROR"
    fi
    if pgm_queue_contains_par2_path "$idx"; then
        return 0
    fi
    PAR2_SET_QUEUE+=("$idx")
    USER_ARG_PATHS+=("$ap")
}

pgm_expand_glob_in_dir() {
    local pattern="$1"
    local dir="$2"
    local -n _out=$3
    local f

    _out=()
    shopt -s nullglob
    for f in "$dir"/$pattern; do
        [[ -f "$f" ]] || continue
        _out+=("$f")
    done
    shopt -u nullglob
}

# Discard keys typed by accident during a long verify. Only meaningful on a
# terminal: on a pipe or file this would swallow the answer itself.
pgm_flush_stdin() {
    local discard drained=0 max_drain=256

    [[ -t 0 ]] || return 0

    while (( drained < max_drain )) && IFS= read -r -t 0.02 -n 1 discard; do
        ((++drained))
    done
}

pgm_prompt_has_timeout() {
    [[ -n "${PROMPT_TIMEOUT:-}" && "${PROMPT_TIMEOUT}" =~ ^[1-9][0-9]*$ ]]
}

pgm_prompt_timeout_label() {
    if pgm_prompt_has_timeout; then
        printf '%ss timeout' "$PROMPT_TIMEOUT"
    else
        printf '%s' 'no timeout'
    fi
}

pgm_read_key_with_timeout() {
    local __var="$1"

    if pgm_prompt_has_timeout; then
        IFS= read -r -t "$PROMPT_TIMEOUT" -n 1 "$__var"
    else
        IFS= read -r -n 1 "$__var"
    fi
}

pgm_read_line_with_timeout() {
    local __var="$1"

    if pgm_prompt_has_timeout; then
        IFS= read -r -t "$PROMPT_TIMEOUT" "$__var"
    else
        IFS= read -r "$__var"
    fi
}

pgm_read_prompt_with_timeout() {
    local __var="$1"
    local __prompt="$2"

    if pgm_prompt_has_timeout; then
        read -t "$PROMPT_TIMEOUT" -r -p "$__prompt" "$__var"
    else
        read -r -p "$__prompt" "$__var"
    fi
}

# Read set-selection answer: q/A work on one key; numbers/ranges still use a line.
pgm_prompt_read_set_selection() {
    local max_n="$1"
    local -n _out_ans=$2
    local first="" rest=""

    printf 'Verify which set(s)? [A/1-%d/ranges like 1-4,q] (default: A, %s): ' \
        "$max_n" "$(pgm_prompt_timeout_label)"
    pgm_flush_stdin

    if ! pgm_read_key_with_timeout first; then
        _out_ans=A
        echo
        return 0
    fi

    case "$first" in
        ''|$'\n')
            _out_ans=A
            echo
            return 0
            ;;
        q|Q)
            _out_ans=q
            echo
            return 0
            ;;
        a|A)
            _out_ans=A
            echo
            return 0
            ;;
    esac

    if pgm_read_line_with_timeout rest; then
        _out_ans="${first}${rest}"
    else
        _out_ans="$first"
    fi
    echo
}

pgm_prompt_read_rename_choice() {
    pgm_prompt_read_yes_no_quit "$1" "$2" \
        "Update PAR2 archives with the new filenames?"
}

pgm_prompt_read_repair_choice() {
    pgm_prompt_read_yes_no_quit "$1" "$2" \
        "Repair damaged file(s) with par2 now?"
}

# Answer on one key (Enter = default); q quits the script. Sets 0=yes, 1=no, 2=quit.
pgm_prompt_read_yes_no_quit() {
    local default_yes="$1"
    local -n _out=$2
    local question="$3"
    local key="" rest=""

    if (( default_yes )); then
        printf '%s [Y/n/q] (%s): ' "$question" "$(pgm_prompt_timeout_label)"
    else
        printf '%s [y/N/q] (%s): ' "$question" "$(pgm_prompt_timeout_label)"
    fi
    pgm_flush_stdin

    if ! pgm_read_key_with_timeout key; then
        _out=$(( default_yes ? 0 : 1 ))
        echo
        return 0
    fi

    case "$key" in
        ''|$'\n')
            _out=$(( default_yes ? 0 : 1 ))
            echo
            return 0
            ;;
        q|Q)
            _out=2
            echo
            return 0
            ;;
        y|Y)
            _out=0
            echo
            return 0
            ;;
        n|N)
            _out=1
            echo
            return 0
            ;;
    esac

    if pgm_read_line_with_timeout rest; then
        case "${key}${rest}" in
            y|Y|yes|YES) _out=0 ;;
            n|N|no|NO) _out=1 ;;
            q|Q) _out=2 ;;
            *) _out=$(( default_yes ? 0 : 1 )) ;;
        esac
    else
        _out=$(( default_yes ? 0 : 1 ))
    fi
    echo
}

pgm_parse_set_selection() {
    local selection="$1"
    local max_n="$2"
    local -n _out=$3
    local token a b i
    local -A seen=()

    _out=()
    selection="${selection// /}"
    [[ -z "$selection" ]] && selection="a"

    if [[ "${selection,,}" == "a" ]]; then
        for ((i = 1; i <= max_n; i++)); do
            _out+=("$i")
        done
        return 0
    fi
    if [[ "${selection,,}" == "q" ]]; then
        return 2
    fi

    selection="${selection//,/ }"
    for token in $selection; do
        if [[ "$token" =~ ^([0-9]+)-([0-9]+)$ ]]; then
            a=${BASH_REMATCH[1]}
            b=${BASH_REMATCH[2]}
            if (( a > b )); then
                i=$a
                a=$b
                b=$i
            fi
            for ((i = a; i <= b; i++)); do
                (( i >= 1 && i <= max_n )) || die "Selection out of range: $i (max $max_n)"
                [[ -n "${seen[$i]:-}" ]] && continue
                seen[$i]=1
                _out+=("$i")
            done
        elif [[ "$token" =~ ^[0-9]+$ ]]; then
            i=$token
            (( i >= 1 && i <= max_n )) || die "Selection out of range: $i (max $max_n)"
            [[ -n "${seen[$i]:-}" ]] && continue
            seen[$i]=1
            _out+=("$i")
        else
            die "Invalid selection: '$token' (use A/a, 1-4, 7, or q)"
        fi
    done

    ((${#_out[@]} > 0)) || die "No PAR2 sets selected."
    return 0
}

pgm_prompt_select_par2_sets() {
    local -n _indices=$1
    local -a picks=()
    local ans i pick_rc display

    ((${#_indices[@]} > 0)) || return 1

    if (( VERIFY_ALL_SETS )); then
        PAR2_SET_QUEUE=("${_indices[@]}")
        return 0
    fi

    echo
    echo "  [A] Verify all ${#_indices[@]} sets (one after another)"
    for i in "${!_indices[@]}"; do
        display="$(pgm_path_display_relative "${_indices[$i]}" "$START_DIR")"
        printf '  [%d] %s\n' "$((i + 1))" "$display"
    done
    echo
    pgm_prompt_read_set_selection "${#_indices[@]}" ans
    [[ -z "$ans" ]] && ans=A

    pgm_parse_set_selection "$ans" "${#_indices[@]}" picks
    pick_rc=$?
    if (( pick_rc == 2 )); then
        echo "Cancelled."
        return_code=0
        finish
    fi

    PAR2_SET_QUEUE=()
    for i in "${picks[@]}"; do
        PAR2_SET_QUEUE+=("${_indices[$((i - 1))]}")
    done
}

pgm_prepare_par2_set() {
    local entry_path="$1"
    local ap idx

    ap="$(abs_path "$entry_path")"
    if ! idx="$(pgm_resolve_par2_index_path "$ap")"; then
        die "$RESOLVE_PAR2_ERROR"
    fi
    PAR2_FILE="$idx"
    DATA_DIR="$(dirname "$PAR2_FILE")"
    collect_par2_set_for_ref_file "${PAR2_RESOLVED_FROM:-$PAR2_FILE}" PAR2_SET_MEMBERS
}

pgm_print_multi_set_banner() {
    local n="$1"
    local total="$2"
    local name="$3"
    local dir="$4"

    echo
    printf '================================================================\n'
    printf 'PAR2 set %d/%d: %s\n' "$n" "$total" "$name"
    printf 'Directory:     %s\n' "$dir"
    printf '================================================================\n'
}

pgm_record_multi_set_result() {
    local rc="$1"
    local name="$2"

    MULTI_SET_TOTAL=$((MULTI_SET_TOTAL + 1))
    case "$rc" in
        0) MULTI_SET_OK=$((MULTI_SET_OK + 1)) ;;
        3) MULTI_SET_FAIL=$((MULTI_SET_FAIL + 1)); MULTI_SET_FAILED_NAMES+=("$name") ;;
        *) MULTI_SET_WARN=$((MULTI_SET_WARN + 1)); MULTI_SET_FAILED_NAMES+=("$name") ;;
    esac
    (( rc > MULTI_SET_WORST_RC )) && MULTI_SET_WORST_RC=$rc
}

pgm_print_multi_set_summary() {
    echo
    echo "=== Multi-set summary ==="
    printf '  Sets checked: %d\n' "$MULTI_SET_TOTAL"
    printf '  OK:           %d\n' "$MULTI_SET_OK"
    if (( MULTI_SET_WARN > 0 )); then
        printf '  WARN:         %d\n' "$MULTI_SET_WARN"
    fi
    if (( MULTI_SET_FAIL > 0 )); then
        printf '  FAIL:         %d\n' "$MULTI_SET_FAIL"
    fi
    if ((${#MULTI_SET_FAILED_NAMES[@]} > 0)); then
        echo "  Problem set(s):"
        local name
        for name in "${MULTI_SET_FAILED_NAMES[@]}"; do
            printf '    - %s\n' "$name"
        done
    fi
    echo
}

pgm_print_run_settings() {
    local n_sets="${#PAR2_SET_QUEUE[@]}"
    local rename_effect

    echo "=== Run settings ==="

    if (( AUTO_RENAME )); then
        echo "  -y/--yes:     given (all sets when unset; auto-rename when misnamed)"
    elif (( VERIFY_ALL_SETS )); then
        echo "  --all:        given (verify every PAR2 set; no selection prompt)"
        echo "  -y/--yes:     not given"
    else
        echo "  --all / -y:   not given (interactive set selection when multiple sets)"
    fi

    if (( NO_RENAME )); then
        echo "  --no-rename:  given (report misnamed files only; never update PAR2)"
    else
        echo "  --no-rename:  not given"
    fi

    if (( REPAIR )); then
        echo "  --repair:     given (repair damaged files without asking)"
    elif (( NO_REPAIR )); then
        echo "  --no-repair:  given (report damage only; never repair)"
    else
        echo "  --repair:     not given (prompt when repair is possible)"
    fi

    if (( NO_RENAME )); then
        rename_effect="skipped (--no-rename)"
    elif (( AUTO_RENAME )); then
        rename_effect="automatic (--yes)"
    elif (( n_sets > 1 )) || (( VERIFY_ALL_SETS && n_sets == 0 )); then
        rename_effect="prompt per problem set; default no ($(pgm_prompt_timeout_label), batch)"
    elif (( n_sets == 1 )); then
        rename_effect="prompt if needed; default yes ($(pgm_prompt_timeout_label), single set)"
    else
        rename_effect="prompt if needed; default yes (single) / no (batch), $(pgm_prompt_timeout_label)"
    fi
    printf '  Rename:       %s\n' "$rename_effect"

    if (( n_sets > 0 )); then
        printf '  Sets queued:  %d from command line\n' "$n_sets"
    fi

    if ((${#PAR2_SET_QUEUE[@]} > 0)); then
        echo "  Scope:        not used (PAR2 set(s) specified on command line)"
    elif [[ -n "$CLI_SCOPE" ]]; then
        if [[ "$CHECK_SCOPE" == "subdirs" ]]; then
            echo "  --scope:      given (subdirs — search tree under start directory)"
        else
            echo "  --scope:      given (current — start directory only)"
        fi
    else
        printf '  --scope:      not given (prompted; selected: %s)\n' "$CHECK_SCOPE"
    fi
    if [[ "$CHECK_SCOPE" == "subdirs" ]]; then
        echo "  Search:       start directory and all subdirectories"
    else
        echo "  Search:       start directory only (no subdirectories)"
    fi
    printf '  Start dir:    %s\n' "$START_DIR"
    echo
}

pgm_path_display_relative() {
    local path="$1"
    local root="$2"
    local ap rp rel

    ap="$(abs_path "$path")"
    rp="$(abs_path "$root")"
    if [[ "$ap" == "$rp" ]]; then
        printf '.'
        return 0
    fi
    if [[ "$ap" == "$rp"/* ]]; then
        rel="${ap#"$rp"/}"
        printf '%s' "$rel"
        return 0
    fi
    printf '%s' "$ap"
}

pgm_par2_set_key() {
    local f="$1"
    printf '%s|%s' "$(abs_path "$(dirname "$f")")" "$(par2_stem_from_par2_basename "$(basename "$f")")"
}

pgm_find_par2_indices_scoped() {
    local root="$1"
    local scope="$2"
    local -n _out=$3
    local f base
    local -a find_args=() all_par2=()
    local -A queued_sets=()

    _out=()
    if [[ "$scope" == "current" ]]; then
        find_args=(find "$root" -mindepth 1 -maxdepth 1)
    else
        find_args=(find "$root")
    fi

    while IFS= read -r -d '' f; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        is_par2_any_active_file "$base" || continue
        all_par2+=("$(abs_path "$f")")
    done < <("${find_args[@]}" \( -iname '*.par2' \) -type f -print0 2>/dev/null)

    for f in "${all_par2[@]}"; do
        base="$(basename "$f")"
        is_par2_index_file "$base" || continue
        _out+=("$f")
        queued_sets["$(pgm_par2_set_key "$f")"]=1
    done

    for f in "${all_par2[@]}"; do
        base="$(basename "$f")"
        is_par2_volume_file "$base" || continue
        [[ -n "${queued_sets[$(pgm_par2_set_key "$f")]:-}" ]] && continue
        queued_sets["$(pgm_par2_set_key "$f")"]=1
        _out+=("$f")
    done

    pgm_sort_path_array _out
}

pgm_print_par2_discovery_summary() {
    local -n _indices=$1
    local -A dir_counts=()
    local idx dir count n_dirs n_sets rel dir_rel display
    local -a sorted_dirs=()
    local start_ap d_ap

    n_sets=${#_indices[@]}
    start_ap="$(abs_path "$START_DIR")"

    for idx in "${_indices[@]}"; do
        dir="$(dirname "$idx")"
        dir_counts["$dir"]=$(( ${dir_counts["$dir"]:-0} + 1 ))
    done
    n_dirs=${#dir_counts[@]}

    if [[ "$CHECK_SCOPE" == "subdirs" ]]; then
        echo "Discovering PAR2 sets under $START_DIR (scope: subdirs; can take time on large trees)..."
    else
        echo "Discovering PAR2 sets in $START_DIR (scope: current directory only)..."
    fi

    if (( n_sets == 1 )); then
        d_ap="$(abs_path "$(dirname "${_indices[0]}")")"
        display="$(pgm_path_display_relative "${_indices[0]}" "$START_DIR")"
        if [[ "$d_ap" == "$start_ap" ]]; then
            echo "Found 1 PAR2 set in the start directory:"
        else
            dir_rel="$(pgm_path_display_relative "$d_ap" "$START_DIR")"
            echo "Found 1 PAR2 set in subdirectory ${dir_rel}/:"
        fi
        printf '  %s\n' "$display"
        echo
        return 0
    fi

    if (( n_dirs == 1 )); then
        d_ap="$(abs_path "$(dirname "${_indices[0]}")")"
        if [[ "$d_ap" == "$start_ap" ]]; then
            echo "Found ${n_sets} PAR2 sets in the start directory."
        else
            echo "Found ${n_sets} PAR2 sets in 1 subdirectory."
        fi
    else
        echo "Found ${n_sets} PAR2 sets in ${n_dirs} directories."
    fi
    echo
    echo "By directory:"

    mapfile -t sorted_dirs < <(printf '%s\n' "${!dir_counts[@]}" | LC_ALL=C sort)
    for d in "${sorted_dirs[@]}"; do
        count="${dir_counts[$d]}"
        d_ap="$(abs_path "$d")"
        if [[ "$d_ap" == "$start_ap" ]]; then
            rel="(start directory)"
        else
            rel="$(pgm_path_display_relative "$d" "$START_DIR")/"
        fi
        if (( count == 1 )); then
            printf '  %-40s 1 set\n' "$rel"
        else
            printf '  %-40s %d sets\n' "$rel" "$count"
        fi
    done
    echo
}

pgm_resolve_check_scope() {
    local input=""

    if [[ -n "$CLI_SCOPE" ]]; then
        CHECK_SCOPE="$CLI_SCOPE"
        return 0
    fi

    echo
    echo "What should be searched for PAR2 sets?"
    echo "  [S] Also subdirectories (default)"
    echo "  [C] Current directory only"
    echo "  [Q] Quit"
    printf 'Choice [S/c/q]: '
    pgm_flush_stdin
    if ! pgm_read_key_with_timeout input; then
        input=S
    fi
    echo
    case "$input" in
        c|C) CHECK_SCOPE=current ;;
        q|Q) echo "Cancelled."; return_code=0; finish ;;
        *) CHECK_SCOPE=subdirs ;;
    esac
    echo "Scope selected: $CHECK_SCOPE"
}

pgm_find_old_par2_backups_scoped() {
    local root="$1"
    local scope="$2"
    local -n _out=$3
    local f base
    local -a find_args=()

    _out=()
    if [[ "$scope" == "current" ]]; then
        find_args=(find "$root" -mindepth 1 -maxdepth 1)
    else
        find_args=(find "$root")
    fi

    while IFS= read -r -d '' f; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        is_par2_backup_file "$base" || continue
        _out+=("$(abs_path "$f")")
    done < <("${find_args[@]}" \( -iname '*_old.par2' \) -type f -print0 2>/dev/null)

    pgm_sort_path_array _out
}

pgm_report_skipped_old_par2_backups() {
    local -a backups=()
    local scope_label rel i

    pgm_find_old_par2_backups_scoped "$START_DIR" "${CHECK_SCOPE:-subdirs}" backups
    ((${#backups[@]} > 0)) || return 0

    if [[ "${CHECK_SCOPE:-subdirs}" == "current" ]]; then
        scope_label="in $START_DIR"
    else
        scope_label="under $START_DIR (including subdirectories)"
    fi

    echo
    echo "Found ${#backups[@]} *_old.par2 backup file(s) ${scope_label}."
    echo "Skipping them (leftovers from prior PAR2 metadata updates; not part of the active set)."
    if ((${#backups[@]} <= 8)); then
        for i in "${backups[@]}"; do
            rel="$(pgm_path_display_relative "$i" "$START_DIR")"
            printf '  %s\n' "$rel"
        done
    else
        for i in "${backups[@]:0:5}"; do
            rel="$(pgm_path_display_relative "$i" "$START_DIR")"
            printf '  %s\n' "$rel"
        done
        echo "  ... and $((${#backups[@]} - 5)) more"
    fi
    echo
}

pgm_discover_and_queue_par2_sets() {
    local -a indices=()

    pgm_find_par2_indices_scoped "$START_DIR" "$CHECK_SCOPE" indices
    ((${#indices[@]} > 0)) || die "No PAR2 sets found under $START_DIR (scope: $CHECK_SCOPE)."

    pgm_print_par2_discovery_summary indices

    if ((${#indices[@]} == 1)); then
        PAR2_SET_QUEUE=("${indices[0]}")
        return 0
    fi

    pgm_prompt_select_par2_sets indices
}

pgm_resolve_rename_py() {
    local hint="${1:-.}"

    if [[ -f "$hint/par2-pgm-rename.py" ]]; then
        RENAME_PY="$(abs_path "$hint/par2-pgm-rename.py")"
    elif [[ -f "$(dirname "${BASH_SOURCE[0]}")/par2-pgm-rename.py" ]]; then
        RENAME_PY="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/par2-pgm-rename.py"
    elif command -v par2-pgm-rename.py >/dev/null 2>&1; then
        RENAME_PY="$(command -v par2-pgm-rename.py)"
    else
        die "par2-pgm-rename.py not found in PATH, script directory, or: $hint"
    fi
}

is_par2_volume_file() {
    local base="$1"
    [[ "$base" =~ \.vol[0-9]*[-+_][0-9]+\.par2$ ]] || [[ "$base" =~ \.vol[0-9]*[-+_][0-9]+\.PAR2$ ]]
}

is_par2_backup_file() {
    local base="$1"
    case "$base" in
        *_old.par2|*_old.PAR2) return 0 ;;
    esac
    return 1
}

is_par2_any_active_file() {
    local base="$1"
    [[ "$base" == *.par2 || "$base" == *.PAR2 ]] || return 1
    is_par2_backup_file "$base" && return 1
    return 0
}

is_hash_manifest_file() {
    local base="$1"
    case "$base" in
        *.sha512|*.SHA512|*.sha256|*.SHA256|*.md5|*.MD5) return 0 ;;
    esac
    return 1
}

is_data_file_basename() {
    local base="$1"
    case "$base" in
        *.par2|*.PAR2) return 1 ;;
        *_old.par2|*_old.PAR2) return 1 ;;
        *.sha512|*.SHA512|*.sha256|*.SHA256|*.md5|*.MD5) return 1 ;;
        par2-pgm-check.sh|par2-pgm-rename.py) return 1 ;;
    esac
    return 0
}

par2_stem_from_par2_basename() {
    local base="$1"
    base="${base%.par2}"
    base="${base%.PAR2}"
    if [[ "$base" == *_old ]]; then
        base="${base%_old}"
    fi
    if is_par2_volume_file "$1"; then
        base="$(sed -E 's/\.vol[0-9]*[-+_][0-9]+$//' <<< "$base")"
    fi
    printf '%s' "$base"
}

is_par2_index_file() {
    local base="$1"
    [[ "$base" == *.par2 || "$base" == *.PAR2 ]] || return 1
    is_par2_backup_file "$base" && return 1
    [[ "$base" =~ \.vol[0-9]*[-+_][0-9]+\.par2$ ]] && return 1
    return 0
}

find_par2_index_in_dir() {
    local dir="$1"
    local f base
    local -a candidates=()

    shopt -s nullglob
    for f in "$dir"/*.par2 "$dir"/*.PAR2; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        is_par2_index_file "$base" || continue
        candidates+=("$f")
    done
    shopt -u nullglob

    if (( ${#candidates[@]} == 1 )); then
        printf '%s\n' "${candidates[0]}"
        return 0
    fi
    if (( ${#candidates[@]} == 0 )); then
        return 1
    fi

    echo "Multiple PAR2 index files found in $dir - specify which one to use:" >&2
    printf '  %s\n' "${candidates[@]}" >&2
    return 2
}

find_all_par2_index_files() {
    local dir="$1"
    local -n _out=$2
    local f base

    _out=()
    shopt -s nullglob
    for f in "$dir"/*.par2 "$dir"/*.PAR2; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        is_par2_index_file "$base" || continue
        _out+=("$(abs_path "$f")")
    done
    shopt -u nullglob

    if (( ${#_out[@]} > 1 )); then
        IFS=$'\n' _out=($(printf '%s\n' "${_out[@]}" | LC_ALL=C sort -f))
        unset IFS
    fi
}

par2_stems_match() {
    [[ "${1,,}" == "${2,,}" ]]
}

pgm_sort_path_array() {
    local -n _arr=$1

    if (( ${#_arr[@]} > 1 )); then
        IFS=$'\n' _arr=($(printf '%s\n' "${_arr[@]}" | LC_ALL=C sort -f))
        unset IFS
    fi
}

collect_par2_set_for_ref_file() {
    local ref="$1"
    local -n _out=$2
    local ap dir base stem f fb fstem

    _out=()
    ap="$(abs_path "$ref")"
    dir="$(dirname "$ap")"
    base="$(basename "$ap")"
    stem="$(par2_stem_from_par2_basename "$base")"

    shopt -s nullglob
    for f in "$dir"/*.par2 "$dir"/*.PAR2; do
        [[ -f "$f" ]] || continue
        fb="$(basename "$f")"
        is_par2_backup_file "$fb" && continue
        fstem="$(par2_stem_from_par2_basename "$fb")"
        if par2_stems_match "$stem" "$fstem"; then
            _out+=("$(abs_path "$f")")
        fi
    done
    shopt -u nullglob

    if (( ${#_out[@]} == 0 )); then
        _out+=("$ap")
    fi

    pgm_sort_path_array _out
}

list_par2_set_members() {
    local dir="$1"
    local stem="$2"
    local -n _members=$3
    local f base fstem

    _members=()
    shopt -s nullglob
    for f in "$dir"/*.par2 "$dir"/*.PAR2; do
        [[ -f "$f" ]] || continue
        base="$(basename "$f")"
        is_par2_backup_file "$base" && continue
        fstem="$(par2_stem_from_par2_basename "$base")"
        if par2_stems_match "$stem" "$fstem"; then
            _members+=("$(abs_path "$f")")
        fi
    done
    shopt -u nullglob

    pgm_sort_path_array _members
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

PAR2_CMD="${PAR2_CMD:-par2}"
PYTHON_CMD="${PYTHON_CMD:-python3}"
REPAIR=0
NO_REPAIR=0
AUTO_RENAME=0
NO_RENAME=0
POSITIONAL=()
MISNAMED_DISK=()
MISNAMED_PAR2=()
MISSING_PAR2_TARGETS=()
DAMAGED_PAR2_TARGETS=()
REPAIR_POSSIBLE=0
PGM_POST_RENAME_OUT=""
RENAME_PAIRS=()
OUT2_FILE=""
RENAME_PY=""
PAR2_FILE=""
DATA_DIR=""
PAR2_RESOLVED_FROM=""
USER_DIR_INPUT=""
USER_HASH_INPUT=""
USER_DATA_INPUT=""
USER_ARG_PATHS=()
PAR2_SET_QUEUE=()
DEFERRED_GLOB_ARGS=()
VERIFY_ALL_SETS=0
MULTI_SET_MODE=0
MULTI_SET_TOTAL=0
MULTI_SET_OK=0
MULTI_SET_WARN=0
MULTI_SET_FAIL=0
MULTI_SET_WORST_RC=0
MULTI_SET_FAILED_NAMES=()
PAR2_SET_MEMBERS=()
RESOLVE_PAR2_ERROR=""
PGM_HASH_VERIFY_MSG=""
PROMPT_TIMEOUT="${PROMPT_TIMEOUT-}"
PGM_PAR2_ARG_BATCH="${PGM_PAR2_ARG_BATCH:-2000}"
PGM_RENAME_BATCH="${PGM_RENAME_BATCH:-16}"
PGM_SCRIPT_START_STR=""
START_DIR=""
CLI_SCOPE=""
CHECK_SCOPE=subdirs

cleanup() {
    [[ -n "$OUT2_FILE" && -f "$OUT2_FILE" ]] && rm -f "$OUT2_FILE"
}
trap cleanup EXIT

die() {
    echo "Error: $*" >&2
    return_code=1
    . /root/bin/_script_footer.sh
    exit 1
}

finish() {
    local rc="${return_code:-0}"
    if (( MULTI_SET_MODE )); then
        pgm_print_multi_set_summary
    fi
    pgm_print_timing_summary
    . /root/bin/_script_footer.sh
    exit "$rc"
}

PGM_HAVE_BOXES=no
if command -v boxes >/dev/null 2>&1; then
    PGM_HAVE_BOXES=yes
fi

pgm_emit_unicode_box() {
    local -a lines=( "$@" )
    local max_len=0 line w

    for line in "${lines[@]}"; do
        (( ${#line} > max_len )) && max_len=${#line}
    done
    (( max_len < 52 )) && max_len=52
    w=$(( max_len + 2 ))

    printf '┌%*s┐\n' "$w" '' | tr ' ' '─'
    for line in "${lines[@]}"; do
        printf '│ %-*s │\n' "$max_len" "$line"
    done
    printf '└%*s┘\n' "$w" '' | tr ' ' '─'
}

pgm_emit_boxed_block() {
    local design="$1"
    shift
    local -a lines=( "$@" )

    if [[ "$PGM_HAVE_BOXES" == yes ]]; then
        printf '%s\n' "${lines[@]}" | boxes -a c -d "$design"
    else
        pgm_emit_unicode_box "${lines[@]}"
    fi
}

pgm_print_step_header() {
    local title="$1"
    echo
    pgm_emit_boxed_block stone "$title"
}

pgm_outcome_header_for_kind() {
    case "$1" in
        ok)   printf '%s' '*** RESULT: OK ***' ;;
        warn) printf '%s' '*** RESULT: ATTENTION NEEDED ***' ;;
        err)  printf '%s' '*** RESULT: PROBLEM ***' ;;
        *)    printf '%s' '*** RESULT ***' ;;
    esac
}

pgm_print_outcome() {
    local kind="$1"
    shift
    local -a body=( "$@" )
    local -a lines
    local design=stone

    lines=( "$(pgm_outcome_header_for_kind "$kind")" )
    lines+=( "${body[@]}" )

    case "$kind" in
        ok) design=ada-box ;;
    esac

    echo
    pgm_emit_boxed_block "$design" "${lines[@]}"
    echo
}

pgm_par2_output_indicates_ok() {
    grep -qiE 'repair is not required|all files are (ok|correct)' <<< "$1"
}

pgm_extract_par2_ok_line() {
    grep -iE 'repair is not required|all files are (ok|correct)' <<< "$1" \
        | head -n 1 \
        | sed -E 's/^[[:space:]]+//;s/[[:space:]]+$//'
}

pgm_filter_par2_verify_output() {
    local text="$1"
    sed -E '/^[[:space:]]*[Aa]ll files are (ok|correct).*repair is not required\.?[[:space:]]*$/Id' <<< "$text" \
        | sed -E -e :a -e '/^\s*$/{$d;N;ba' -e '}'
}

pgm_filter_par2_verify_stream() {
    sed -E '/^[[:space:]]*[Aa]ll files are (ok|correct).*repair is not required\.?[[:space:]]*$/Id'
}

pgm_wall_clock_now() {
    date '+%Y.%m.%d %H:%M:%S'
}

pgm_format_elapsed() {
    local s="${1:-0}" h m
    (( s < 0 )) && s=0
    h=$(( s / 3600 )); s=$(( s % 3600 ))
    m=$(( s / 60 )); s=$(( s % 60 ))
    if (( h > 0 )); then
        printf '%dh %dm %ds' "$h" "$m" "$s"
    elif (( m > 0 )); then
        printf '%dm %ds' "$m" "$s"
    else
        printf '%ds' "$s"
    fi
}

pgm_print_step_verdict() {
    local step="$1"
    local kind="$2"
    shift 2

    printf 'Step %s — %-6s%s\n' "$step" "${kind}:" "$*"
}

pgm_print_step1_verdict_from_msg() {
    local msg="$1"
    local ok_line

    if grep -qi 'Skipping PAR2 archive checksum verification' <<< "$msg"; then
        if grep -qi 'No .sha512 / .sha256 / .md5 hash file found' <<< "$msg"; then
            pgm_print_step_verdict 1 SKIP "No hash files in directory; checksum step not run."
        elif grep -qi 'no hash file lists any in-scope PAR2 archive' <<< "$msg"; then
            pgm_print_step_verdict 1 SKIP "No in-scope hash manifests for this PAR2 set."
        elif grep -qi 'no hash file in this directory contains .par2 entries' <<< "$msg"; then
            pgm_print_step_verdict 1 SKIP "No hash files list PAR2 entries; checksum step not run."
        else
            pgm_print_step_verdict 1 SKIP "PAR2 archive checksum verification skipped."
        fi
        return 0
    fi

    ok_line=$(grep 'PAR2 archive checksums OK:' <<< "$msg" | head -n 1 || true)
    if [[ -n "$ok_line" ]]; then
        if [[ "$ok_line" =~ ([0-9]+)\ in-scope\ PAR2\ file\(s\)\ match\ across\ ([0-9]+)\ hash ]]; then
            pgm_print_step_verdict 1 OK \
                "PAR2 archive checksums verified (${BASH_REMATCH[1]} in-scope file(s), ${BASH_REMATCH[2]} hash file(s))."
        else
            pgm_print_step_verdict 1 OK "${ok_line#PAR2 archive checksums OK: }"
        fi
    fi
}

pgm_timing_lap_to() {
    local var_name="$1"
    local now=$SECONDS

    printf -v "$var_name" '%s' "$(( now - PGM_TIMING_LAST ))"
    PGM_TIMING_LAST=$now
}

pgm_print_timing_summary() {
    local total=0 end_time wall_time
    local -a labels=() values=() formatted=()
    local i max_w=0 w

    end_time="$(pgm_wall_clock_now)"

    if (( MULTI_SET_MODE )); then
        [[ -n "${PGM_MULTI_RUN_START:-}" ]] || return 0
        total=$(( SECONDS - PGM_MULTI_RUN_START ))
        wall_time="$(pgm_format_elapsed "$total")"

        echo
        echo "--- Timing (all sets) ---"
        [[ -n "${PGM_SCRIPT_START_STR:-}" ]] && \
            printf '  %-28s %s\n' "Start time:" "$PGM_SCRIPT_START_STR"
        printf '  %-28s %s\n' "End time:" "$end_time"
        printf '  %-28s %s\n' "Total wall time:" "$wall_time"
        echo
        printf '  %-28s %d\n' "Sets checked:" "$MULTI_SET_TOTAL"
        echo
        return 0
    fi

    [[ -n "${PGM_RUN_START:-}" ]] || return 0
    total=$(( SECONDS - PGM_RUN_START ))
    wall_time="$(pgm_format_elapsed "$total")"

    labels+=("Hash checksum check:")
    values+=("${PGM_TIMING_HASH_SEC:-0}")

    if (( ${PGM_TIMING_PAR2_SCAN_SEC:-0} > 0 )); then
        labels+=("PAR2 verify (names only):")
        values+=("${PGM_TIMING_PAR2_NAMES_SEC:-0}")
        labels+=("PAR2 verify (dir scan):")
        values+=("${PGM_TIMING_PAR2_SCAN_SEC:-0}")
    else
        labels+=("PAR2 verify:")
        values+=("${PGM_TIMING_PAR2_NAMES_SEC:-0}")
    fi

    for i in "${!values[@]}"; do
        formatted[i]="$(pgm_format_elapsed "${values[$i]}")"
        w=${#formatted[$i]}
        (( w > max_w )) && max_w=$w
    done

    echo
    echo "--- Timing ---"
    [[ -n "${PGM_SCRIPT_START_STR:-}" ]] && \
        printf '  %-28s %s\n' "Start time:" "$PGM_SCRIPT_START_STR"
    printf '  %-28s %s\n' "End time:" "$end_time"
    printf '  %-28s %s\n' "Total wall time:" "$wall_time"
    echo
    echo "--- Step durations ---"
    for i in "${!labels[@]}"; do
        printf '  %-28s %*s\n' "${labels[$i]}" "$max_w" "${formatted[$i]}"
    done
    echo
}

pgm_describe_path_kind() {
    local path="$1"
    local base

    if [[ -d "$path" ]]; then
        printf '%s' 'directory'
        return 0
    fi

    base="$(basename "$path")"
    if is_hash_manifest_file "$base"; then
        printf '%s' 'hash manifest'
    elif is_par2_index_file "$base"; then
        printf '%s' 'PAR2 index'
    elif is_par2_volume_file "$base"; then
        printf '%s' 'PAR2 volume'
    elif is_par2_any_active_file "$base"; then
        printf '%s' 'PAR2 file'
    else
        printf '%s' 'data file'
    fi
}

apply_file_argument() {
    local arg="$1"
    local ap base

    [[ -e "$arg" ]] || die "Path not found: $arg"
    ap="$(abs_path "$arg")"
    base="$(basename "$ap")"

    USER_ARG_PATHS+=("$ap")

    if is_hash_manifest_file "$base"; then
        [[ -z "$USER_HASH_INPUT" ]] || die "Multiple hash files specified: $arg"
        USER_HASH_INPUT="$ap"
        return 0
    fi

    if is_par2_backup_file "$base"; then
        die "PAR2 backup file ignored (use the active .par2, not *_old.par2): $base"
    fi

    if is_par2_any_active_file "$base"; then
        pgm_queue_add_par2_path "$ap"
        return 0
    fi

    if is_data_file_basename "$base"; then
        [[ -z "$USER_DATA_INPUT" ]] || die "Multiple data files specified as entry point: $arg"
        USER_DATA_INPUT="$ap"
        return 0
    fi

    die "Unrecognized file type (expected PAR2, hash manifest, or data file): $base"
}

infer_data_dir_from_inputs() {
    if [[ -n "$USER_DIR_INPUT" ]]; then
        printf '%s\n' "$USER_DIR_INPUT"
        return 0
    fi
    if ((${#PAR2_SET_QUEUE[@]} > 0)); then
        dirname "${PAR2_SET_QUEUE[0]}"
        return 0
    fi
    if [[ -n "$USER_HASH_INPUT" ]]; then
        dirname "$USER_HASH_INPUT"
        return 0
    fi
    if [[ -n "$USER_DATA_INPUT" ]]; then
        dirname "$USER_DATA_INPUT"
        return 0
    fi
    abs_path "."
}

resolve_par2_from_user_input() {
    local input="$1"
    local idx

    if ! idx="$(pgm_resolve_par2_index_path "$input")"; then
        return 1
    fi
    PAR2_FILE="$idx"
    collect_par2_set_for_ref_file "${PAR2_RESOLVED_FROM:-$PAR2_FILE}" PAR2_SET_MEMBERS
    return 0
}

pgm_path_in_array() {
    local needle="$1"
    local -n _haystack=$2
    local item

    for item in "${_haystack[@]}"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

pgm_load_hash_inventory() {
    local msg rc=0
    local -a lines=()

    HASH_INV_TOTAL=0
    HASH_INV_WITH_PAR2=0
    HASH_INV_IN_SCOPE=0
    HASH_INV_RELEVANT=()
    HASH_INV_ERROR=""

    msg=$(run_rename_py hash inventory "$DATA_DIR" "$PAR2_FILE" 2>&1) || rc=$?
    if (( rc != 0 )); then
        HASH_INV_ERROR="$msg"
        return "$rc"
    fi

    mapfile -t lines <<< "$msg"
    HASH_INV_TOTAL="${lines[0]:-0}"
    HASH_INV_WITH_PAR2="${lines[1]:-0}"
    HASH_INV_IN_SCOPE="${lines[2]:-0}"
    if (( ${#lines[@]} > 3 )); then
        HASH_INV_RELEVANT=("${lines[@]:3}")
    fi
    return 0
}

pgm_print_startup_inventory() {
    local par2_dir stem user_par2_ap=""
    local -a par2_set=() index_candidates=()
    local i other_count=0 ignored_index_count=0 marker

    par2_dir="$(dirname "$PAR2_FILE")"
    stem="$(par2_stem_from_par2_basename "$(basename "$PAR2_FILE")")"
    find_all_par2_index_files "$par2_dir" index_candidates
    if (( ${#PAR2_SET_MEMBERS[@]} > 0 )); then
        par2_set=("${PAR2_SET_MEMBERS[@]}")
    else
        list_par2_set_members "$par2_dir" "$stem" par2_set
    fi
    [[ -n "$PAR2_RESOLVED_FROM" ]] && user_par2_ap="$PAR2_RESOLVED_FROM"

    echo "=== PAR2 check scope ==="
    echo "Data directory : $DATA_DIR"
    if [[ "$par2_dir" != "$DATA_DIR" ]]; then
        echo "PAR2 directory : $par2_dir"
    fi
    echo

    if (( ${#USER_ARG_PATHS[@]} > 0 )); then
        echo "User specified:"
        for i in "${USER_ARG_PATHS[@]}"; do
            printf '  %s (%s)\n' "$(basename "$i")" "$(pgm_describe_path_kind "$i")"
        done
        echo
    fi

    if [[ -n "$user_par2_ap" && "$user_par2_ap" != "$PAR2_FILE" ]]; then
        echo "PAR2 entry (specified): $(basename "$user_par2_ap")"
    fi
    if is_par2_index_file "$(basename "$PAR2_FILE")"; then
        echo "PAR2 index (in use): $(basename "$PAR2_FILE")"
    else
        echo "PAR2 verify file (in use): $(basename "$PAR2_FILE")"
        echo "Note: no separate PAR2 index file found in this set."
    fi

    if [[ -n "$PAR2_RESOLVED_FROM" || ${#PAR2_SET_QUEUE[@]} -gt 1 ]]; then
        for i in "${index_candidates[@]}"; do
            [[ "$i" == "$PAR2_FILE" ]] && continue
            if ! pgm_path_in_array "$i" par2_set; then
                ignored_index_count=$((ignored_index_count + 1))
            fi
        done
        if (( ignored_index_count > 0 )); then
            echo "Other PAR2 index file(s) in directory (ignored): ${ignored_index_count}"
        fi
    else
        for i in "${index_candidates[@]}"; do
            [[ "$i" == "$PAR2_FILE" ]] && continue
            other_count=$((other_count + 1))
        done
        if (( other_count > 0 )); then
            echo "Other PAR2 index file(s) in PAR2 directory:"
            for i in "${index_candidates[@]}"; do
                [[ "$i" == "$PAR2_FILE" ]] && continue
                printf '  %s\n' "$(basename "$i")"
            done
        elif (( ${#index_candidates[@]} == 1 )); then
            echo "PAR2 index file(s) in PAR2 directory: 1"
        else
            echo "PAR2 index file(s) in PAR2 directory: 0"
        fi
    fi

    echo "PAR2 set (${#par2_set[@]} file(s)):"
    if (( ${#par2_set[@]} == 0 )); then
        echo "  (none besides index)"
    else
        for i in "${par2_set[@]}"; do
            marker=""
            [[ "$i" == "$PAR2_FILE" ]] && marker="  [index]"
            [[ -n "$user_par2_ap" && "$i" == "$user_par2_ap" ]] && marker="  [user argument]"
            printf '  %s%s\n' "$(basename "$i")" "$marker"
        done
    fi
    echo

    if pgm_load_hash_inventory; then
        if (( HASH_INV_TOTAL == 0 )); then
            echo "Hash files: none in directory."
        elif (( HASH_INV_IN_SCOPE == 0 )); then
            echo "Hash files: ${HASH_INV_TOTAL} in directory; none list in-scope PAR2 archive(s) for this set."
        else
            echo "Hash files: ${HASH_INV_IN_SCOPE} of ${HASH_INV_TOTAL} list in-scope PAR2 archive(s) for this set:"
            for i in "${HASH_INV_RELEVANT[@]}"; do
                marker=""
                [[ -n "$USER_HASH_INPUT" && "$(abs_path "$USER_HASH_INPUT")" == "$i" ]] && marker="  [user argument]"
                printf '  %s%s\n' "$(basename "$i")" "$marker"
            done
        fi
    else
        echo "Hash files: inventory unavailable (${HASH_INV_ERROR%%$'\n'*})"
    fi
    echo

    echo "Data files: scanned only if Step 3 runs (subdirectory tree scan)."
}

abs_path() {
    local path="$1"
    if command -v realpath >/dev/null 2>&1; then
        realpath "$path"
    else
        (
            cd "$(dirname "$path")" || exit 1
            echo "$(pwd -P)/$(basename "$path")"
        )
    fi
}

collect_data_files() {
    local dir="$1"
    local f base dir_ap rel
    local -a nested_roots=()

    DATA_FILES=()
    dir_ap="$(abs_path "$dir")"
    pgm_find_nested_par2_roots "$dir_ap" nested_roots

    while IFS= read -r -d '' f; do
        [[ -f "$f" ]] || continue
        if ((${#nested_roots[@]} > 0)); then
            for nr in "${nested_roots[@]}"; do
                [[ "$f" == "$nr"/* || "$f" == "$nr" ]] && continue 2
            done
        fi
        base="$(basename "$f")"
        case "$base" in
            *.par2|*.PAR2) continue ;;
            *_old.par2|*_old.PAR2) continue ;;
            *.sha512|*.SHA512|*.sha256|*.SHA256|*.md5|*.MD5) continue ;;
            par2-pgm-check.sh|par2-pgm-rename.py) continue ;;
        esac
        if [[ "$f" == "$dir_ap"/* ]]; then
            rel="${f#"$dir_ap"/}"
        else
            rel="$base"
        fi
        DATA_FILES+=("$rel")
    done < <(find "$dir_ap" -type f -print0 2>/dev/null)

    if (( ${#DATA_FILES[@]} > 1 )); then
        IFS=$'\n' DATA_FILES=($(printf '%s\n' "${DATA_FILES[@]}" | LC_ALL=C sort -f))
        unset IFS
    fi
}

pgm_find_nested_par2_roots() {
    local root="$1"
    local -n _out=$2
    local f base d_ap root_ap
    local -a all_par2=()
    local -A dir_index_stems=() nested_dirs=()

    _out=()
    root_ap="$(abs_path "$root")"
    while IFS= read -r -d '' f; do
        [[ -f "$f" ]] || continue
        all_par2+=("$f")
    done < <(find "$root_ap" \( -iname '*.par2' -o -iname '*.PAR2' \) -type f -print0 2>/dev/null)

    for f in "${all_par2[@]}"; do
        base="$(basename "$f")"
        is_par2_index_file "$base" || continue
        d_ap="$(abs_path "$(dirname "$f")")"
        dir_index_stems["$(pgm_par2_set_key "$f")"]=1
    done

    for f in "${all_par2[@]}"; do
        base="$(basename "$f")"
        is_par2_any_active_file "$base" || continue
        d_ap="$(abs_path "$(dirname "$f")")"
        [[ "$d_ap" == "$root_ap" ]] && continue
        if is_par2_index_file "$base"; then
            nested_dirs["$d_ap"]=1
        elif is_par2_volume_file "$base"; then
            [[ -n "${dir_index_stems[$(pgm_par2_set_key "$f")]:-}" ]] && continue
            nested_dirs["$d_ap"]=1
        fi
    done

    _out=("${!nested_dirs[@]}")
    pgm_sort_path_array _out
}

pgm_collect_data_files_for_scan() {
    echo "Scanning data files under $DATA_DIR (including subdirectories; large trees can take several minutes)..."
    collect_data_files "$DATA_DIR"
    (( ${#DATA_FILES[@]} > 0 )) || die "No data files found under: $DATA_DIR"
    echo "Found ${#DATA_FILES[@]} data file(s) for directory scan."
    echo
}

run_par2() {
    local mode="$1"
    shift
    "$PAR2_CMD" "$mode" "$@"
}

# Run par2 against DATA_FILES in chunks to stay under ARG_MAX on large trees.
pgm_par2_run_chunked() {
    local mode="$1"
    local outfile="${2:-}"
    local par2_base batch_size chunk=() i rc=0 last_rc=0

    par2_base="$(basename "$PAR2_FILE")"
    batch_size="$PGM_PAR2_ARG_BATCH"
    (( ${#DATA_FILES[@]} > 0 )) || return 0

    if [[ -n "$outfile" ]]; then
        : > "$outfile"
    fi

    for (( i=0; i < ${#DATA_FILES[@]}; i++ )); do
        chunk+=("${DATA_FILES[$i]}")
        if ((${#chunk[@]} >= batch_size)) || (( i == ${#DATA_FILES[@]} - 1 )); then
            if [[ -n "$outfile" ]]; then
                (
                    cd "$DATA_DIR" || exit 1
                    run_par2 "$mode" "$par2_base" "${chunk[@]}"
                ) >>"$outfile" 2>&1
                last_rc=$?
            else
                (
                    cd "$DATA_DIR" || exit 1
                    run_par2 "$mode" "$par2_base" "${chunk[@]}"
                )
                last_rc=$?
            fi
            (( last_rc != 0 )) && rc=$last_rc
            chunk=()
        fi
    done
    return "$rc"
}

run_rename_py() {
    if [[ -n "${DATA_DIR:-}" && -d "$DATA_DIR" ]]; then
        ( cd "$DATA_DIR" && "$PYTHON_CMD" "$RENAME_PY" "$@" )
    else
        "$PYTHON_CMD" "$RENAME_PY" "$@"
    fi
}

verify_par2_hashes() {
    local msg rc

    msg=$(run_rename_py hash verify "$DATA_DIR" "$PAR2_FILE" 2>&1) || true
    rc=$?
    PGM_HASH_VERIFY_MSG="$msg"
    echo "$msg"
    return "$rc"
}

update_par2_hashes() {
    local msg rc
    msg=$(run_rename_py hash update "$DATA_DIR" "$PAR2_FILE" 2>&1) || true
    rc=$?
    echo "$msg"
    return "$rc"
}

restore_par2_file_timestamps() {
    local dir="$1"
    local f backup_base active restored=0

    shopt -s nullglob
    for f in "$dir"/*_old.par2 "$dir"/*_old.PAR2; do
        [[ -f "$f" ]] || continue
        backup_base="$(basename -- "$f")"
        backup_base="${backup_base%_old.par2}"
        backup_base="${backup_base%_old.PAR2}"
        active=""
        if [[ -f "$dir/${backup_base}.par2" ]]; then
            active="$dir/${backup_base}.par2"
        elif [[ -f "$dir/${backup_base}.PAR2" ]]; then
            active="$dir/${backup_base}.PAR2"
        fi
        [[ -n "$active" ]] || continue
        touch -r "$f" -- "$active"
        printf '  %s\n' "$(basename -- "$active")"
        restored=$((restored + 1))
    done
    shopt -u nullglob

    if (( restored > 0 )); then
        echo "Restored original timestamps on ${restored} PAR2 file(s) (from *_old.par2 backup dates)."
    fi
}

extract_misnamed_pairs() {
    local out_file="$1"
    local disk_file par2_name par2_names_file

    MISNAMED_DISK=()
    MISNAMED_PAR2=()
    RENAME_PAIRS=()

    command -v "$PYTHON_CMD" >/dev/null 2>&1 || die "'$PYTHON_CMD' not found (needed to parse par2 output)."

    par2_names_file=$(mktemp "${TMPDIR:-/tmp}/par2-pgm-check.XXXXXX")
    if ! run_rename_py "$(basename "$PAR2_FILE")" list-names >"$par2_names_file" 2>/dev/null; then
        : > "$par2_names_file"
    fi

    while IFS='|' read -r disk_file par2_name; do
        [[ -n "$disk_file" && -n "$par2_name" ]] || continue
        MISNAMED_DISK+=("$disk_file")
        MISNAMED_PAR2+=("$par2_name")
        RENAME_PAIRS+=("${par2_name}//${disk_file}")
    done < <("$PYTHON_CMD" - "$out_file" "$DATA_DIR" "$par2_names_file" <<'PY'
import os
import re
import sys

path = sys.argv[1]
data_dir = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2] else ""
par2_names_path = sys.argv[3] if len(sys.argv) > 3 else ""

par2_names = set()
if par2_names_path:
    with open(par2_names_path, encoding="utf-8") as handle:
        par2_names = {line.strip() for line in handle if line.strip()}

with open(path, "rb") as handle:
    text = handle.read().decode("utf-8", errors="replace").replace("\r", "")


def rel_from_data_dir(disk_path):
    disk_path = disk_path.replace("\\", "/")
    if not data_dir:
        return disk_path
    if os.path.isabs(disk_path):
        try:
            return os.path.relpath(disk_path, data_dir).replace("\\", "/")
        except ValueError:
            return disk_path
    return disk_path


def normalize_quotes(line):
    return (
        line.replace("\u201c", '"')
        .replace("\u201d", '"')
        .replace("\u00ab", '"')
        .replace("\u00bb", '"')
    )


seen_par2 = set()


def add_pair(disk_raw, par2_raw):
    disk = rel_from_data_dir(disk_raw.strip().replace("\\", "/"))
    par2_name = par2_raw.strip().rstrip(".").replace("\\", "/")
    if not disk or not par2_name or disk == par2_name:
        return
    if par2_names and par2_name not in par2_names:
        return
    if par2_name in seen_par2:
        return
    seen_par2.add(par2_name)
    print(f"{disk}|{par2_name}")


match_patterns = (
    r'File:\s*"([^"]+)"\s*-\s*is a match for\s*"([^"]+)"',
    r'Target:\s*"([^"]+)"\s*-\s*is a match for\s*"([^"]+)"',
)

for line in text.split("\n"):
    line = normalize_quotes(line)
    matched = False
    for pattern in match_patterns:
        match = re.search(pattern, line)
        if match:
            add_pair(match.group(1), match.group(2))
            matched = True
            break
    if matched:
        continue
    match = re.match(r"^(.+?) is a perfect match for (.+?)\s*$", line.strip())
    if match:
        add_pair(match.group(1), match.group(2))
PY
    )
    rm -f "$par2_names_file"
}

pgm_apply_rename_from_pairs_file() {
    local pairs_file="$1"
    local batch_file
    local -a batch=()
    local line count=0 rename_rc=0

    batch_file=$(mktemp "${TMPDIR:-/tmp}/par2-pgm-check.XXXXXX")
    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ -n "$line" ]] || continue
        batch+=("$line")
        count=$((count + 1))
        if (( count >= PGM_RENAME_BATCH )); then
            printf '%s\n' "${batch[@]}" >"$batch_file"
            run_rename_py "$(basename "$PAR2_FILE")" --pairs-file "$batch_file" || rename_rc=$?
            (( rename_rc == 0 )) || { rm -f "$batch_file"; return "$rename_rc"; }
            batch=()
            count=0
        fi
    done <"$pairs_file"

    if (( count > 0 )); then
        printf '%s\n' "${batch[@]}" >"$batch_file"
        run_rename_py "$(basename "$PAR2_FILE")" --pairs-file "$batch_file" || rename_rc=$?
    fi

    rm -f "$batch_file"
    return "$rename_rc"
}

prompt_and_apply_rename() {
    local pairs_file rename_rc=0 rename_choice=0

    (( ${#RENAME_PAIRS[@]} > 0 )) || return 0

    if (( NO_RENAME == 1 )); then
        pgm_print_step_verdict 4 SKIP "PAR2 metadata update skipped (--no-rename)."
        return 1
    fi

    if (( AUTO_RENAME == 0 )); then
        echo
        echo "Misnamed files can be fixed by updating filenames inside the PAR2 set"
        echo "(disk filenames stay unchanged)."
        echo "PAR2 index file: $(basename "$PAR2_FILE")"
        if (( MULTI_SET_MODE )); then
            pgm_prompt_read_rename_choice 0 rename_choice
        else
            pgm_prompt_read_rename_choice 1 rename_choice
        fi
        case "$rename_choice" in
            0)
                ;;
            1)
                echo "Skipped PAR2 metadata update."
                pgm_print_step_verdict 4 SKIP "PAR2 metadata update skipped at prompt."
                return 1
                ;;
            2)
                echo "Cancelled."
                return_code=0
                finish
                ;;
        esac
    fi

    pgm_print_step_header "Step 4: update PAR2 metadata"
    pairs_file=$(mktemp "${TMPDIR:-/tmp}/par2-pgm-check.XXXXXX")
    printf '%s\n' "${RENAME_PAIRS[@]}" >"$pairs_file"
    echo "Applying ${#RENAME_PAIRS[@]} PAR2 metadata rename pair(s)..."
    pgm_apply_rename_from_pairs_file "$pairs_file"
    rename_rc=$?
    rm -f "$pairs_file"
    (( rename_rc == 0 )) || die "PAR2 metadata update failed (exit $rename_rc)."
    pgm_print_step_verdict 4 OK "PAR2 metadata updated for misnamed file(s)."

    pgm_print_step_header "Step 4b: restore PAR2 file timestamps"
    echo "Setting active .par2 modification times to match the original *_old.par2 backups."
    restore_par2_file_timestamps "$DATA_DIR"
    pgm_print_step_verdict 4b OK "PAR2 file timestamps restored from *_old.par2 backups."

    pgm_print_step_header "Step 5: update hash file"
    update_par2_hashes || die "Failed to update hash file."
    pgm_print_step_verdict 5 OK "Hash manifest(s) updated for in-scope PAR2 archive(s)."

    pgm_print_step_header "Step 6: verify after update"
    local OUT6_FILE
    OUT6_FILE=$(mktemp "${TMPDIR:-/tmp}/par2-pgm-check.XXXXXX")
    run_par2 verify "$PAR2_FILE" >"$OUT6_FILE" 2>&1
    <"$OUT6_FILE" pgm_filter_par2_verify_stream
    echo
    pgm_collect_missing_targets "$OUT6_FILE"
    pgm_print_missing_targets_report
    PGM_POST_RENAME_OUT=$(<"$OUT6_FILE")
    rm -f "$OUT6_FILE"

    if pgm_post_rename_names_unresolved "$PGM_POST_RENAME_OUT"; then
        pgm_print_step_verdict 6 FAIL "PAR2 names still do not match the files on disk."
        die "PAR2 metadata update did not resolve all name mismatches (see Step 6 output)."
    fi

    # Damage unrelated to naming is left for the repair step, not treated as a
    # failed rename.
    if pgm_par2_output_indicates_ok "$PGM_POST_RENAME_OUT"; then
        pgm_print_step_verdict 6 OK "Post-update PAR2 verify passed."
    else
        pgm_print_step_verdict 6 OK \
            "PAR2 names now match on disk; other problems remain (see below)."
    fi
    return 0
}

# True while par2 still reports naming problems for the files we just renamed.
pgm_post_rename_names_unresolved() {
    local text="$1"
    local name

    grep -qE '[0-9]+ file\(s\) have the wrong name\.' <<< "$text" && return 0

    for name in "${MISNAMED_PAR2[@]}"; do
        grep -qF "Target: \"${name}\" - missing." <<< "$text" && return 0
    done
    return 1
}

prompt_and_apply_repair() {
    local repair_choice=0 repair_rc=0

    (( REPAIR_POSSIBLE == 1 )) || return 1

    if (( NO_REPAIR == 1 )); then
        pgm_print_step_verdict 7 SKIP "Repair skipped (--no-repair)."
        return 1
    fi

    if (( REPAIR == 0 )); then
        echo
        echo "par2 can rebuild the damaged file(s) from the recovery blocks."
        echo "Note: par2 repair also renames disk files to match PAR2 names."
        if (( MULTI_SET_MODE )); then
            pgm_prompt_read_repair_choice 0 repair_choice
        else
            pgm_prompt_read_repair_choice 1 repair_choice
        fi
        case "$repair_choice" in
            0)
                ;;
            1)
                echo "Skipped repair."
                pgm_print_step_verdict 7 SKIP "Repair skipped at prompt."
                return 1
                ;;
            2)
                echo "Cancelled."
                return_code=0
                finish
                ;;
        esac
    fi

    pgm_print_step_header "Step 7: repair damaged file(s)"
    (( ${#DATA_FILES[@]} > 0 )) || pgm_collect_data_files_for_scan
    set +e
    pgm_par2_run_chunked repair
    repair_rc=$?
    set -e
    if (( repair_rc != 0 )); then
        pgm_print_step_verdict 7 FAIL "par2 repair failed (exit $repair_rc)."
        return 1
    fi
    pgm_print_step_verdict 7 OK "par2 repair completed."
    return 0
}

pgm_collect_missing_targets() {
    local out_file="$1"
    local line

    MISSING_PAR2_TARGETS=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line//$'\r'/}"
        case "$line" in
            Target:*" - missing.")
                MISSING_PAR2_TARGETS+=("$line")
                ;;
        esac
    done <"$out_file"
}

pgm_print_missing_targets_report() {
    local n=${#MISSING_PAR2_TARGETS[@]}
    local i max_show=500

    (( n > 0 )) || return 0

    echo
    echo "Missing PAR2 target file(s) (${n}):"
    if (( n <= max_show )); then
        for i in "${MISSING_PAR2_TARGETS[@]}"; do
            printf '  %s\n' "$i"
        done
    else
        for i in "${!MISSING_PAR2_TARGETS[@]}"; do
            (( i < max_show )) || break
            printf '  %s\n' "${MISSING_PAR2_TARGETS[$i]}"
        done
        echo "  ... and $(( n - max_show )) more"
    fi
}

pgm_collect_damaged_targets() {
    local out_file="$1"
    local line name in_extras=0
    local -A seen=()

    DAMAGED_PAR2_TARGETS=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        line="${line//$'\r'/}"
        case "$line" in
            "Scanning extra files:"*)
                in_extras=1
                continue
                ;;
            "Verifying source files:"*)
                in_extras=0
                continue
                ;;
            Target:*" - damaged."*)
                name="${line#Target: \"}"
                name="${name%%\" - damaged.*}"
                ;;
            # A source file that exists but matches no block at all.
            File:*" - no data found."*)
                (( in_extras )) && continue
                name="${line#File: \"}"
                name="${name%%\" - no data found.*}"
                ;;
            *)
                continue
                ;;
        esac
        [[ -n "${seen[$name]:-}" ]] && continue
        seen[$name]=1
        DAMAGED_PAR2_TARGETS+=("$name")
    done <"$out_file"
}

# A damaged .par2 / hash file is often one this run (or an earlier one) updated
# on purpose, so repairing it from the recovery blocks rolls that update back.
pgm_print_damaged_targets_report() {
    local n=${#DAMAGED_PAR2_TARGETS[@]}
    local i base max_show=100
    local -a metadata=()

    (( n > 0 )) || return 0

    echo
    echo "Damaged file(s) (${n}):"
    for i in "${!DAMAGED_PAR2_TARGETS[@]}"; do
        (( i < max_show )) || { echo "  ... and $(( n - max_show )) more"; break; }
        printf '  %s\n' "${DAMAGED_PAR2_TARGETS[$i]}"
    done

    for i in "${DAMAGED_PAR2_TARGETS[@]}"; do
        base="$(basename -- "$i")"
        if is_par2_any_active_file "$base" || pgm_is_hash_file_name "$base"; then
            metadata+=("$i")
        fi
    done

    (( ${#metadata[@]} > 0 )) || return 0

    echo
    echo "Caution: ${#metadata[@]} damaged file(s) are PAR2 or hash metadata:"
    for i in "${metadata[@]}"; do
        printf '  %s\n' "$i"
    done
    echo "If that metadata was updated on purpose (a misnamed-file fix here or in"
    echo "a nested set), this set still stores the old content and repairing would"
    echo "undo the update. Regenerate this set instead when the change was wanted."
}

pgm_is_hash_file_name() {
    case "${1,,}" in
        *.sha512|*.sha256|*.md5) return 0 ;;
    esac
    return 1
}

pgm_filter_missing_targets_excluding_misnamed() {
    local -a filtered=()
    local line par2_target i

    for line in "${MISSING_PAR2_TARGETS[@]}"; do
        par2_target="${line#Target: \"}"
        par2_target="${par2_target%\" - missing.}"
        for i in "${MISNAMED_PAR2[@]}"; do
            [[ "$i" == "$par2_target" ]] && continue 2
        done
        filtered+=("$line")
    done
    MISSING_PAR2_TARGETS=("${filtered[@]}")
}

print_summary() {
    local out_file="$1"
    local missing=0
    local matches=0
    local wrong=""
    local rename_cmd
    local i

    pgm_collect_missing_targets "$out_file"
    pgm_collect_damaged_targets "$out_file"

    REPAIR_POSSIBLE=0
    grep -qiE 'repair is possible' "$out_file" && REPAIR_POSSIBLE=1

    wrong=$(grep -E '[0-9]+ file\(s\) have the wrong name\.' "$out_file" | head -1 || true)

    extract_misnamed_pairs "$out_file"
    pgm_filter_missing_targets_excluding_misnamed
    missing=${#MISSING_PAR2_TARGETS[@]}
    matches=${#MISNAMED_DISK[@]}

    for i in "${!MISNAMED_DISK[@]}"; do
        echo "File: \"${MISNAMED_DISK[$i]}\" - is a match for \"${MISNAMED_PAR2[$i]}\"."
    done

    echo
    echo "Summary:"
    echo "  Missing targets (by PAR2 name): ${missing}"
    echo "  Content matches found on disk:  ${matches}"
    echo "  Damaged files:                  ${#DAMAGED_PAR2_TARGETS[@]}"
    [[ -n "$wrong" ]] && echo "  ${wrong}"
    pgm_print_missing_targets_report

    if (( matches > 0 )); then
        echo
        echo "Misnamed files detected (same data, different name on disk):"
        rename_cmd="./par2-pgm-rename.py $(printf '%q' "$(basename "$PAR2_FILE")")"
        for i in "${!MISNAMED_PAR2[@]}"; do
            printf '  PAR2 expects: %s\n' "${MISNAMED_PAR2[$i]}"
            printf '  Found on disk: %s\n' "${MISNAMED_DISK[$i]}"
            echo
            rename_cmd+=" $(printf '%q' "${MISNAMED_PAR2[$i]}//${MISNAMED_DISK[$i]}")"
        done
        if (( NO_RENAME == 0 && AUTO_RENAME == 0 )); then
            if (( MULTI_SET_MODE )); then
                echo "You will be asked whether to update PAR2 metadata (default: no, q quits, $(pgm_prompt_timeout_label))."
            else
                echo "You will be asked whether to update PAR2 metadata (default: yes, q quits, $(pgm_prompt_timeout_label))."
            fi
        elif (( AUTO_RENAME == 1 )); then
            echo "PAR2 metadata will be updated automatically (--yes)."
        else
            echo "Manual command if needed:"
            echo
            echo "$rename_cmd"
        fi
        pgm_print_step_verdict 3 WARN \
            "Misnamed file(s) detected (same data, different name on disk)."
        pgm_print_outcome warn \
            "Misnamed file(s) detected (same data, different name on disk)." \
            "See details above; update PAR2 metadata or use --no-rename."
        return 2
    fi

    if pgm_par2_output_indicates_ok "$out_file"; then
        local par2_ok_line
        par2_ok_line="$(pgm_extract_par2_ok_line "$out_file")"
        pgm_print_step_verdict 3 OK "Directory scan passed; names match on disk."
        pgm_print_outcome ok \
            "Verification passed (directory scan)." \
            "${par2_ok_line:-All files match under PAR2 names.}"
        return 0
    fi

    if [[ -n "$wrong" ]]; then
        pgm_print_step_verdict 3 WARN \
            "Wrong PAR2 filename(s) detected; rename pairs could not be parsed."
        pgm_print_outcome warn \
            "Wrong PAR2 filename(s) detected, but rename pairs could not be parsed." \
            "Search Step 3 output for: File/Target: \"...\" - is a match for \"...\"."
        return 2
    fi

    if (( REPAIR_POSSIBLE )); then
        pgm_print_damaged_targets_report
        if (( NO_REPAIR == 0 && REPAIR == 0 )); then
            echo
            if (( MULTI_SET_MODE )); then
                echo "You will be asked whether to repair (default: no, q quits, $(pgm_prompt_timeout_label))."
            else
                echo "You will be asked whether to repair (default: yes, q quits, $(pgm_prompt_timeout_label))."
            fi
        elif (( REPAIR == 1 )); then
            echo
            echo "Damaged file(s) will be repaired automatically (--repair)."
        fi
        pgm_print_step_verdict 3 WARN "Repair is possible (damage or rename fixable)."
        pgm_print_outcome warn \
            "Repair is possible (damage or rename fixable)." \
            "See missing file list above (if any)."
        return 2
    fi

    if (( missing > 0 )); then
        pgm_print_step_verdict 3 FAIL \
            "Files missing with no content match on disk (${missing} target(s))."
        pgm_print_outcome err \
            "Files are missing and no content match was found in the directory." \
            "Missing targets (by PAR2 name): ${missing}"
        return 3
    fi

    pgm_print_step_verdict 3 FAIL "Verification reported problems (see output above)."
    pgm_print_outcome err \
        "Verification reported problems." \
        "Review Step 3 output above."
    return 2
}

pgm_run_one_par2_set() {
    local SUMMARY_RC=0

    MISNAMED_DISK=()
    MISNAMED_PAR2=()
    RENAME_PAIRS=()
    DAMAGED_PAR2_TARGETS=()
    REPAIR_POSSIBLE=0
    PGM_POST_RENAME_OUT=""
    OUT2_FILE=""
    PGM_HASH_VERIFY_MSG=""
    PGM_TIMING_HASH_SEC=0
    PGM_TIMING_PAR2_NAMES_SEC=0
    PGM_TIMING_PAR2_SCAN_SEC=0
    PGM_RUN_START=$SECONDS
    PGM_TIMING_LAST=$SECONDS

    pgm_print_startup_inventory

    pgm_print_step_header "Step 1: verify PAR2 archive checksums"
    if ! verify_par2_hashes; then
        pgm_print_step_verdict 1 FAIL "PAR2 archive checksum verification failed."
        if (( MULTI_SET_MODE )); then
            return 3
        fi
        die "PAR2 archive checksum verification failed. Refusing to scan for misnamed files."
    fi
    pgm_print_step1_verdict_from_msg "${PGM_HASH_VERIFY_MSG:-}"
    pgm_timing_lap_to PGM_TIMING_HASH_SEC

    pgm_print_step_header "Step 2: verify (PAR2 names only)"
    OUT1=$(run_par2 verify "$PAR2_FILE" 2>&1)
    RC1=$?
    pgm_timing_lap_to PGM_TIMING_PAR2_NAMES_SEC
    printf '%s\n\n' "$(pgm_filter_par2_verify_output "$OUT1")"

    if pgm_par2_output_indicates_ok "$OUT1"; then
        par2_ok_line="$(pgm_extract_par2_ok_line "$OUT1")"
        pgm_print_step_verdict 2 OK "All files match under PAR2 names."
        pgm_print_outcome ok \
            "All files OK under PAR2 names." \
            "${par2_ok_line:-Verification passed under PAR2 names only.}"
        return 0
    fi

    pgm_print_step_verdict 2 WARN "Not all files OK under PAR2 names; running directory scan."
    pgm_collect_data_files_for_scan
    pgm_print_step_header "Step 3: verify with directory scan (subdirs; detect misnamed files)"
    OUT2_FILE=$(mktemp "${TMPDIR:-/tmp}/par2-pgm-check.XXXXXX")
    pgm_par2_run_chunked verify "$OUT2_FILE"
    RC2=$?
    <"$OUT2_FILE" pgm_filter_par2_verify_stream
    pgm_timing_lap_to PGM_TIMING_PAR2_SCAN_SEC
    echo

    print_summary "$OUT2_FILE"
    SUMMARY_RC=$?

    if (( SUMMARY_RC == 2 && ${#RENAME_PAIRS[@]} > 0 )); then
        if prompt_and_apply_rename; then
            if pgm_par2_output_indicates_ok "$PGM_POST_RENAME_OUT"; then
                par2_ok_line="$(pgm_extract_par2_ok_line "$PGM_POST_RENAME_OUT")"
                SUMMARY_RC=0
                pgm_print_outcome ok \
                    "All files OK under PAR2 names." \
                    "${par2_ok_line:-Verification passed under PAR2 names only.}"
            else
                printf '%s\n' "$PGM_POST_RENAME_OUT" >"$OUT2_FILE"
                REPAIR_POSSIBLE=0
                grep -qiE 'repair is possible' "$OUT2_FILE" && REPAIR_POSSIBLE=1
                pgm_collect_damaged_targets "$OUT2_FILE"
                pgm_print_damaged_targets_report
                SUMMARY_RC=2
                pgm_print_outcome warn \
                    "PAR2 names updated; damaged file(s) still need attention." \
                    "See the damaged file list above."
            fi
        fi
    fi

    if (( SUMMARY_RC != 0 && REPAIR_POSSIBLE == 1 )); then
        if prompt_and_apply_repair; then
            local OUT8_FILE out8_text
            pgm_print_step_header "Step 8: verify after repair"
            OUT8_FILE=$(mktemp "${TMPDIR:-/tmp}/par2-pgm-check.XXXXXX")
            pgm_par2_run_chunked verify "$OUT8_FILE"
            <"$OUT8_FILE" pgm_filter_par2_verify_stream
            echo
            out8_text=$(<"$OUT8_FILE")
            rm -f "$OUT8_FILE"
            if pgm_par2_output_indicates_ok "$out8_text"; then
                SUMMARY_RC=0
                pgm_print_step_verdict 8 OK "Post-repair verify passed."
                pgm_print_outcome ok \
                    "Repair completed; all files verify." \
                    "$(pgm_extract_par2_ok_line "$out8_text")"
            else
                pgm_print_step_verdict 8 FAIL "Post-repair verify still reports problems."
                pgm_print_outcome err \
                    "Repair ran but verification still reports problems." \
                    "Review Step 8 output above."
                SUMMARY_RC=3
            fi
        fi
    fi

    return "$SUMMARY_RC"
}

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            . /root/bin/_script_footer.sh
            exit 0
            ;;
        -v|--version)
            print_version_banner
            . /root/bin/_script_footer.sh
            exit 0
            ;;
        --repair)
            REPAIR=1
            shift
            ;;
        --no-repair)
            NO_REPAIR=1
            shift
            ;;
        --yes|-y)
            AUTO_RENAME=1
            VERIFY_ALL_SETS=1
            shift
            ;;
        --all)
            VERIFY_ALL_SETS=1
            shift
            ;;
        --no-rename)
            NO_RENAME=1
            shift
            ;;
        --scope)
            [[ $# -ge 2 ]] || die "Missing value for --scope (use subdirs or current)"
            case "$2" in
                subdirs|current) CLI_SCOPE="$2" ;;
                *) die "Invalid --scope: $2 (use subdirs or current)" ;;
            esac
            shift 2
            ;;
        -*)
            echo "Unknown option: $1 (try --help)" >&2
            return_code=1
            finish
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

for arg in "${POSITIONAL[@]}"; do
    [[ -n "$arg" ]] || continue
    if [[ -d "$arg" ]]; then
        [[ -z "$USER_DIR_INPUT" ]] || die "Multiple directories specified: $arg"
        USER_DIR_INPUT="$(abs_path "$arg")"
        USER_ARG_PATHS+=("$USER_DIR_INPUT")
    elif [[ -e "$arg" ]]; then
        apply_file_argument "$arg"
    elif pgm_arg_has_glob "$arg"; then
        DEFERRED_GLOB_ARGS+=("$arg")
    else
        die "Path not found: $arg"
    fi
done

DATA_DIR="$(infer_data_dir_from_inputs)"
DATA_DIR="$(abs_path "$DATA_DIR")"
[[ -d "$DATA_DIR" ]] || die "Directory not found: $DATA_DIR"
START_DIR="$DATA_DIR"

if ((${#DEFERRED_GLOB_ARGS[@]} > 0)); then
    glob_arg=""
    glob_matches=()
    for glob_arg in "${DEFERRED_GLOB_ARGS[@]}"; do
        glob_matches=()
        pgm_expand_glob_in_dir "$glob_arg" "$DATA_DIR" glob_matches
        ((${#glob_matches[@]} > 0)) || die "No files matched glob in $DATA_DIR: $glob_arg"
        for match in "${glob_matches[@]}"; do
            apply_file_argument "$match"
        done
    done
fi

if ((${#PAR2_SET_QUEUE[@]} == 0)); then
    pgm_resolve_check_scope
fi

pgm_print_run_settings

pgm_report_skipped_old_par2_backups

if ((${#PAR2_SET_QUEUE[@]} == 0)); then
    pgm_discover_and_queue_par2_sets
fi

((${#PAR2_SET_QUEUE[@]} > 0)) || die "No PAR2 set selected for verification."

command -v "$PAR2_CMD" >/dev/null 2>&1 || die "'$PAR2_CMD' not found. Install par2cmdline or set PAR2_CMD."
command -v "$PYTHON_CMD" >/dev/null 2>&1 || die "'$PYTHON_CMD' not found."

pgm_resolve_rename_py "$START_DIR"

PGM_SCRIPT_START_STR="$(pgm_wall_clock_now)"

if ((${#PAR2_SET_QUEUE[@]} == 1)); then
    pgm_prepare_par2_set "${PAR2_SET_QUEUE[0]}"
    pgm_run_one_par2_set
    return_code=$?
    finish
fi

MULTI_SET_MODE=1
PGM_MULTI_RUN_START=$SECONDS
set_idx=0
set_rc=0
for set_idx in "${!PAR2_SET_QUEUE[@]}"; do
    pgm_prepare_par2_set "${PAR2_SET_QUEUE[$set_idx]}"
    pgm_print_multi_set_banner "$((set_idx + 1))" "${#PAR2_SET_QUEUE[@]}" \
        "$(pgm_path_display_relative "$PAR2_FILE" "$START_DIR")" "$(dirname "$PAR2_FILE")"
    set_rc=0
    pgm_run_one_par2_set || set_rc=$?
    pgm_record_multi_set_result "$set_rc" "$(pgm_path_display_relative "$PAR2_FILE" "$START_DIR")"
done

return_code=$MULTI_SET_WORST_RC
finish
