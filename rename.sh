#!/usr/bin/env bash

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

read -t 60 -n 1 input
echo

if [[ "$input" =~ [Qq] ]]; then
    echo "Quitting."
    exit 0
elif [[ "$input" =~ [Nn] ]]; then
    use_colors=no
fi

# -------- COLORS SETUP (NO ANSI STORED IN DATA) --------
if [[ "$use_colors" == "yes" ]]; then
    RED='\e[31m'
    GREEN='\e[32m'
    CYAN='\e[36m'
    RESET='\e[0m'
else
    RED=''
    GREEN=''
    CYAN=''
    RESET=''
fi

ARROW="→"

# ============================================================
# MODE SELECTION
# ============================================================
echo
echo "Select mode:"
echo "  [D] Dry-run (default, preview only)"
echo "  [R] Real rename (interactive)"
echo "  [Q] Quit"
echo -n "Choice [D/r/q]: "

mode="dry-run"
input=""

read -t 60 -n 1 input
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
# STATE
# ============================================================
files_examined=0
files_affected=0
files_skipped=0
stopped_by_user=no
rename_all=no

# store as "old|new" (plain text only!)
declare -a renamed_list

# ============================================================
# MAIN LOOP
# ============================================================
for f in *; do
    ((files_examined++))
    new="$f"

    # -------- TRANSFORMATIONS --------
    new=$(printf '%s' "$new" | perl -pe '
        s/!/./g;
        tr/ĘĆÓŁĄŚŻŹŃęćółąśżźń/ECOŁASZZNecołaszzn/;
        s/[{}\[\]\(\),]/_/g;
        s/'\''/_/g;
        s/&/_and_/g;
        s/•/-/g;
        s/ /_/g;
        s/__+/_/g;
        s/_\././g;
        s/_$//;
        s/\.$//;
    ')

    [[ "$f" == "$new" ]] && { ((files_skipped++)); continue; }

    # -------- DRY-RUN MODE --------
    if [[ "$mode" == "dry-run" ]]; then
        echo
        echo -e "${RED}OLD:${RESET} $f"
        echo -e "${GREEN}NEW:${RESET} $new"
        echo "----------------------------------------"
        ((files_affected++))
        renamed_list+=("$f|$new")
        continue
    fi

    # -------- REAL MODE --------
    echo
    echo -e "${RED}OLD:${RESET} $f"
    echo -e "${GREEN}NEW:${RESET} $new"

    if [[ "$rename_all" == "yes" ]]; then
        if mv -i -- "$f" "$new"; then
            ((files_affected++))
            renamed_list+=("$f|$new")
        else
            ((files_skipped++))
        fi
        continue
    fi

    echo -n "Rename this file? [y/N/a/q]: "
    read -t 300 -n 1 input
    echo

    case "$input" in
        q|Q)
            stopped_by_user=yes
            break
            ;;
        y|Y)
            if mv -i -- "$f" "$new"; then
                ((files_affected++))
                renamed_list+=("$f|$new")
            else
                ((files_skipped++))
            fi
            ;;
        a|A)
            echo
            echo "⚠️  This will rename ALL remaining files without asking."
            echo -n "Are you sure? [y/N]: "
            read -n 1 confirm
            echo

            if [[ "$confirm" =~ [Yy] ]]; then
                rename_all=yes
                if mv -i -- "$f" "$new"; then
                    ((files_affected++))
                    renamed_list+=("$f|$new")
                else
                    ((files_skipped++))
                fi
            else
                echo "Rename-all cancelled."
                ((files_skipped++))
            fi
            ;;
        *)
            ((files_skipped++))
            ;;
    esac
done

# ============================================================
# SUMMARY (ANSI SAFE)
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

