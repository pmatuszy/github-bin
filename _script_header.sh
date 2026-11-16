#!/bin/bash
# v. 20261116.151500 - shared script_arrow_menu (Up/Down + Enter) for interactive prompts
# v. 20261116.143700 - shared terminal colors: ask Use colors?, green questions, highlight (default)
# v. 20261115.200000 - SUMMARY helpers: Script + Version identity; Family-A begin/end chrome
# v. 20261021.210400 - Usage/help use script_live_basename from _script_self_update.sh
# v. 20261021.143500 - after seal, keep CALLER_SCRIPT* / $0 as the live script (not .deleteme.*.seal.*)
# v. 20261020.205600 - seal files named .deleteme.*; seal failure falls back to live script
# v. 20261020.205000 - seal caller to temp before banner so in-place cp cannot splice bash source
# v. 20261020.202500 - self-update: watch live bin/ path (copy overwrite), not git checkout alone
# v. 20261020.202200 - source _script_self_update.sh: detect on-disk script replace while running
# v. 20260916.130951 - print_version_banner: draw box rules with sed; tr truncated ─ to one invalid byte
# v. 20260811.095711 - print_script_history: paged --history from caller changelog heade
# v. 20260731.211609 - ask before apt install (default Y, no timeout); no silent auto-install
# v. 20260722.084451 - let scripts continue with plain banners when optional boxes or figlet installation fails
# v. 20260716.173600 - print_version_banner uses CALLER_SCRIPT version fields
# v. 20260716.163300 - versioning v. YYYYMMDD.HH24MISS; parse first # v. YYYYMMDD.HHMMSS line

# 2026.11.16 - v. 1.69.151500 - Shared script_arrow_menu: Up/Down highlight, Enter select;
#                        letter keys still work; used by AV interactive prompts.
# 2026.11.16 - v. 1.68.143700 - Shared interactive colors: SCRIPT_USE_COLORS, script_ask_colors,
#                        script_print_question, script_echo_option (green "(default)"), script_printf_prompt.
#                        Scripts set SCRIPT_TS_FN to their timestamp helper and call script_ask_colors after the banner.
# 2026.11.15 - v. 1.67.200000 - script_summary_begin/end + script_summary_print_identity for shared
#                        end-of-run SUMMARY chrome (Script + Version at top)
# 2026.10.21 - v. 1.66.210400 - script_live_basename lives in _script_self_update.sh; help/Usage should call it
#                        instead of basename "$0" so .deleteme.*.seal.* never appears
# 2026.10.21 - v. 1.65.143500 - after seal re-exec, CALLER_SCRIPT / CALLER_SCRIPT_BASENAME / $0 (bash 5+)
#                        stay on the live script path so Command/Equivalent lines never print .deleteme.*.seal.*
# 2026.10.20 - v. 1.64.205600 - seal copies use .deleteme.<script>.seal.XXXXXX; if the seal cannot be created (read-only dir), continue on the live script without failing startup
# 2026.10.20 - v. 1.63.205000 - seal CALLER_SCRIPT to a temp copy before banners/delay (in-place cp into bin/ must not feed bash mixed old/new source); still watch the live path for [R]/[C]/[Q]
# 2026.10.20 - v. 1.62.202500 - self-update watches the running script path (destination after copy into bin/); git pull in a checkout does not count until that live file is overwritten
# 2026.10.20 - v. 1.61.202200 - source sibling _script_self_update.sh for CALLER_SCRIPT: notice git pull / file replace mid-run (DEBUG trap, [R]/[C]/[Q])
# 2026.09.16 - v. 1.60.130951 - print_version_banner: horizontal rules via sed 's/ /─/g'; tr is byte-wise and reduced the 3-byte ─ (U+2500) to a lone 0xE2, so banners printed invalid UTF-8
# 2026.07.31 - v. 1.59.211609 - check_if_installed: prompt before apt (default Y; no timeout; no auto-install)
# 2026.07.22 - v. 1.58.084451 - boxes/figlet checks are errexit-safe and fall back to plain startup text
# 2026.07.15 - v. 1.57.210402 - profile_location_dir: export only when set; no default to $HOME
# 2026.07.15 - v. 1.57.210401 - export profile_location_dir (default: $HOME or /root)
# 2026.07.05 - v. 1.57.210400 - fix caller script detection (BASH_SOURCE[1] was _script_header.sh inside function)
# 2026.06.27 - v. 1.56 - prompts: timestamp only; script version stays in window title (not script_version_in_prompt)
# 2026.06.18 - v. 1.55 - PuTTY/window title: script version at front of title ba
# 2026.06.18 - v. 1.54 - resolve caller script via BASH_SOURCE; export SCRIPT_VERSION_NUMBER; PuTTY title + prompt helpe
# 2026.06.02 - v. 1.53 - accept --no_startup_delay as alias for NO_STARTUP_DELAY (skip random delay when sourced with that flag)
# 2026.04.21 - v. 1.52 - ctrl_c STY guard; quote $0 in version/tty; year-agnostic changelog grep; -n STY; indent; contract blurb
# 2025.10.28 - v. 1.51- now we set LC_ALL for scripts to have proper separators in numbers (like ,.)
# 2023.10.10 - v. 1.5 - bugfix: removed hardcoded HEALTHCHECKS_FILE
# 2023.05.22 - v. 1.4 - added printing of the script name, added NO_STARTUP_DELAY startup paramete
# 2023.04.11 - v. 1.3 - added printing of the script name
# 2023.02.17 - v. 1.2 - added SCRIPT_VERSION env variable
# 2023.02.10 - v. 1.1 - changed check_if_installed with the option to provide the package name to be installed
# 2023.02.07 - v. 1.0 - added check_if_installed function and checks for figlet and boxes utils
# 2023.01.25 - v. 0.9 - added script_is_run_interactively env variable
# 2023.01.24 - v. 0.8 - added return_code environment variable
# 2023.01.15 - v. 0.7 - change $0 to basename $0 to have a shorter line
# 2022.10.27 - v. 0.6 - but fix for "tcScrTitleEnd" variable
# 2022.05.16 - v. 0.5 - small bug fix with STY unbound variable
# 2022.05.11 - v. 0.4 - set set -o options
# 2021.07.05 - v. 0.3 - added figlet displaying the current script name
# 2020.09.15 - v. 0.2 - initial release
# 2020.09.15 - v. 0.1 - initial release
#
# _script_header.sh
#
# Provide shared startup, version, dependency-check, and terminal helpers.
# print_script_history (--history): paged dump of the caller script's header changelog.
#
# Contract: sourced (not executed) by sibling scripts. Enables nounset and pipefail,
# sets LC_ALL=C, defines check_if_installed and ctrl_c, optionally installs boxes/figlet when root
# (after interactive [Y/n] prompt), sets GNU Screen window title when STY is set, optional RANDOM_DELAY when not on a tty.

if [[ "$0" = "/bin/bash" ]] || [[ "$0" = "/usr/bin/bash" ]] || [[ "$0" = "/usr/local/bin/bash" ]] ; then
  echo do not run the script standalone - only from the script ...
  return 1
fi

# exit when your script tries to use undeclared variables
set -o nounset
set -o pipefail

# set this to get proper numbers with separators - especially for smart*sh scripts which do calculations
export LC_ALL=C

_script_header_resolve_caller_script() {
  local p="" dir base found i

  # When this runs inside a function, BASH_SOURCE[1] is _script_header.sh (the call site),
  # not the script that sourced us — walk the stack and skip header frames.
  for (( i=1; i < ${#BASH_SOURCE[@]}; i++ )); do
    p="${BASH_SOURCE[i]}"
    [[ "$(basename "$p")" == "_script_header.sh" ]] && continue
    if [[ "$p" == */* && -r "$p" ]]; then
      dir="$(cd "$(dirname "$p")" && pwd -P)"
      base="$(basename "$p")"
      printf '%s/%s' "$dir" "$base"
      return 0
    fi
    if [[ -r "./$p" ]]; then
      dir="$(cd "$(dirname "./$p")" && pwd -P)"
      base="$(basename "$p")"
      printf '%s/%s' "$dir" "$base"
      return 0
    fi
    found="$(type -P "$p" 2>/dev/null || true)"
    if [[ -n "$found" && -r "$found" ]]; then
      printf '%s' "$found"
      return 0
    fi
  done

  p="${0:-}"
  if [[ "$p" == */* && -r "$p" ]]; then
    dir="$(cd "$(dirname "$p")" && pwd -P)"
    base="$(basename "$p")"
    printf '%s/%s' "$dir" "$base"
    return 0
  fi
  if [[ -r "./$p" ]]; then
    dir="$(cd "$(dirname "./$p")" && pwd -P)"
    base="$(basename "$p")"
    printf '%s/%s' "$dir" "$base"
    return 0
  fi
  found="$(type -P "$p" 2>/dev/null || true)"
  if [[ -n "$found" && -r "$found" ]]; then
    printf '%s' "$found"
    return 0
  fi
  printf '%s' "$p"
}

CALLER_SCRIPT="$(_script_header_resolve_caller_script)"
export CALLER_SCRIPT
CALLER_SCRIPT_BASENAME="$(basename "$CALLER_SCRIPT")"
export CALLER_SCRIPT_BASENAME

# Seal early (before banners / random delay) so an in-place overwrite of the live
# caller cannot splice bash's remaining source reads. Re-execs once from a temp copy.
_SCRIPT_SELF_UPDATE_HELPER="$(cd "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)/_script_self_update.sh"
if [[ -f "${_SCRIPT_SELF_UPDATE_HELPER}" ]]; then
  # shellcheck source=/dev/null
  . "${_SCRIPT_SELF_UPDATE_HELPER}"
  script_self_update_setup "${SCRIPT_SELF_LIVE_PATH:-$CALLER_SCRIPT}"
  # Seal re-exec leaves $0 as .deleteme.*.seal.*; prefer the live name for display/CLI.
  if declare -F script_self_update_apply_live_identity >/dev/null 2>&1; then
    script_self_update_apply_live_identity
  fi
fi
unset _SCRIPT_SELF_UPDATE_HELPER

# script_live_basename is defined in _script_self_update.sh (sourced above when present).
# Fallback if that helper file is missing (unusual).
if ! declare -F script_live_basename >/dev/null 2>&1; then
  script_live_basename() {
    local base
    if [[ -n "${SCRIPT_SELF_LIVE_PATH:-}" ]]; then
      base="$(basename -- "${SCRIPT_SELF_LIVE_PATH}")"
    else
      base="$(basename -- "${CALLER_SCRIPT_BASENAME:-${0:-}}")"
    fi
    case "$base" in
      .deleteme.*.seal.*)
        base="${base#.deleteme.}"
        base="${base%.seal.*}"
        ;;
    esac
    printf '%s\n' "$base"
  }
fi

SCRIPT_VERSION_NUMBER="$(
  LC_ALL=C grep -m1 -E '^# v\. [0-9]{8}\.[0-9]{6} - ' "$CALLER_SCRIPT" 2>/dev/null \
    | sed -E -n 's/^# v\. ([0-9]{8}\.[0-9]{6}) - .*/\1/p'
)"
SCRIPT_VERSION_DATE="$(
  if [[ "$SCRIPT_VERSION_NUMBER" =~ ^([0-9]{4})([0-9]{2})([0-9]{2})\.([0-9]{2})([0-9]{2})([0-9]{2})$ ]]; then
    printf '%s.%s.%s %s:%s:%s' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}" "${BASH_REMATCH[3]}" \
      "${BASH_REMATCH[4]}" "${BASH_REMATCH[5]}" "${BASH_REMATCH[6]}"
  fi
)"
if [[ -z "$SCRIPT_VERSION_NUMBER" ]]; then
  SCRIPT_VERSION_NUMBER="$(
    LC_ALL=C grep -m1 '^# [0-9]' "$CALLER_SCRIPT" 2>/dev/null \
      | sed -E -n 's/^# [0-9]{4}\.[0-9]{2}\.[0-9]{2} - v\. ([0-9]+(\.[0-9]+)*) - .*/\1/p'
  )"
  SCRIPT_VERSION_DATE="$(
    LC_ALL=C grep -m1 '^# [0-9]' "$CALLER_SCRIPT" 2>/dev/null \
      | sed -E -n 's/^# ([0-9]{4}\.[0-9]{2}\.[0-9]{2}) - v\. .*/\1/p'
  )"
fi
[[ -n "$SCRIPT_VERSION_NUMBER" ]] || SCRIPT_VERSION_NUMBER=unknown
export SCRIPT_VERSION_NUMBER SCRIPT_VERSION_DATE

print_version_banner() {
  local ver=unknown date= title verline width=60
  ver="${SCRIPT_VERSION_NUMBER:-unknown}"
  date="${SCRIPT_VERSION_DATE:-}"
  title="$(script_live_basename)"
  if [[ -n "$date" && "$ver" != unknown ]]; then
    verline="Version: ${ver} (${date})"
  else
    verline="Version: ${ver}"
  fi
  printf '┌%*s┐\n' "$width" '' | sed 's/ /─/g'
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$title"
  printf '│ %-*.*s │\n' $((width - 2)) $((width - 2)) "$verline"
  printf '└%*s┘\n' "$width" '' | sed 's/ /─/g'
}

# --- End-of-run SUMMARY chrome (shared across media / audio / video tools) ---

script_summary_rule() {
  printf '%s\n' '========================================================================'
}

# Print Script + Version as the first two summary fields (Family A).
# Optional $1 = label column width (default 22).
script_summary_print_identity() {
  local width="${1:-22}"
  local name ve

  if declare -F script_live_basename >/dev/null 2>&1; then
    name="$(script_live_basename)"
  else
    name="$(basename -- "${CALLER_SCRIPT_BASENAME:-${0:-script}}")"
  fi
  ver="${SCRIPT_VERSION_NUMBER:-unknown}"
  if [[ -n "${SCRIPT_VERSION_DATE:-}" && "$ver" != unknown ]]; then
    ver="${ver} (${SCRIPT_VERSION_DATE})"
  fi
  printf '  %-*s %s\n' "$width" "Script:" "$name"
  printf '  %-*s %s\n' "$width" "Version:" "$ver"
}

# Open a SUMMARY block (rules + timestamped title) and print Script/Version.
script_summary_begin() {
  local width="${1:-22}"
  echo
  script_summary_rule
  printf '[ %s ] SUMMARY\n' "$(date '+%Y.%m.%d %H:%M:%S')"
  script_summary_rule
  script_summary_print_identity "$width"
}

script_summary_end() {
  script_summary_rule
}

# Changelog lines from the caller script header (new # v. YYYYMMDD… and old # YYYY.MM.DD - v. …).
# Lenient: other # comments and blank lines in the preamble are skipped so mid-heade
# notes do not truncate the list; the first non-comment code line ends the scan.
script_collect_history_lines() {
  local script="${1:-${CALLER_SCRIPT:-}}"
  [[ -n "$script" && -r "$script" ]] || return 1
  awk '
    NR == 1 && /^#!/ { next }
    /^# v\. [0-9]{8}\.[0-9]{6}[[:space:]]*-/ {
      sub(/^#[[:space:]]*/, "")
      print
      next
    }
    /^# [0-9]{4}\.[0-9]{2}\.[0-9]{2}[[:space:]]*-[[:space:]]*v\./ {
      sub(/^#[[:space:]]*/, "")
      print
      next
    }
    /^#/ { next }
    /^[[:space:]]*$/ { next }
    { exit }
  ' "$script"
}

script_history_page_size() {
  local rows
  rows="$(tput lines 2>/dev/null || true)"
  [[ "$rows" =~ ^[0-9]+$ ]] || rows="${LINES:-24}"
  [[ "$rows" =~ ^[0-9]+$ ]] || rows=24
  if (( rows < 8 )); then
    printf '%s\n' 5
  else
    printf '%s\n' $(( rows - 3 ))
  fi
}

# Print caller script changelog. TTY stdout: one page at a time; More? [Y/n/q]
# (default Y, 200s). Answers from /dev/tty (SCRIPT_HISTORY_TTY override for tests).
# Piped stdout: full dump.
print_script_history() {
  local -a lines=()
  local total page i end answer timeout=200
  local script_name script_path tty_dev hist_tty_fd=-1

  script_path="${CALLER_SCRIPT:-}"
  [[ -n "$script_path" && -r "$script_path" ]] || script_path="${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}"
  script_name="$(basename -- "${CALLER_SCRIPT_BASENAME:-$script_path}")"

  mapfile -t lines < <(script_collect_history_lines "$script_path")
  total=${#lines[@]}

  if (( total == 0 )); then
    echo "${script_name}: no changelog entries found in header." >&2
    return 1
  fi

  if (( total == 1 )); then
    printf '%s changelog (1 entry):\n' "$script_name"
  else
    printf '%s changelog (%d entries):\n' "$script_name" "$total"
  fi

  tty_dev="${SCRIPT_HISTORY_TTY:-${LOUDNESS_HISTORY_TTY:-/dev/tty}}"
  if [[ ! -t 1 || ! -r "$tty_dev" ]]; then
    printf '%s\n' "${lines[@]}"
    return 0
  fi
  exec {hist_tty_fd}<"$tty_dev" || {
    printf '%s\n' "${lines[@]}"
    return 0
  }

  page="$(script_history_page_size)"
  i=0
  while (( i < total )); do
    end=$(( i + page ))
    (( end > total )) && end=$total
    printf '%s\n' "${lines[@]:i:end-i}"
    i=$end
    (( i >= total )) && break

    printf '[%s] More history? [Y/n/q] (%d/%d shown): ' \
      "$(date '+%Y.%m.%d %H:%M:%S')" "$i" "$total"
    answer=""
    if ! IFS= read -r -n 1 -t "$timeout" -u "$hist_tty_fd" answer; then
      answer=Y
    fi
    echo
    case "${answer^^}" in
      Q)
        printf '[%s] Selected: quit\n' "$(date '+%Y.%m.%d %H:%M:%S')"
        exec {hist_tty_fd}<&-
        return 0
        ;;
      N)
        printf '[%s] Selected: no (stop)\n' "$(date '+%Y.%m.%d %H:%M:%S')"
        exec {hist_tty_fd}<&-
        return 0
        ;;
      *)
        printf '[%s] Selected: yes (more)\n' "$(date '+%Y.%m.%d %H:%M:%S')"
        ;;
    esac
  done
  exec {hist_tty_fd}<&-
  return 0
}

# Optional suffix for prompt timestamps; version belongs in the window title only.
script_version_in_prompt() {
  :
}

script_version_title_prefix() {
  if [[ -n "${SCRIPT_VERSION_NUMBER:-}" && "${SCRIPT_VERSION_NUMBER}" != unknown ]]; then
    printf 'v%s ' "$SCRIPT_VERSION_NUMBER"
  fi
}

#######################################################################################
function ctrl_c() {
  echo
  echo "** Trapped CTRL-C - cleaning up...."
  echo
  if [ -n "${STY:-}" ]; then    # checking if we are running within screen
    # I am setting the screen window title to the script name
    echo -ne "${tcScrTitleStart}${CALLER_SCRIPT_BASENAME}${tcScrTitleEnd}"
  fi
  exit
}
#######################################################################################
#######################################################################################
# Prompt before apt-get install. Default Y on Enter; waits indefinitely (no timeout).
# Returns 0 if the user agrees, 1 if declined or install is not possible.
pgm_prompt_before_apt_install() {
  local pkg_list="" pkg

  if ((${#@} == 0)); then
    return 1
  fi

  for pkg in "$@"; do
    pkg_list+="${pkg} "
  done
  pkg_list="${pkg_list% }"

  if ! command -v apt-get &>/dev/null; then
    echo "(PGM) apt-get not found; cannot install: ${pkg_list}" >&2
    return 1
  fi

  if (( ! ${script_is_run_interactively:-0} )); then
    echo "(PGM) Non-interactive session — not installing: ${pkg_list}" >&2
    return 1
  fi

  if [ "$(id -u)" -ne 0 ]; then
    echo "(PGM) Not root — cannot install: ${pkg_list}. Try: apt install ${pkg_list}" >&2
    return 1
  fi

  read -r -p "Install package(s) ${pkg_list} now? [Y/n]: " ans
  case "${ans}" in
    n|N|no|NO)
      echo "(PGM) Skipped installation of: ${pkg_list}"
      return 1
      ;;
    ''|y|Y|yes|YES)
      return 0
      ;;
    *)
      echo "(PGM) Skipped installation of: ${pkg_list}"
      return 1
      ;;
  esac
}

pgm_apt_install_packages() {
  echo "#######################################################"
  apt-get -y install "$@" || true
  echo "#######################################################"
}

function check_if_installed() {
  local cmd="$1"
  local install_package="${2:-BRAK}"
  local requirement="${3:-REQUIRED}"
  local pkg

  if type -fP "${cmd}" &>/dev/null; then
    return 0
  fi

  if [ "${install_package}" != "BRAK" ]; then
    pkg="${install_package}"
  else
    pkg="${cmd}"
  fi

  echo
  echo "#######################################################"
  echo "(PGM) ${cmd} not found."

  if pgm_prompt_before_apt_install "${pkg}"; then
    echo "Proceeding with install..."
    pgm_apt_install_packages "${pkg}"
  fi
  echo "#######################################################"
  echo

  if ! type -fP "${cmd}" &>/dev/null; then
    if [[ "${requirement}" == "OPTIONAL" ]]; then
      echo "(PGM) Optional utility ${cmd} is still unavailable; continuing with plain output." >&2
      return 1
    fi
    echo "(PGM) I can't find ${cmd} utility... exiting ..." >&2
    exit 1
  fi
  return 0
}
#######################################################################################

# if we are run non-interactively - do not set the terminal title
export tcScrTitleStart="\ek"
export tcScrTitleEnd="\033\\"

check_if_installed boxes BRAK OPTIONAL || true
check_if_installed figlet BRAK OPTIONAL || true

tty 2>&1 >/dev/null
if (( $? == 0 )); then
  echo -ne "\033]0;$(script_version_title_prefix)${CALLER_SCRIPT_BASENAME}\007"
  if type -fP figlet &>/dev/null; then
    figlet -w 280 "${CALLER_SCRIPT_BASENAME}"
  else
    printf '%s\n' "${CALLER_SCRIPT_BASENAME}"
  fi
fi

if [ -n "${STY:-}" ]; then    # checking if we are running within screen
  # I am setting the screen window title to the script name
  echo -ne "${tcScrTitleStart}$(script_version_title_prefix)${CALLER_SCRIPT_BASENAME}${tcScrTitleEnd}"
fi

# trap ctrl-c and call ctrl_c()
trap ctrl_c INT

[[ -n "${profile_location_dir:-}" ]] && export profile_location_di

export HEALTHCHECKS_FILE=/root/bin/healthchecks-ids.txt
export return_code=123      # default placeholder; scripts set real exit code
export RANDOM_DELAY=0
export MAX_RANDOM_DELAY_IN_SEC=${MAX_RANDOM_DELAY_IN_SEC:-50}

export script_is_run_interactively=0

export SCRIPT_VERSION_TMP=$(
  echo "script name: ${CALLER_SCRIPT}" ;
  if [[ "${SCRIPT_VERSION_NUMBER}" != unknown ]]; then
    echo "script version: ${SCRIPT_VERSION_NUMBER} (dated ${SCRIPT_VERSION_DATE})" ;
  else
    echo "script version: unknown" ;
  fi
  echo "current date : $(date '+%Y.%m.%d %H:%M:%S')"
  echo "script is run on $(hostname)" ; echo ; echo
)

if type -fP boxes &>/dev/null; then
  SCRIPT_VERSION="$(printf '%s\n' "${SCRIPT_VERSION_TMP}" | boxes -s 50x3 -a c -d ada-box)"
else
  SCRIPT_VERSION="${SCRIPT_VERSION_TMP}"
fi
export SCRIPT_VERSION


FORCE_NO_STARTUP_DELAY_var=0

if [ $# -ne 0 ];then      # if there is an argument supplied we gonna check what is that
  case $1 in
    NO_STARTUP_DELAY|--no_startup_delay)
         FORCE_NO_STARTUP_DELAY_var=1
       ;;
    *)
       ;;
  esac
fi

tty 2>&1 >/dev/null
if (( $? != 0 )) ; then      # we set RANDOM_DELAY only when running NOT from terminal
  script_is_run_interactively=0
  export RANDOM_DELAY=$((RANDOM % $MAX_RANDOM_DELAY_IN_SEC ))
  if (( $FORCE_NO_STARTUP_DELAY_var != 1 )); then # we do the delay only when is it NOT requested by command line parameter...
    sleep $RANDOM_DELAY
  fi
else
  echo "Interactive session detected: I will NOT introduce RANDOM_DELAY...";echo
  script_is_run_interactively=1
  echo "${SCRIPT_VERSION}" ; echo
fi

#######################################################################################
# Shared terminal colors for interactive audio / media / video scripts.
# Set SCRIPT_TS_FN to a timestamp function name (e.g. mfd_ts), then call script_ask_colors.
#######################################################################################
SCRIPT_USE_COLORS=0
SCRIPT_C_G=""
SCRIPT_C_0=""
# Optional: name of a zero-arg function that prints "[ YYYY.MM.DD HH:MM:SS ]"
SCRIPT_TS_FN="${SCRIPT_TS_FN:-}"

script_colors_init() {
  SCRIPT_C_G=""
  SCRIPT_C_0=""
  if (( SCRIPT_USE_COLORS )) && [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
    SCRIPT_C_G=$'\033[32m'
    SCRIPT_C_0=$'\033[0m'
  else
    SCRIPT_USE_COLORS=0
  fi
}

script_ts_now() {
  if [[ -n "${SCRIPT_TS_FN:-}" ]] && declare -F "${SCRIPT_TS_FN}" >/dev/null 2>&1; then
    "${SCRIPT_TS_FN}"
  else
    date '+[ %Y.%m.%d %H:%M:%S ]'
  fi
}

# Timestamp (normal) + question text (green when colors on).
script_print_question() {
  if (( SCRIPT_USE_COLORS )); then
    printf '%s %s%s%s\n' "$(script_ts_now)" "$SCRIPT_C_G" "$*" "$SCRIPT_C_0"
  else
    printf '%s %s\n' "$(script_ts_now)" "$*"
  fi
}

# Menu option line; highlight "(default)" / related markers in green when colors are on.
script_echo_option() {
  local line="$*"
  if (( SCRIPT_USE_COLORS )); then
    if [[ "$line" == *'(default)'* ]]; then
      line="${line//(default)/${SCRIPT_C_G}(default)${SCRIPT_C_0}}"
    elif [[ "$line" == *'(oldest - default)'* ]]; then
      line="${line//(oldest - default)/${SCRIPT_C_G}(oldest - default)${SCRIPT_C_0}}"
    elif [[ "$line" == *', default)'* ]]; then
      line="${line//, default)/, ${SCRIPT_C_G}default${SCRIPT_C_0})}"
    elif [[ "$line" == *' is the default'* ]]; then
      line="${line// is the default/${SCRIPT_C_G} is the default${SCRIPT_C_0}}"
    fi
  fi
  printf '%s\n' "$line"
}

# Timestamp (normal) + prompt (green) for single-key reads (no newline).
script_printf_prompt() {
  local prompt="$*"
  if (( SCRIPT_USE_COLORS )); then
    printf '%s %s%s%s' "$(script_ts_now)" "$SCRIPT_C_G" "$prompt" "$SCRIPT_C_0"
  else
    printf '%s %s' "$(script_ts_now)" "$prompt"
  fi
}


#######################################################################################
# Shared Up/Down arrow menu for interactive audio / media / video scripts.
# Usage: script_arrow_menu DEFAULT_KEY "key|label" "key|label" ...
# Sets REPLY to the chosen key (lowercase). Up/Down move; Enter accepts;
# pressing a listed key accepts immediately. Digits 1/2 map to y/n when those
# keys are options and 1/2 are not. Non-TTY: static list + one-key read.
#######################################################################################
SCRIPT_ARROW_STTY=""

script_arrow_menu_restore_tty() {
  printf '\033[?25h' 2>/dev/null || true
  if [[ -n "${SCRIPT_ARROW_STTY:-}" ]]; then
    stty "$SCRIPT_ARROW_STTY" 2>/dev/null || true
    SCRIPT_ARROW_STTY=""
  fi
}

script_arrow_choice() {
  local c="${1,,}"
  c="${c//$'\r'/}"
  c="${c//$'\n'/}"
  printf '%s' "$c"
}

script_arrow_key_disp() {
  local key="$1" def="$2"
  if [[ "$(script_arrow_choice "$key")" == "$(script_arrow_choice "$def")" ]]; then
    printf '%s' "${key^^}"
  else
    printf '%s' "$key"
  fi
}

script_arrow_def_mark() {
  local key="$1" def="$2" label="${3:-}"
  [[ "$(script_arrow_choice "$key")" == "$(script_arrow_choice "$def")" ]] || return 0
  [[ "$label" == *'(default)'* || "$label" == *'(oldest - default)'* ]] && return 0
  printf ' (default)'
}

script_arrow_flush_stdin() {
  local discard drained=0
  while (( drained < 256 )) && IFS= read -r -t 0.02 -n 1 discard; do
    ((++drained)) || true
  done
}

script_arrow_menu_has_key() {
  local want="$1" k
  shift
  for k in "$@"; do
    [[ "$(script_arrow_choice "$k")" == "$want" ]] && return 0
  done
  return 1
}

# $1 = default key (may be empty = no default; Enter still accepts highlight).
# Remaining: "key|label" options.
script_arrow_menu() {
  local def_key="${1:-}"
  shift
  local -a keys=() labels=()
  local item i n idx=0
  local byte="" c2="" c3="" ch="" accepted=0
  local rows=0 has_y=0 has_n=0 has_1=0 has_2=0
  local key_disp mark line

  for item in "$@"; do
    keys+=("${item%%|*}")
    labels+=("${item#*|}")
  done
  n=${#keys[@]}
  (( n > 0 )) || {
    REPLY="$(script_arrow_choice "$def_key")"
    return 1
  }

  def_key="$(script_arrow_choice "$def_key")"
  if [[ -n "$def_key" ]]; then
    for (( i = 0; i < n; i++ )); do
      if [[ "$(script_arrow_choice "${keys[i]}")" == "$def_key" ]]; then
        idx=$i
        break
      fi
    done
  fi

  for (( i = 0; i < n; i++ )); do
    case "$(script_arrow_choice "${keys[i]}")" in
      y) has_y=1 ;;
      n) has_n=1 ;;
      1) has_1=1 ;;
      2) has_2=1 ;;
    esac
  done

  if [[ ! -t 0 || ! -t 1 ]]; then
    for (( i = 0; i < n; i++ )); do
      key_disp="$(script_arrow_key_disp "${keys[i]}" "$def_key")"
      mark="$(script_arrow_def_mark "${keys[i]}" "$def_key" "${labels[i]}")"
      if declare -F script_echo_option >/dev/null 2>&1; then
        script_echo_option "  [${key_disp}] ${labels[i]}${mark}"
      else
        printf '  [%s] %s%s\n' "$key_disp" "${labels[i]}" "$mark"
      fi
    done
    echo
    if [[ -n "$def_key" ]]; then
      if declare -F script_printf_prompt >/dev/null 2>&1; then
        script_printf_prompt "Choice: "
      else
        printf 'Choice: '
      fi
    else
      printf 'Choice: '
    fi
    script_arrow_flush_stdin
    byte=""
    read -n 1 byte || byte=""
    echo
    ch="$(script_arrow_choice "$byte")"
    if [[ -z "$ch" && -n "$def_key" ]]; then
      REPLY="$def_key"
      return 0
    fi
    if (( has_y && has_n && ! has_1 && ! has_2 )); then
      case "$ch" in
        1) ch=y ;;
        2) ch=n ;;
      esac
    fi
    REPLY="$ch"
    return 0
  fi

  script_arrow_menu_draw() {
    local j
    for (( j = 0; j < n; j++ )); do
      key_disp="$(script_arrow_key_disp "${keys[j]}" "$def_key")"
      mark="$(script_arrow_def_mark "${keys[j]}" "$def_key" "${labels[j]}")"
      if (( j == idx )); then
        if (( SCRIPT_USE_COLORS )); then
          printf ' %s>%s [%s] %s%s%s%s\n' \
            "$SCRIPT_C_G" "$SCRIPT_C_0" "$key_disp" \
            "$SCRIPT_C_G" "${labels[j]}" "$mark" "$SCRIPT_C_0"
        else
          printf ' > [%s] %s%s\n' "$key_disp" "${labels[j]}" "$mark"
        fi
      else
        line="   [${key_disp}] ${labels[j]}${mark}"
        if declare -F script_echo_option >/dev/null 2>&1; then
          script_echo_option "$line"
        else
          printf '%s\n' "$line"
        fi
      fi
    done
    echo
    if (( SCRIPT_USE_COLORS )); then
      printf '  %sUp/Down move · Enter select · or press a listed key%s\n' \
        "$SCRIPT_C_G" "$SCRIPT_C_0"
    else
      echo "  Up/Down move · Enter select · or press a listed key"
    fi
  }

  SCRIPT_ARROW_STTY="$(stty -g 2>/dev/null || true)"
  stty -echo -icanon min 1 time 0 2>/dev/null || true
  printf '\033[?25l'
  script_arrow_flush_stdin
  script_arrow_menu_draw
  rows=$((n + 2))

  while (( ! accepted )); do
    byte=""
    IFS= read -r -n 1 byte || byte=""
    if [[ "$byte" == $'\033' ]]; then
      c2=""
      c3=""
      IFS= read -r -t 0.05 -n 1 c2 || c2=""
      if [[ "$c2" == '[' || "$c2" == 'O' ]]; then
        IFS= read -r -t 0.05 -n 1 c3 || c3=""
        case "$c3" in
          A)
            if (( idx > 0 )); then
              idx=$((idx - 1))
            fi
            printf '\033[%dA' "$rows"
            script_arrow_menu_draw
            continue
            ;;
          B)
            if (( idx < n - 1 )); then
              idx=$((idx + 1))
            fi
            printf '\033[%dA' "$rows"
            script_arrow_menu_draw
            continue
            ;;
        esac
      fi
      continue
    fi

    if [[ -z "$byte" || "$byte" == $'\n' || "$byte" == $'\r' ]]; then
      REPLY="$(script_arrow_choice "${keys[idx]}")"
      accepted=1
      break
    fi

    ch="$(script_arrow_choice "$byte")"
    if (( has_y && has_n && ! has_1 && ! has_2 )); then
      case "$ch" in
        1) ch=y ;;
        2) ch=n ;;
      esac
    fi

    for (( i = 0; i < n; i++ )); do
      if [[ "$(script_arrow_choice "${keys[i]}")" == "$ch" ]]; then
        idx=$i
        REPLY="$ch"
        accepted=1
        printf '\033[%dA' "$rows"
        script_arrow_menu_draw
        break
      fi
    done
  done

  script_arrow_menu_restore_tty
  echo
  return 0
}

# Ask once. Default Yes. Pass 1 as $1 when -y / non-interactive should skip (colors off).
# Returns via exit 0 on Quit. Sets SCRIPT_USE_COLORS and color codes.
script_ask_colors() {
  local do_yes="${1:-0}"
  SCRIPT_USE_COLORS=0
  script_colors_init
  if (( do_yes )) || (( ! script_is_run_interactively )); then
    return 0
  fi
  if [[ ! -t 1 || ! -t 0 ]] || [[ -n "${NO_COLOR:-}" ]]; then
    return 0
  fi
  SCRIPT_USE_COLORS=1
  script_colors_init
  echo
  script_print_question "Use colors in the terminal?"
  echo
  script_arrow_menu y \
    "y|Yes" \
    "n|No" \
    "q|Quit"
  case "$(script_arrow_choice "$REPLY")" in
    y|"") SCRIPT_USE_COLORS=1 ;;
    n) SCRIPT_USE_COLORS=0 ;;
    q)
      echo "$(script_ts_now) Quit."
      return_code=0
      if [[ -f "${profile_location_dir:-$HOME}/bin/_script_footer.sh" ]]; then
        # shellcheck disable=SC1090
        . "${profile_location_dir:-$HOME}/bin/_script_footer.sh"
      fi
      exit 0
      ;;
    *) SCRIPT_USE_COLORS=1 ;;
  esac
  script_colors_init
}
