#!/bin/bash

# 2026.04.22 - v. 0.8 - quieter menu; selected VM in boxes; snapshot prompt shortened
# 2026.04.22 - v. 0.7 - VM/snapshot menu read: read -rs -n 1 + echo digits (fixes TTY line-buffer stall)
# 2026.04.22 - v. 0.6 - encrypted VM: interactive TPM_PASS with masked input (*) if not already set
# 2026.04.22 - v. 0.5 - snapshot index menu: same unique-prefix choice as VM menu
# 2026.04.22 - v. 0.4 - VM menu: unique digit prefix accepts without Enter; ambiguous indices need more digits or Enter
# 2026.04.22 - v. 0.3 - print deleteSnapshot wall time before script footer
# 2026.04.22 - v. 0.2 - after deleteSnapshot: list remaining snapshots
# 2026.04.22 - v. 0.1 - interactive delete snapshot: pick VM, pick snapshot, show command, [y/N] run
#
# Environment:
#   VMWARE_VM_SEARCH_DIRS — optional; if set, replaces the default VM_LOCATIONS below (space-separated roots)
#   TPM_PASS — optional; if set (e.g. via /root/SECRET/vmware-pass.sh), vmrun uses -vp for encrypted VMs.
#              If unset and the .vmx looks encrypted, you are prompted on a TTY (passphrase shown as *).
#
# Note: vmrun deleteSnapshot usually requires the VM to be powered off or suspended (see VMware docs).

. /root/bin/_script_header.sh

_SCRIPT_START_EPOCH=$(date +%s)
_SCRIPT_START_FMT=$(date '+%Y-%m-%d %H:%M:%S %Z')

_print_run_timing_banner() {
  local end_ep end_fmt elapsed h m s human

  end_ep=$(date +%s)
  end_fmt=$(date '+%Y-%m-%d %H:%M:%S %Z')
  elapsed=$((end_ep - _SCRIPT_START_EPOCH))
  h=$((elapsed / 3600))
  m=$(((elapsed % 3600) / 60))
  s=$((elapsed % 60))
  if ((h > 0)); then
    human="${h}h ${m}m ${s}s"
  elif ((m > 0)); then
    human="${m}m ${s}s"
  else
    human="${s}s"
  fi

  echo
  echo "=========================================="
  echo "  $(basename "$0") — run timing"
  echo "  Started: ${_SCRIPT_START_FMT}"
  echo "  Stopped: ${end_fmt}"
  echo "  Elapsed: ${elapsed}s (${human})"
  echo "=========================================="
}

trap '_print_run_timing_banner' EXIT

check_if_installed virt-what

virt_what_out=$(virt-what 2>/dev/null) || true
if [[ -n "${virt_what_out//[[:space:]]/}" ]]; then
  vw_report="${virt_what_out//$'\n'/, }"
  vw_report="${vw_report%, }"
  echo
  echo "(PGM) host is NOT a physical machine (virt-what: ${vw_report}) ... exiting ..."
  echo
  exit 1
fi

export DISPLAY=

if [[ -f /root/SECRET/vmware-pass.sh ]]; then
  # shellcheck source=/dev/null
  . /root/SECRET/vmware-pass.sh
fi

if ! type -fP vmrun &>/dev/null; then
  echo
  echo "(PGM) I can't find vmrun utility... exiting ..."
  echo
  exit 1
fi

if [[ -n "${VMWARE_VM_SEARCH_DIRS:-}" ]]; then
  VM_LOCATIONS="$VMWARE_VM_SEARCH_DIRS"
else
  VM_LOCATIONS="/vmware /vmware-nvme /encrypted/vmware-in-encrypted /mnt/luks-raidsonic /mnt/luks-icybox10/vmware /mnt/luks-buffalo2/vmware"
  VM_LOCATIONS="$VM_LOCATIONS /mnt/luks-raid1-A/vmware"
fi

_canonical() {
  local p="$1"
  if command -v realpath &>/dev/null; then
    realpath -m "$p" 2>/dev/null && return 0
  fi
  readlink -f "$p" 2>/dev/null && return 0
  printf '%s' "$p"
}

declare -A _seen_canon=()

_add_unique_vmx_line() {
  local line="$1"
  local c
  [[ -n "$line" ]] || return 0
  c="$(_canonical "$line")"
  [[ -n "${_seen_canon[$c]+x}" ]] && return 0
  _seen_canon[$c]=1
  _vmx_lines+=( "$line" )
}

# Fills the array named by $2 with names from vmrun listSnapshots stdout in $1.
# Returns 10 if output contains Total snapshots: 0 (array cleared).
_pgm_parse_snapshots_from_list_out() {
  local list_out="$1"
  local -n _snaps_ref="$2"
  local line saw_zero=0

  _snaps_ref=()
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%$'\r'}"
    [[ -z "${line//[[:space:]]/}" ]] && continue
    if [[ "${line}" =~ [Tt]otal[[:space:]]+snapshots: ]]; then
      if [[ "${line}" =~ [Tt]otal[[:space:]]+snapshots:[[:space:]]*0[[:space:]]*$ ]]; then
        saw_zero=1
      fi
      continue
    fi
    _snaps_ref+=("$line")
  done <<< "$list_out"
  ((saw_zero == 1)) && return 10
  return 0
}

# Reads VM index into nameref $2; associative array $1 is idx -> path.
# Unique prefix of index digits accepts immediately; else type full number and Enter, or Enter after exact index.
# q + Enter quits when buffer empty. Output: "", "q", or digits.
_pgm_read_vm_menu_choice() {
  local -n _menu="$1"
  local -n _out_choice="$2"
  local buf="" key n match try_buf _k _ok
  local -a _sorted_idxs=()

  mapfile -t _sorted_idxs < <(printf '%s\n' "${!_menu[@]}" | sort -n)

  while true; do
    IFS= read -rs -n 1 key || {
      echo
      _out_choice=""
      return 0
    }

    if [[ "$key" == $'\n' || "$key" == $'\r' ]]; then
      echo
      if [[ -z "$buf" ]]; then
        _out_choice=""
        return 0
      fi
      buf="${buf//$'\r'/}"
      _ok=0
      for _k in "${!_menu[@]}"; do
        [[ "$_k" == "$buf" ]] && {
          _ok=1
          break
        }
      done
      if [[ "$buf" =~ ^[0-9]+$ ]] && ((_ok)); then
        _out_choice="$buf"
        return 0
      fi
      echo "(PGM) Invalid choice: $(printf '%q' "$buf")" >&2
      buf=""
      printf '(PGM) Try again. Choice: '
      continue
    fi

    if [[ "$key" == [qQ] ]]; then
      if [[ -z "$buf" ]]; then
        printf '%s\n' "$key"
        _out_choice="q"
        return 0
      fi
      continue
    fi

    [[ "$key" == [0-9] ]] || continue

    try_buf="${buf}${key}"
    n=0
    match=""
    for match_try in "${_sorted_idxs[@]}"; do
      if [[ "$match_try" == "$try_buf"* ]]; then
        ((++n))
        match="$match_try"
      fi
    done

    ((n == 0)) && continue

    printf '%s' "$key"
    buf="$try_buf"

    if ((n == 1)); then
      echo
      _out_choice="$match"
      return 0
    fi
  done
}

_pgm_show_selected_vm_boxed() {
  local _idx="$1" _vmx="$2"

  echo
  if type -fP boxes &>/dev/null; then
    printf 'SELECTED VM  [%s]\n%s\n' "$_idx" "$_vmx" | boxes -s 120x8 -a c -d ada-box
  else
    echo "====================  SELECTED VM  ========================"
    printf '  [%s]  %s\n' "$_idx" "$_vmx"
    echo "==========================================================="
  fi
  echo
}

_pgm_vmx_likely_encrypted() {
  [[ -f "$1" ]] || return 1
  if grep -qiE '^encryption\.keySafe[[:space:]]*=' "$1" 2>/dev/null; then
    return 0
  fi
  grep -qiE '^encryptVM\.enabled[[:space:]]*=[[:space:]]*"TRUE"' "$1" 2>/dev/null
}

# Reads a line into nameref $1; echoes '*' per char; Backspace erases. Uses stdin/stdout TTY.
_pgm_read_password_masked() {
  local -n _pw="$1"
  local prompt="${2:-Passphrase: }"
  local char

  _pw=""
  if [[ ! -t 0 ]] || [[ ! -t 1 ]]; then
    echo "(PGM) Not a TTY; cannot read masked passphrase. Set TPM_PASS or use /root/SECRET/vmware-pass.sh" >&2
    return 1
  fi

  printf '%s' "$prompt"
  while true; do
    IFS= read -rs -n 1 char || {
      echo
      return 1
    }
    if [[ "$char" == $'\n' || "$char" == $'\r' ]]; then
      echo
      break
    fi
    if [[ "$char" == $'\177' || "$char" == $'\b' ]]; then
      if ((${#_pw} > 0)); then
        _pw="${_pw%?}"
        printf '\b \b'
      fi
      continue
    fi
    if [[ "$char" =~ [^[:print:]] ]]; then
      continue
    fi
    _pw+="$char"
    printf '*'
  done
  return 0
}

_pgm_ensure_tpm_pass_for_vmx() {
  local vmx="$1"

  [[ -n "${TPM_PASS:-}" ]] && return 0
  if ! _pgm_vmx_likely_encrypted "$vmx"; then
    return 0
  fi
  echo
  echo "(PGM) This VMX appears encrypted. Enter the encryption passphrase (each character shown as *; Backspace corrects)."
  if ! _pgm_read_password_masked TPM_PASS "Passphrase: "; then
    echo "(PGM) Passphrase input aborted." >&2
    return 1
  fi
  if [[ -z "${TPM_PASS}" ]]; then
    echo "(PGM) Empty passphrase — vmrun may still prompt or fail." >&2
  fi
  return 0
}

_pgm_print_remaining_snapshots_for_vmx() {
  local vmx="$1"
  local list_r list_o snaps=() parse_rc i

  list_r=0
  if [[ -n "${TPM_PASS:-}" ]]; then
    list_o=$(vmrun -vp "$TPM_PASS" listSnapshots "$vmx" 2>&1) || list_r=$?
  else
    list_o=$(vmrun listSnapshots "$vmx" 2>&1) || list_r=$?
  fi

  echo
  echo "(PGM) Remaining snapshots (vmrun listSnapshots) …"
  if ((list_r != 0)); then
    echo "(PGM) listSnapshots failed (exit $list_r); cannot show remaining list." >&2
    echo "$list_o" >&2
    return 1
  fi

  _pgm_parse_snapshots_from_list_out "$list_o" snaps
  parse_rc=$?
  if ((parse_rc == 10)); then
    echo "  (none)"
    return 0
  fi
  if ((${#snaps[@]} == 0)); then
    echo "(PGM) Could not parse snapshot list. Raw output:"
    echo "$list_o"
    return 1
  fi

  echo
  echo "====================  REMAINING SNAPSHOTS  ========================"
  i=1
  for s in "${snaps[@]}"; do
    printf '  [%2d] %s\n' "$i" "$s"
    ((++i))
  done
  return 0
}

mapfile -t _running_raw < <(vmrun list 2>/dev/null | grep -E '\.vmx$' | sort -u)

_vmx_lines=()
declare -A _seen_canon=()
for p in "${_running_raw[@]}"; do
  _add_unique_vmx_line "$p"
done
running_paths=("${_vmx_lines[@]}")

_vmx_lines=()
declare -A _seen_canon=()
for root in $VM_LOCATIONS; do
  [[ -d "$root" ]] || continue
  while IFS= read -r -d '' f; do
    _add_unique_vmx_line "$f"
  done < <(find "$root" -type f -name '*.vmx' -print0 2>/dev/null)
done
all_paths=("${_vmx_lines[@]}")

declare -A running_canon=()
for p in "${running_paths[@]}"; do
  running_canon["$(_canonical "$p")"]=1
done

stopped_paths=()
for p in "${all_paths[@]}"; do
  c="$(_canonical "$p")"
  [[ -n "${running_canon[$c]+x}" ]] && continue
  stopped_paths+=( "$p" )
done

if ((${#running_paths[@]} == 0 && ${#stopped_paths[@]} == 0)); then
  echo "(PGM) No .vmx files found under VM_LOCATIONS and none reported running by vmrun."
  echo "(PGM) Set VMWARE_VM_SEARCH_DIRS to your VM root directories (space-separated)."
  exit 1
fi

declare -A menu_idx_to_path=()
idx=1

echo
echo "========================  RUNNING VMs  ========================"
if ((${#running_paths[@]} == 0)); then
  echo "  (none)"
else
  for p in "${running_paths[@]}"; do
    printf '  [%2d] %s\n' "$idx" "$p"
    menu_idx_to_path[$idx]=$p
    ((++idx))
  done
fi

echo
echo "====================  NOT RUNNING VMs  ========================"
if ((${#stopped_paths[@]} == 0)); then
  echo "  (none under search paths, or all discovered VMs are running)"
else
  for p in "${stopped_paths[@]}"; do
    printf '  [%2d] %s\n' "$idx" "$p"
    menu_idx_to_path[$idx]=$p
    ((++idx))
  done
fi

echo
echo "(PGM) Enter the VM number to delete a snapshot from, or [q] to quit."
echo -n "Choice: "
choice=""
_pgm_read_vm_menu_choice menu_idx_to_path choice

if [[ "${choice,,}" == "q" ]] || [[ -z "${choice//[[:space:]]/}" ]]; then
  echo "(PGM) Exiting."
  exit 0
fi

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [[ -z "${menu_idx_to_path[$choice]+x}" ]]; then
  echo "(PGM) Invalid choice: $choice" >&2
  exit 1
fi

selected="${menu_idx_to_path[$choice]}"
if [[ ! -f "$selected" ]]; then
  echo "(PGM) VMX not found: $selected" >&2
  exit 1
fi

if ! _pgm_ensure_tpm_pass_for_vmx "$selected"; then
  exit 1
fi

_pgm_show_selected_vm_boxed "$choice" "$selected"

echo "(PGM) Storage — filesystem containing this VM (same mount as the .vmx path):"
if ! df -hT -- "$selected" 2>/dev/null; then
  echo "(PGM) df -hT failed; trying df -h ..." >&2
  df -h -- "$selected" || echo "(PGM) Could not show disk space for: $selected" >&2
fi
echo

echo "(PGM) Listing snapshots (vmrun listSnapshots) …"
list_rc=0
if [[ -n "${TPM_PASS:-}" ]]; then
  list_out=$(vmrun -vp "$TPM_PASS" listSnapshots "$selected" 2>&1) || list_rc=$?
else
  list_out=$(vmrun listSnapshots "$selected" 2>&1) || list_rc=$?
fi

if ((list_rc != 0)); then
  echo "(PGM) vmrun listSnapshots failed (exit ${list_rc:-1})." >&2
  echo "$list_out" >&2
  exit 1
fi

snapshots=()
_pgm_parse_snapshots_from_list_out "$list_out" snapshots
parse_rc=$?
if ((parse_rc == 10)); then
  echo "(PGM) This VM has no snapshots."
  exit 0
fi

if ((${#snapshots[@]} == 0)); then
  echo "(PGM) No snapshot names parsed from vmrun output. Raw output:"
  echo "$list_out"
  exit 1
fi

declare -A snap_idx_to_name=()
sidx=1
echo
echo "====================  SNAPSHOTS  ========================"
for s in "${snapshots[@]}"; do
  printf '  [%2d] %s\n' "$sidx" "$s"
  snap_idx_to_name[$sidx]=$s
  ((++sidx))
done

echo
echo "(PGM) Enter the snapshot index to delete, or [q] to quit."
echo "(PGM) Hint: deleteSnapshot usually needs the VM off or suspended."
echo -n "Choice: "
schoice=""
_pgm_read_vm_menu_choice snap_idx_to_name schoice

if [[ "${schoice,,}" == "q" ]] || [[ -z "${schoice//[[:space:]]/}" ]]; then
  echo "(PGM) Exiting."
  exit 0
fi

if ! [[ "$schoice" =~ ^[0-9]+$ ]] || [[ -z "${snap_idx_to_name[$schoice]+x}" ]]; then
  echo "(PGM) Invalid snapshot choice: $schoice" >&2
  exit 1
fi

snap_del="${snap_idx_to_name[$schoice]}"

echo
echo "(PGM) Delete snapshot:"
echo "  VM:           $selected"
echo "  Snapshot:     $snap_del"
echo
echo "(PGM) Command to run:"
if [[ -n "${TPM_PASS:-}" ]]; then
  vm_cmd=(vmrun -vp "$TPM_PASS" deleteSnapshot "$selected" "$snap_del")
  printf '  %s\n' "vmrun -vp <TPM_PASS> deleteSnapshot $(printf '%q' "$selected") $(printf '%q' "$snap_del")"
else
  vm_cmd=(vmrun deleteSnapshot "$selected" "$snap_del")
  printf '  %s\n' "vmrun deleteSnapshot $(printf '%q' "$selected") $(printf '%q' "$snap_del")"
fi
echo
echo -n "(PGM) Run this command? [y/N] "
IFS= read -r -n 1 -t 300 run_confirm || true
echo
case "${run_confirm}" in
  y|Y) ;;
  n|N|''|$'\n'|$'\r')
    echo "(PGM) Command not run (no)."
    exit 0
    ;;
  *)
    echo "(PGM) Command not run (only y/Y runs the command; n/N, Enter, or other = no)."
    exit 0
    ;;
esac

_delete_start=$(date +%s)
"${vm_cmd[@]}"
rc=$?
_delete_end=$(date +%s)
_delete_el=$((_delete_end - _delete_start))
_delete_h=$((_delete_el / 3600))
_delete_m=$(((_delete_el % 3600) / 60))
_delete_s=$((_delete_el % 60))
if ((_delete_h > 0)); then
  _delete_human="${_delete_h}h ${_delete_m}m ${_delete_s}s"
elif ((_delete_m > 0)); then
  _delete_human="${_delete_m}m ${_delete_s}s"
else
  _delete_human="${_delete_s}s"
fi

if ((rc == 0)); then
  echo
  echo "(PGM) vmrun deleteSnapshot finished successfully."
else
  echo
  echo "(PGM) vmrun deleteSnapshot failed (exit $rc). If the VM is on, power off or suspend and retry." >&2
fi

_pgm_print_remaining_snapshots_for_vmx "$selected" || true

echo
echo "(PGM) vmrun deleteSnapshot wall time: ${_delete_el}s (${_delete_human})"

. /root/bin/_script_footer.sh
exit "$rc"
