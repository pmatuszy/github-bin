#!/bin/bash

# 2026.04.22 - v. 0.4 - after VM choice: df -hT for filesystem holding the .vmx
# 2026.04.22 - v. 0.3 - before vmrun: print command, [y/N] confirm (default N)
# 2026.04.22 - v. 0.2 - EXIT banner: script start/stop wall times and elapsed
# 2026.04.22 - v. 0.1 - interactive snapshot: running vs stopped VMs, readline snapshot name
#
# Environment:
#   VMWARE_VM_SEARCH_DIRS — optional; if set, replaces the default VM_LOCATIONS below (space-separated roots)
#   TPM_PASS — optional; if set (e.g. via /root/SECRET/vmware-pass.sh), vmrun uses -vp for encrypted VMs

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
echo "(PGM) Enter the number of the VM to snapshot, or [q] to quit."
echo -n "Choice: "
IFS= read -r choice || true
echo

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

echo
echo "(PGM) Storage — filesystem containing this VM (same mount as the .vmx path):"
if ! df -hT -- "$selected" 2>/dev/null; then
  echo "(PGM) df -hT failed; trying df -h ..." >&2
  df -h -- "$selected" || echo "(PGM) Could not show disk space for: $selected" >&2
fi
echo

default_snap="$(date '+%Y.%m.%d_%H%M%S_-_snapshot')"
echo "(PGM) Snapshot name (readline: arrows, Home, End; empty line aborts):"
echo -n "  "
snap_name=""
IFS= read -r -e -i "$default_snap" -t 300 snap_name || true
echo

if [[ -z "${snap_name//[[:space:]]/}" ]]; then
  echo "(PGM) Empty snapshot name — aborted."
  exit 1
fi

echo
echo "(PGM) Creating snapshot:"
echo "  VM:       $selected"
echo "  Name:     $snap_name"
echo
echo "(PGM) Command to run:"
if [[ -n "${TPM_PASS:-}" ]]; then
  vm_cmd=(vmrun -vp "$TPM_PASS" snapshot "$selected" "$snap_name")
  printf '  %s\n' "vmrun -vp <TPM_PASS> snapshot $(printf '%q' "$selected") $(printf '%q' "$snap_name")"
else
  vm_cmd=(vmrun snapshot "$selected" "$snap_name")
  printf '  %s\n' "vmrun snapshot $(printf '%q' "$selected") $(printf '%q' "$snap_name")"
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

"${vm_cmd[@]}"
rc=$?

if ((rc == 0)); then
  echo
  echo "(PGM) vmrun snapshot finished successfully."
else
  echo
  echo "(PGM) vmrun snapshot failed (exit $rc)." >&2
fi

. /root/bin/_script_footer.sh
exit "$rc"
