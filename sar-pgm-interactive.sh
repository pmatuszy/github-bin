#!/bin/bash
# v. 20260811.225554 - after specific-day report return to day list; title shows SA path + count
# v. 20260811.225430 - day list: show SA dir path + file count; menu height lists all (scroll)
# v. 20260811.224531 - specific day: pick from sa* list (YYYY.MM.DD, weekday, days ago)
# v. 20260811.164738 - color toggle: show currently ON/OFF in menu and after toggle
# v. 20260811.164425 - statistics menu: c color toggle only (no dashed separator row)
# v. 20260811.164149 - statistics menu: dashed separator + c color toggle (ON/OFF)
# v. 20260811.163640 - always use ASCII dialog borders (--ascii-lines); drop frame auto-detect
# v. 20260811.163343 - auto ASCII dialog frames when TERM/UTF-8 ACS likely broken; optional frame check
# v. 20260811.160740 - page long history reports with less (else more); live samples stay unpaged
# v. 20260811.155854 - WithoutDialog menus: single-key choice; time range has q to quit
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
WithoutDialog prompts use a single key (no Enter); menus include q to quit.

Always starts without the random cron startup delay.

Ctrl-C while a report is running cancels that report and returns to the
statistics menu (choose q to quit). Ctrl-C outside a report exits.

History / time-window reports are paged with less if available, otherwise more.
Live samples are not paged (they stream to the terminal).

WithDialog appearance uses a private dialogrc (colors + shadows) and
always ASCII borders (--ascii-lines: + - |), which render reliably everywhere.

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
CHOSEN_SA_FILE=""
LAST_CHOSEN_SA_FILE=""

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
  # Colors + shadows via a private dialogrc; always ASCII borders (reliable on all TERMs).
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
  export DIALOGOPTS="--backtitle sar-pgm-interactive.sh --shadow --ascii-lines"
  trap cleanup_dialog_rc EXIT
}

run_dialog() {
  # Always ASCII borders (+ - |) — consistent and readable on every terminal.
  dialog --ascii-lines "$@"
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
  # WithoutDialog yes/no; default N. Single key, no Enter. Returns 0=yes, 1=no.
  local prompt="$1"
  local ans=""
  printf '%s' "${prompt} [y/N]: "
  read -r -n 1 ans || true
  echo
  case "${ans}" in
    y|Y) return 0 ;;
    *) return 1 ;;
  esac
}

prompt_yn_default_yes() {
  # WithoutDialog yes/no; default Y. Single key, no Enter. Returns 0=yes, 1=no.
  local prompt="$1"
  local ans=""
  printf '%s' "${prompt} [Y/n]: "
  read -r -n 1 ans || true
  echo
  case "${ans}" in
    n|N) return 1 ;;
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
  # Sets PLAIN_MENU_CHOICE. Single key, no Enter. Retries on invalid.
  local prompt="$1"
  local default_key="$2"
  shift 2
  local key label ans k
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
  while true; do
    printf '%s' "Choice [${default_key}]: "
    ans=""
    read -r -n 1 ans || true
    echo
    ans="${ans:-${default_key}}"
    [[ "${ans}" == "Q" ]] && ans=q
    for k in "${keys[@]}"; do
      if [[ "${ans}" == "${k}" ]]; then
        PLAIN_MENU_CHOICE="${ans}"
        return 0
      fi
    done
    echo "(PGM) Please press one of: ${keys[*]} (or Enter for ${default_key})."
  done
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
    echo "(PGM) Using WithDialog."
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
    echo "(PGM) Continuing with WithDialog."
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

colors_menu_label() {
  if [[ "${S_COLORS_VALUE}" == "never" ]]; then
    printf '%s' "Toggle colors (currently OFF)"
  else
    printf '%s' "Toggle colors (currently ON)"
  fi
}

toggle_sar_colors() {
  local state
  if [[ "${S_COLORS_VALUE}" == "never" ]]; then
    S_COLORS_VALUE=auto
    state="ON"
  else
    S_COLORS_VALUE=never
    state="OFF"
  fi
  export S_COLORS="${S_COLORS_VALUE}"
  if (( USE_DIALOG )); then
    run_dialog --title "Colors" --msgbox "Colors are currently ${state}.\n\n(S_COLORS=${S_COLORS_VALUE})" 8 42
  else
    echo "(PGM) Colors are currently ${state} (S_COLORS=${S_COLORS_VALUE})."
  fi
}

choose_stat_type() {
  local default_tag=1
  local color_lbl
  while true; do
    color_lbl="$(colors_menu_label)"
    if ! ask_menu "Statistics" "What would you like to see?" "${default_tag}" \
        1 "CPU utilization (sar -u)" \
        2 "Memory (sar -r)" \
        3 "Swap (sar -S)" \
        4 "Disk I/O per device (sar -d -p)" \
        5 "Block I/O totals (sar -b)" \
        6 "Network interfaces (sar -n DEV)" \
        7 "Load / run queue (sar -q)" \
        c "${color_lbl}" \
        q "Quit"; then
      return 1
    fi
    case "${MENU_CHOICE}" in
      c|C)
        toggle_sar_colors
        default_tag=c
        continue
        ;;
      q|Q) return 1 ;;
      1) SAR_OPTS=(-u) ;;
      2) SAR_OPTS=(-r) ;;
      3) SAR_OPTS=(-S) ;;
      4) SAR_OPTS=(-d -p) ;;
      5) SAR_OPTS=(-b) ;;
      6) SAR_OPTS=(-n DEV) ;;
      7) SAR_OPTS=(-q) ;;
      *)
        echo "(PGM) Invalid choice."
        default_tag=1
        continue
        ;;
    esac
    return 0
  done
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

# Relative day label: 0 days, -1 day, -2 days, ...
sa_day_rel_label() {
  local diff="$1"
  if (( diff == 0 )); then
    printf '0 days'
  elif (( diff == -1 || diff == 1 )); then
    printf '%d day' "${diff}"
  else
    printf '%d days' "${diff}"
  fi
}

# Build CHOSEN_SA_FILE from an interactive list of existing sa* files.
# Labels use file mtime: YYYY.MM.DD (Wed)  -N days  [saDD]
# Returns 0 on success, 1 on cancel / no files.
choose_sa_day_file() {
  local f mtime ymd dow today_mid file_mid diff_days rel label entry
  local default_tag=1 i n ans tmp rc menu_h title prompt
  local -a entries=() files=() labels=() menu_args=() sorted=()

  CHOSEN_SA_FILE=""

  if [[ ! -d "${SA_DIR}" ]]; then
    echo "(PGM) No SA dir yet: ${SA_DIR}" >&2
    return 1
  fi

  # All readable sa* data files (no artificial limit; dialog scrolls if needed)
  for f in "${SA_DIR}"/sa[0-9]*; do
    [[ -f "${f}" && -r "${f}" ]] || continue
    mtime="$(stat -c %Y "${f}" 2>/dev/null || true)"
    [[ -n "${mtime}" ]] || continue
    entries+=("${mtime}|${f}")
  done

  if ((${#entries[@]} == 0)); then
    echo "(PGM) No readable sa* files in ${SA_DIR}." >&2
    return 1
  fi

  mapfile -t sorted < <(printf '%s\n' "${entries[@]}" | sort -t'|' -k1,1nr)

  today_mid="$(date -d "$(date +%Y-%m-%d)" +%s)"
  i=0
  for entry in "${sorted[@]}"; do
    mtime="${entry%%|*}"
    f="${entry#*|}"
    ymd="$(date -d "@${mtime}" +%Y.%m.%d)"
    dow="$(date -d "@${mtime}" +%a)"
    file_mid="$(date -d "$(date -d "@${mtime}" +%Y-%m-%d)" +%s)"
    diff_days=$(( (file_mid - today_mid) / 86400 ))
    rel="$(sa_day_rel_label "${diff_days}")"
    label="$(printf '%s (%s)  %7s  [%s]' "${ymd}" "${dow}" "${rel}" "$(basename "${f}")")"
    ((i++)) || true
    files+=("${f}")
    labels+=("${label}")
    menu_args+=("${i}" "${label}")
    if (( diff_days == 0 )); then
      default_tag="${i}"
    fi
    if [[ -n "${LAST_CHOSEN_SA_FILE}" && "${f}" == "${LAST_CHOSEN_SA_FILE}" ]]; then
      default_tag="${i}"
    fi
  done
  n="${#files[@]}"
  menu_args+=(q "Cancel / back")
  menu_h=$((n + 1))
  title="Day: ${SA_DIR}"
  prompt="Choose SAR day — ${n} file(s) in ${SA_DIR} (arrows scroll):"

  if (( USE_DIALOG )); then
    tmp="$(mktemp)"
    # menu-height = all items so every file is in the list (scroll on small terminals)
    if run_dialog --title "${title}" --default-item "${default_tag}" \
        --menu "${prompt}" 0 78 "${menu_h}" "${menu_args[@]}" 2>"${tmp}"; then
      MENU_CHOICE="$(cat "${tmp}")"
      rm -f "${tmp}"
    else
      rc=$?
      rm -f "${tmp}"
      return "${rc}"
    fi
    case "${MENU_CHOICE}" in
      q|Q) return 1 ;;
    esac
    if [[ "${MENU_CHOICE}" =~ ^[0-9]+$ ]] && (( MENU_CHOICE >= 1 && MENU_CHOICE <= n )); then
      CHOSEN_SA_FILE="${files[$((MENU_CHOICE - 1))]}"
      LAST_CHOSEN_SA_FILE="${CHOSEN_SA_FILE}"
      return 0
    fi
    echo "(PGM) Invalid day choice." >&2
    return 1
  fi

  # WithoutDialog: numbered list; Enter after number (supports 10+ days).
  echo
  echo "SA dir: ${SA_DIR}  (${n} file(s))"
  echo "Choose SAR day:"
  echo
  for ((i = 0; i < n; i++)); do
    printf "  %2d) %s\n" "$((i + 1))" "${labels[$i]}"
  done
  echo "   q) Cancel / back"
  echo
  while true; do
    printf '%s' "Choice [${default_tag}]: "
    ans=""
    read -r ans || true
    ans="${ans:-${default_tag}}"
    case "${ans}" in
      q|Q) return 1 ;;
    esac
    if [[ "${ans}" =~ ^[0-9]+$ ]] && (( ans >= 1 && ans <= n )); then
      CHOSEN_SA_FILE="${files[$((ans - 1))]}"
      LAST_CHOSEN_SA_FILE="${CHOSEN_SA_FILE}"
      return 0
    fi
    echo "(PGM) Please enter 1-${n}, or q to cancel."
  done
}

# Run sar (optional pager). Args: use_pager (0/1), then command words (sar ...).
run_sar_report_cmd() {
  local use_pager="$1"
  shift
  local -a cmd=("$@")
  local color_for_run paged=0 rc

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

  color_for_run="${S_COLORS_VALUE}"
  if (( use_pager )) && type -fP less &>/dev/null; then
    [[ "${color_for_run}" == "auto" ]] && color_for_run=always
    echo "(PGM) Paging with less (-R); press q to leave the pager."
    S_COLORS="${color_for_run}" "${cmd[@]}" | less -R || true
    paged=1
  elif (( use_pager )) && type -fP more &>/dev/null; then
    [[ "${color_for_run}" == "auto" ]] && color_for_run=always
    echo "(PGM) Paging with more; press q or space as usual."
    S_COLORS="${color_for_run}" "${cmd[@]}" | more || true
    paged=1
  else
    if (( use_pager )); then
      echo "(PGM) No less/more found — printing without a pager."
    fi
    S_COLORS="${S_COLORS_VALUE}" "${cmd[@]}" || true
  fi
  rc=$?
  echo
  if (( SAR_PGM_INTERRUPTED )); then
    SAR_PGM_IN_REPORT=0
    return 0
  fi
  if (( rc != 0 && ! paged )); then
    echo "(PGM) sar exited with status ${rc}." >&2
  fi
  if (( ! paged )); then
    pause_to_read_report
  fi
  SAR_PGM_IN_REPORT=0
  return 0
}

choose_and_run_report() {
  local mode start_t end_t interval count sa_file
  local use_pager=1
  local -a cmd

  if ! ask_menu "Time range" "Time range?" "1" \
      1 "Today (from collected logs)" \
      2 "Specific day (from list)" \
      3 "Live sample (interval x count)" \
      4 "Time window today" \
      q "Quit"; then
    return 1
  fi
  mode="${MENU_CHOICE}"
  case "${mode}" in
    q|Q)
      echo "(PGM) Done."
      exit 0
      ;;
  esac

  # Specific day: pick → report → back to day list until Cancel
  if [[ "${mode}" == "2" ]]; then
    while true; do
      if ! choose_sa_day_file; then
        return 1
      fi
      echo "(PGM) Using ${CHOSEN_SA_FILE}"
      run_sar_report_cmd 1 sar "${SAR_OPTS[@]}" -f "${CHOSEN_SA_FILE}"
    done
  fi

  cmd=(sar "${SAR_OPTS[@]}")

  case "${mode}" in
    1)
      ;;
    3)
      use_pager=0
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

  run_sar_report_cmd "${use_pager}" "${cmd[@]}"
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
