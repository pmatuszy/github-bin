#!/bin/bash
# v. 20260811.155244 - Ctrl-C during any-key pause returns to menu immediately (no second key)
# v. 20260811.154553 - colors prompt defaults to Y (S_COLORS=auto)
# v. 20260811.153637 - Ctrl-C during report returns to menu (q still quits); override header exit trap
# v. 20260811.153209 - show sar command at top of report screen (after clear)
# v. 20260811.152756 - UI mode default: 1 if dialog installed, else 2; Quit tag q
# v. 20260811.152232 - after report return to main menu; single-key pause (no Enter / no "again?" ask)
# v. 20260811.151804 - run sar with S_COLORS=... prefix; avoid shadowed env shell function
# v. 20260811.151030 - nicer WithDialog look: dialogrc colors/shadows, PuTTY-safe line drawing
# v. 20260811.150911 - pause after sar output so dialog does not wipe the report immediately
# v. 20260811.150417 - non-root: check usable SAR history; only root is asked to enable collection
# v. 20260811.145638 - interactive sar browser: WithDialog/WithoutDialog, colors, collection check
#
# sar-pgm-interactive.sh
#
# Interactive wrapper around sar (sysstat): choose UI mode, colors (default on),
# optionally enable data collection, then pick CPU/memory/swap/disk/network/load reports.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--history]

Interactive wrapper around sar (sysstat).

UI modes:
  WithDialog     — dialog menus / yes-no boxes (install offered only as root, default N)
  WithoutDialog  — plain questions

Default UI mode: 1 if dialog is installed, otherwise 2.
UI mode prompt: single key 1/2/q (no Enter).

Always starts without the random cron startup delay.

Ctrl-C while a report is running cancels that report and returns to the
statistics menu (choose q to quit). Ctrl-C outside a report exits.

WithDialog appearance uses a private dialogrc (colors + shadows) and
NCURSES_NO_UTF8_ACS=1 so frames render better in PuTTY. If boxes still look
wrong, run:  SAR_DIALOG_ASCII_LINES=1 $(basename "$0")

Options:
  -h, --help     Show this help and exit.
  -v, --version  Print script version and exit.
  --history      Print script changelog from the header and exit.
EOF
}

. /root/bin/_script_header.sh NO_STARTUP_DELAY

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    --history) print_script_history; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

check_if_installed sar sysstat

################################################################################
# Globals
################################################################################

USE_DIALOG=0
S_COLORS_VALUE=auto
SAR_OPTS=()
SA_DIR=""
DIALOG_RC_FILE=""
SAR_PGM_IN_REPORT=0
SAR_PGM_INTERRUPTED=0

# Interactive browser: Ctrl-C during a report returns to the menu (do not exit).
# Outside a report, keep the usual exit behaviour from _script_header.sh.
sar_pgm_on_int() {
  echo
  if (( SAR_PGM_IN_REPORT )); then
    SAR_PGM_INTERRUPTED=1
    echo "(PGM) Interrupted — returning to menu (choose q to quit)."
    return 0
  fi
  echo "(PGM) Interrupted — exiting."
  cleanup_dialog_rc
  if [ -n "${STY:-}" ]; then
    echo -ne "${tcScrTitleStart}bash${tcScrTitleEnd}"
  fi
  exit 130
}
trap sar_pgm_on_int INT

################################################################################
# Helpers
################################################################################

cleanup_dialog_rc() {
  if [[ -n "${DIALOG_RC_FILE:-}" && -f "${DIALOG_RC_FILE}" ]]; then
    rm -f "${DIALOG_RC_FILE}"
  fi
}

setup_dialog_look() {
  # Colors + shadows via a private dialogrc; fix broken frames in PuTTY/SSH.
  DIALOG_RC_FILE="$(mktemp "${TMPDIR:-/tmp}/sar-pgm-dialogrc.XXXXXX")"
  cat > "${DIALOG_RC_FILE}" <<'EOF'
# Temporary dialogrc for sar-pgm-interactive.sh
aspect = 0
separate_widget = ""
tab_len = 0
visit_items = ON
use_shadow = ON
use_colors = ON
screen_color = (CYAN,BLACK,ON)
shadow_color = (BLACK,BLACK,ON)
dialog_color = (BLACK,WHITE,OFF)
title_color = (BLUE,WHITE,ON)
border_color = (WHITE,WHITE,ON)
border2_color = border_color
button_active_color = (WHITE,BLUE,ON)
button_inactive_color = (BLACK,WHITE,OFF)
button_key_active_color = (WHITE,BLUE,ON)
button_key_inactive_color = (RED,WHITE,OFF)
button_label_active_color = (YELLOW,BLUE,ON)
button_label_inactive_color = (BLACK,WHITE,ON)
inputbox_color = dialog_color
inputbox_border_color = border_color
inputbox_border2_color = border_color
menubox_color = dialog_color
menubox_border_color = border_color
menubox_border2_color = border_color
item_color = dialog_color
item_selected_color = button_active_color
tag_color = (BLUE,WHITE,ON)
tag_selected_color = (WHITE,BLUE,ON)
tag_key_color = (RED,WHITE,OFF)
tag_key_selected_color = (YELLOW,BLUE,ON)
form_active_text_color = button_active_color
form_text_color = dialog_color
form_item_readonly_color = (CYAN,WHITE,ON)
gauge_color = (BLUE,WHITE,ON)
EOF
  export DIALOGRC="${DIALOG_RC_FILE}"
  # PuTTY + UTF-8 often breaks ACS frames; prefer Unicode box-drawing chars
  export NCURSES_NO_UTF8_ACS=1
  export DIALOGOPTS="--backtitle sar-pgm-interactive.sh --shadow"
  trap cleanup_dialog_rc EXIT
}

run_dialog() {
  # Single entry point so look/options stay consistent.
  # --ascii-lines is a fallback only when Unicode frames still look wrong:
  # set SAR_DIALOG_ASCII_LINES=1 to force ASCII + - | frames.
  if [[ "${SAR_DIALOG_ASCII_LINES:-0}" == "1" ]]; then
    dialog --ascii-lines "$@"
  else
    dialog "$@"
  fi
}

is_root() {
  [ "$(id -u)" -eq 0 ]
}

resolve_sa_dir() {
  if [[ -d /var/log/sysstat ]]; then
    SA_DIR=/var/log/sysstat
  elif [[ -d /var/log/sa ]]; then
    SA_DIR=/var/log/sa
  else
    SA_DIR=/var/log/sysstat
  fi
}

prompt_yn_default_no() {
  # WithoutDialog yes/no; default N. Returns 0=yes, 1=no.
  local prompt="$1"
  local ans=""
  read -r -p "${prompt} [y/N]: " ans || true
  case "${ans}" in
    y|Y|yes|YES) return 0 ;;
    *) return 1 ;;
  esac
}

prompt_yn_default_yes() {
  # WithoutDialog yes/no; default Y. Returns 0=yes, 1=no.
  local prompt="$1"
  local ans=""
  read -r -p "${prompt} [Y/n]: " ans || true
  case "${ans}" in
    n|N|no|NO) return 1 ;;
    *) return 0 ;;
  esac
}

dialog_yesno_default_no() {
  # Returns 0=yes, 1=no/cancel.
  local title="$1"
  local text="$2"
  run_dialog --title "${title}" --defaultno --yesno "${text}" 10 60
}

dialog_yesno_default_yes() {
  # Returns 0=yes, 1=no/cancel. Yes is the default button.
  local title="$1"
  local text="$2"
  run_dialog --title "${title}" --yesno "${text}" 10 60
}

ask_yes_no_default_no() {
  local title="$1"
  local text="$2"
  if (( USE_DIALOG )); then
    dialog_yesno_default_no "${title}" "${text}"
  else
    prompt_yn_default_no "${text}"
  fi
}

ask_yes_no_default_yes() {
  local title="$1"
  local text="$2"
  if (( USE_DIALOG )); then
    dialog_yesno_default_yes "${title}" "${text}"
  else
    prompt_yn_default_yes "${text}"
  fi
}

plain_menu() {
  # Args: prompt default_key then pairs of key label...
  # Sets PLAIN_MENU_CHOICE. Returns 1 on quit/empty cancel.
  local prompt="$1"
  local default_key="$2"
  shift 2
  local key label
  local -a keys=()
  echo
  echo "${prompt}"
  echo
  while [[ $# -gt 0 ]]; do
    key="$1"
    label="$2"
    shift 2
    keys+=("${key}")
    printf "  %s) %s\n" "${key}" "${label}"
  done
  echo
  local ans=""
  read -r -p "Choice [${default_key}]: " ans || true
  ans="${ans:-${default_key}}"
  local k
  for k in "${keys[@]}"; do
    if [[ "${ans}" == "${k}" ]]; then
      PLAIN_MENU_CHOICE="${ans}"
      return 0
    fi
  done
  echo "(PGM) Invalid choice: ${ans}" >&2
  return 1
}

dialog_menu() {
  # Args: title prompt default_tag then pairs of tag item...
  # Sets DIALOG_MENU_CHOICE. Returns 1 on cancel.
  local title="$1"
  local prompt="$2"
  local default_tag="$3"
  shift 3
  local tmp rc
  tmp="$(mktemp)"
  # dialog --menu text height width menu-height tag item ...
  if run_dialog --title "${title}" --default-item "${default_tag}" --menu "${prompt}" 0 0 0 "$@" 2>"${tmp}"; then
    DIALOG_MENU_CHOICE="$(cat "${tmp}")"
    rm -f "${tmp}"
    return 0
  fi
  rc=$?
  rm -f "${tmp}"
  return "${rc}"
}

ask_menu() {
  # Sets MENU_CHOICE. title prompt default then tag label pairs.
  local title="$1"
  local prompt="$2"
  local default_tag="$3"
  shift 3
  if (( USE_DIALOG )); then
    if dialog_menu "${title}" "${prompt}" "${default_tag}" "$@"; then
      MENU_CHOICE="${DIALOG_MENU_CHOICE}"
      return 0
    fi
    return 1
  fi
  if plain_menu "${prompt}" "${default_tag}" "$@"; then
    MENU_CHOICE="${PLAIN_MENU_CHOICE}"
    return 0
  fi
  return 1
}

ask_input() {
  # Sets INPUT_VALUE. title prompt default
  local title="$1"
  local prompt="$2"
  local default="$3"
  local tmp ans
  if (( USE_DIALOG )); then
    tmp="$(mktemp)"
    if run_dialog --title "${title}" --inputbox "${prompt}" 10 60 "${default}" 2>"${tmp}"; then
      INPUT_VALUE="$(cat "${tmp}")"
      rm -f "${tmp}"
      INPUT_VALUE="${INPUT_VALUE:-${default}}"
      return 0
    fi
    rm -f "${tmp}"
    return 1
  fi
  read -r -p "${prompt} [${default}]: " ans || true
  INPUT_VALUE="${ans:-${default}}"
  return 0
}

################################################################################
# UI mode + dialog install
################################################################################

choose_ui_mode() {
  # Always plain prompts here (dialog may be missing; USE_DIALOG still unset).
  # Single key 1 / 2 / q — no Enter required.
  # Default: 1 if dialog is installed, else 2.
  local key="" default_key=2
  if type -fP dialog &>/dev/null; then
    default_key=1
  fi

  while true; do
    echo
    echo "Choose UI mode:"
    echo
    echo "  1) WithDialog — menus / yes-no boxes (dialog)"
    echo "  2) WithoutDialog — plain questions"
    echo "  q) Quit"
    echo
    if [[ "${default_key}" == "1" ]]; then
      echo "(PGM) dialog found — default WithDialog."
    else
      echo "(PGM) dialog not found — default WithoutDialog."
    fi
    printf '%s' "Choice [${default_key}]: "
    key=""
    read -r -n 1 key || true
    echo
    case "${key}" in
      1)
        USE_DIALOG=1
        return 0
        ;;
      2)
        USE_DIALOG=0
        return 0
        ;;
      '')
        if [[ "${default_key}" == "1" ]]; then
          USE_DIALOG=1
        else
          USE_DIALOG=0
        fi
        return 0
        ;;
      q|Q)
        echo "(PGM) Done."
        exit 0
        ;;
      *)
        echo "(PGM) Please press 1, 2, or q."
        ;;
    esac
  done
}

ensure_dialog_if_needed() {
  if (( ! USE_DIALOG )); then
    return 0
  fi
  if type -fP dialog &>/dev/null; then
    setup_dialog_look
    echo "(PGM) Using WithDialog (colors/shadows; PuTTY-safe frames)."
    echo "(PGM) If frames still look wrong: SAR_DIALOG_ASCII_LINES=1 $0"
    return 0
  fi

  echo
  echo "(PGM) 'dialog' is not installed (needed for WithDialog)."

  if ! is_root; then
    echo "(PGM) Not running as root — cannot install packages."
    echo "(PGM) Falling back to WithoutDialog."
    USE_DIALOG=0
    return 0
  fi

  if ! command -v apt-get &>/dev/null; then
    echo "(PGM) apt-get not found; cannot install dialog."
    echo "(PGM) Falling back to WithoutDialog."
    USE_DIALOG=0
    return 0
  fi

  if prompt_yn_default_no "Install package 'dialog' now?"; then
    echo "Proceeding with install..."
    pgm_apt_install_packages dialog
  else
    echo "(PGM) Skipped installation of: dialog"
  fi

  if type -fP dialog &>/dev/null; then
    setup_dialog_look
    echo "(PGM) Continuing with WithDialog (colors/shadows; PuTTY-safe frames)."
    echo "(PGM) If frames still look wrong: SAR_DIALOG_ASCII_LINES=1 $0"
    USE_DIALOG=1
  else
    echo "(PGM) dialog still unavailable — falling back to WithoutDialog."
    USE_DIALOG=0
  fi
}

################################################################################
# Colors
################################################################################

choose_colors() {
  if ask_yes_no_default_yes "Colors" "Use colors in sar output?"; then
    S_COLORS_VALUE=auto
    echo "(PGM) Colors: on (S_COLORS=auto)."
  else
    S_COLORS_VALUE=never
    echo "(PGM) Colors: off (S_COLORS=never)."
  fi
  export S_COLORS="${S_COLORS_VALUE}"
}

################################################################################
# Collection detect / enable
################################################################################

collection_looks_active() {
  if [[ -f /etc/default/sysstat ]]; then
    if grep -Eq '^ENABLED=["'\'']?true["'\'']?' /etc/default/sysstat; then
      # ENABLED=true is enough on Debian even before first sample
      return 0
    fi
  fi

  if systemctl is-active --quiet sysstat-collect.timer 2>/dev/null; then
    return 0
  fi
  if systemctl is-active --quiet sysstat.service 2>/dev/null; then
    return 0
  fi
  if systemctl is-active --quiet sysstat 2>/dev/null; then
    return 0
  fi

  # Any recent sa file in the last 2 days
  if [[ -d "${SA_DIR}" ]] && find "${SA_DIR}" -maxdepth 1 -type f \( -name 'sa[0-9][0-9]' -o -name 'sa[0-9]' \) -mtime -2 2>/dev/null | grep -q .; then
    return 0
  fi

  return 1
}

print_collection_status() {
  local today
  today="$(date +%d)"
  echo
  echo "(PGM) Checking sysstat / SAR data collection..."
  echo "  data dir .......... ${SA_DIR}"
  if type -fP systemctl &>/dev/null; then
    if systemctl is-active --quiet sysstat-collect.timer 2>/dev/null; then
      echo "  collect timer ..... active"
    elif systemctl is-active --quiet sysstat 2>/dev/null; then
      echo "  sysstat ........... active"
    else
      echo "  systemd ........... no active sysstat collect timer/service"
    fi
  fi
  if [[ -f /etc/default/sysstat ]]; then
    if grep -Eq '^ENABLED=["'\'']?true["'\'']?' /etc/default/sysstat; then
      echo "  ENABLED ........... true (/etc/default/sysstat)"
    else
      echo "  ENABLED ........... false/other (/etc/default/sysstat)"
    fi
  fi
  if [[ -f "${SA_DIR}/sa${today}" ]]; then
    echo "  today's file ...... sa${today} (present)"
  else
    echo "  today's file ...... sa${today} (missing)"
  fi
}

enable_sar_collection() {
  echo
  echo "(PGM) Enabling SAR data collection..."

  if [[ -f /etc/default/sysstat ]]; then
    if grep -q '^ENABLED=' /etc/default/sysstat; then
      sed -i 's/^ENABLED=.*/ENABLED="true"/' /etc/default/sysstat
    else
      echo 'ENABLED="true"' >> /etc/default/sysstat
    fi
    echo "(PGM) Set ENABLED=\"true\" in /etc/default/sysstat"
  fi

  if type -fP systemctl &>/dev/null; then
    systemctl enable --now sysstat 2>/dev/null || true
    systemctl enable --now sysstat-collect.timer 2>/dev/null || true
    systemctl enable --now sysstat-summary.timer 2>/dev/null || true
    # Debian package often uses sysstat.service which manages the timers
    systemctl restart sysstat 2>/dev/null || true
  fi

  if type -fP service &>/dev/null; then
    service sysstat start 2>/dev/null || true
  fi

  # Seed one sample if sa1 exists
  if [[ -x /usr/lib/sysstat/sa1 ]]; then
    /usr/lib/sysstat/sa1 1 1 2>/dev/null || true
  elif [[ -x /usr/lib64/sa/sa1 ]]; then
    /usr/lib64/sa/sa1 1 1 2>/dev/null || true
  fi

  echo "(PGM) Enable steps finished."
  echo "(PGM) Note: richer history appears after further collect intervals (~10 min)."
}

can_use_sar_history() {
  # Non-root (and root): can we actually read collected sa files?
  local f today
  today="$(date +%d)"

  if [[ ! -d "${SA_DIR}" ]]; then
    echo "(PGM) History: SA dir missing (${SA_DIR}) — live sampling only."
    return 1
  fi
  if [[ ! -r "${SA_DIR}" ]]; then
    echo "(PGM) History: SA dir not readable (${SA_DIR}) — live sampling only."
    return 1
  fi

  # Prefer today's file; otherwise any readable saDD
  if [[ -f "${SA_DIR}/sa${today}" ]]; then
    if [[ -r "${SA_DIR}/sa${today}" ]]; then
      if S_COLORS=never sar -u -f "${SA_DIR}/sa${today}" 1>/dev/null 2>&1; then
        echo "(PGM) History: usable (can read ${SA_DIR}/sa${today})."
        return 0
      fi
      echo "(PGM) History: sa${today} present but sar cannot read it — live sampling only."
      return 1
    fi
    echo "(PGM) History: sa${today} present but not readable — live sampling only."
    return 1
  fi

  for f in "${SA_DIR}"/sa[0-9]*; do
    [[ -f "${f}" && -r "${f}" ]] || continue
    if S_COLORS=never sar -u -f "${f}" 1>/dev/null 2>&1; then
      echo "(PGM) History: usable (can read $(basename "${f}"); today's sa${today} missing)."
      return 0
    fi
  done

  echo "(PGM) History: no readable sa* files in ${SA_DIR} — live sampling only."
  return 1
}

maybe_offer_enable_collection() {
  print_collection_status

  if is_root; then
    if collection_looks_active; then
      echo "(PGM) SAR data collection looks active."
      can_use_sar_history || true
      return 0
    fi

    echo
    echo "(PGM) SAR data collection does not appear to be running."
    echo "(PGM) Without it, history (today / past days) may be empty; live sampling still works."

    if ask_yes_no_default_no "Enable collection" "Enable SAR data collection now?"; then
      enable_sar_collection
      can_use_sar_history || true
    else
      echo "(PGM) Continuing without enabling collection."
      can_use_sar_history || true
    fi
    return 0
  fi

  # Non-root: never ask to enable; only report whether history is usable.
  echo
  if collection_looks_active; then
    echo "(PGM) SAR data collection looks active on this host."
  else
    echo "(PGM) SAR data collection does not appear to be running on this host."
  fi
  echo "(PGM) Not root — will not offer to enable collection."
  can_use_sar_history || true
}

################################################################################
# Stats + time range + run
################################################################################

choose_stat_type() {
  if ! ask_menu "Statistics" "What would you like to see?" "1" \
      1 "CPU utilization (sar -u)" \
      2 "Memory (sar -r)" \
      3 "Swap (sar -S)" \
      4 "Disk I/O per device (sar -d -p)" \
      5 "Block I/O totals (sar -b)" \
      6 "Network interfaces (sar -n DEV)" \
      7 "Load / run queue (sar -q)" \
      q "Quit"; then
    return 1
  fi
  case "${MENU_CHOICE}" in
    q|Q) return 1 ;;
    1) SAR_OPTS=(-u) ;;
    2) SAR_OPTS=(-r) ;;
    3) SAR_OPTS=(-S) ;;
    4) SAR_OPTS=(-d -p) ;;
    5) SAR_OPTS=(-b) ;;
    6) SAR_OPTS=(-n DEV) ;;
    7) SAR_OPTS=(-q) ;;
    *) echo "(PGM) Invalid choice."; return 1 ;;
  esac
  return 0
}

normalize_time() {
  # Accept HH:MM or HH:MM:SS → HH:MM:SS
  local t="$1"
  if [[ "${t}" =~ ^[0-9]{1,2}:[0-9]{2}$ ]]; then
    printf '%s:00' "${t}"
  else
    printf '%s' "${t}"
  fi
}

list_sa_days_hint() {
  local f found=0
  if [[ ! -d "${SA_DIR}" ]]; then
    echo "(PGM) No SA dir yet: ${SA_DIR}"
    return
  fi
  echo "(PGM) Available files in ${SA_DIR}:"
  for f in "${SA_DIR}"/sa[0-9]*; do
    [[ -f "${f}" ]] || continue
    printf "  %s\n" "$(basename "${f}")"
    found=1
  done
  if (( ! found )); then
    echo "  (none)"
  fi
}

choose_and_run_report() {
  local mode day start_t end_t interval count sa_file
  local -a cmd

  if ! ask_menu "Time range" "Time range?" "1" \
      1 "Today (from collected logs)" \
      2 "Specific day (saDD file)" \
      3 "Live sample (interval x count)" \
      4 "Time window today"; then
    return 1
  fi
  mode="${MENU_CHOICE}"

  cmd=(sar "${SAR_OPTS[@]}")

  case "${mode}" in
    1)
      ;;
    2)
      list_sa_days_hint
      day="$(date +%d)"
      if ! ask_input "Day" "Day number (DD)" "${day}"; then
        return 1
      fi
      day="$(printf '%02d' "$((10#${INPUT_VALUE}))" 2>/dev/null || printf '%s' "${INPUT_VALUE}")"
      sa_file="${SA_DIR}/sa${day}"
      if [[ ! -f "${sa_file}" ]]; then
        echo "(PGM) File not found: ${sa_file}" >&2
        return 1
      fi
      cmd+=(-f "${sa_file}")
      ;;
    3)
      if ! ask_input "Interval" "Interval in seconds" "1"; then
        return 1
      fi
      interval="${INPUT_VALUE}"
      if ! ask_input "Samples" "Number of samples" "5"; then
        return 1
      fi
      count="${INPUT_VALUE}"
      cmd+=("${interval}" "${count}")
      ;;
    4)
      if ! ask_input "Start" "Start time (HH:MM or HH:MM:SS)" "00:00:00"; then
        return 1
      fi
      start_t="$(normalize_time "${INPUT_VALUE}")"
      if ! ask_input "End" "End time (HH:MM or HH:MM:SS)" "23:59:59"; then
        return 1
      fi
      end_t="$(normalize_time "${INPUT_VALUE}")"
      cmd+=(-s "${start_t}" -e "${end_t}")
      ;;
    *)
      echo "(PGM) Invalid time range."; return 1 ;;
  esac

  # Leave dialog screen; show command + sar on the real terminal
  if (( USE_DIALOG )); then
    clear
  fi
  echo "(PGM) Running:"
  printf '  S_COLORS=%q ' "${S_COLORS_VALUE}"
  printf '%q ' "${cmd[@]}"
  echo
  echo
  SAR_PGM_INTERRUPTED=0
  SAR_PGM_IN_REPORT=1
  # Do not use "env VAR=val cmd" — a shell function named env may shadow /usr/bin/env
  S_COLORS="${S_COLORS_VALUE}" "${cmd[@]}" || true
  local rc=$?
  echo
  if (( SAR_PGM_INTERRUPTED )); then
    SAR_PGM_IN_REPORT=0
    return 0
  fi
  if (( rc != 0 )); then
    echo "(PGM) sar exited with status ${rc}." >&2
  fi
  # dialog redraws the whole screen; wait so the user can read sar output first
  pause_to_read_report
  SAR_PGM_IN_REPORT=0
  return 0
}

pause_to_read_report() {
  # One key continues; Ctrl-C sets SAR_PGM_INTERRUPTED in the trap.
  # read -n 1 alone would still block after the trap (Ctrl-C is not the key),
  # so use a short timeout loop and exit as soon as the flag is set.
  local _ans=""
  echo
  printf '%s' "(PGM) Press any key to continue..."
  while true; do
    if (( SAR_PGM_INTERRUPTED )); then
      echo
      return 0
    fi
    if read -r -n 1 -s -t 1 _ans; then
      echo
      return 0
    fi
  done
}

################################################################################
# Main
################################################################################

resolve_sa_dir
choose_ui_mode
ensure_dialog_if_needed
choose_colors
maybe_offer_enable_collection

while true; do
  if ! choose_stat_type; then
    echo "(PGM) Done."
    break
  fi
  choose_and_run_report || true
  # After the report + key pause, return to the main statistics menu
done

. /root/bin/_script_footer.sh
