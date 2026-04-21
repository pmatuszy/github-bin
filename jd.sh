#!/bin/bash

# 2026.04.22 - v. 1.8 - --details: sector size + sectors/bytes/kB/MB/GB/TB (SI); expanded --help
# 2026.04.22 - v. 1.7 - serial column width: trim values; max width via value loop (reliable subscripts)
# 2026.04.22 - v. 1.6 - column widths from longest cell (header + data)
# 2026.04.22 - v. 1.5 - aligned Device / size / Serial; NVMe SN via nvme id-ctrl
# 2026.04.22 - v. 1.4 - help/version; root check; grep -E; quoting; disk list for all supported OS; uname -m; kod_powrotu
# 2023.10.25 - v. 1.3 - added check if hdparm is installed
# 2023.09.02 - v. 1.2 - bugfix: better OS detection
# 2023.07.19 - v. 1.1 - bugfix: handling wrong partition table (it was prompted, now it is removed with echo q
# 2023.07.19 - v. 1.0 - bugfix: egrep and $? checking
# 2023.06.21 - v. 0.9 - check if nvme is installed
# 2023.03.07 - v. 0.8 - added script_header and footer calls
# 2022.11.10 - v. 0.7 - added S/N printing for NVME devices and replaced echo with printf to beautify output
# 2022.10.27 - v. 0.6 - bugfixes, added support for Raspbian, small changes in print format output,added printing of the script version
# 2022.10.11 - v. 0.5 - discovery if it is x86 or raspberry pi
# 2021.04.16 - v. 0.4 - checking if it is redhat system
# 2020.11.27 - v. 0.3 - added printing of the disk serial numbers
# 2020.10.09 - v. 0.2 - small cosmetic modifications
# 2020.0x.xx - v. 0.1 - initial release (date unknown)

if [[ "${1:-}" == -h || "${1:-}" == --help ]]; then
  cat <<'EOF'
Usage: jd.sh [options]

Summary
  Lists whole-disk block devices (from fdisk -l) in a three-column table: device
  path, the "Disk ..." size line from gdisk, and the serial from hdparm (SATA/SAS)
  or nvme id-ctrl (NVMe). Column widths fit the longest value in each column.

  Intended for Debian/Ubuntu/Raspbian and RHEL-family systems that have
  /etc/os-release or /etc/redhat-release.

  Run as root so fdisk, hdparm, gdisk, and blockdev behave consistently.

Options
  -h, --help       Show this help and exit.
  -v, --version    Print script version and exit.
  -d, --details    After the table, print per-disk geometry: logical sector size,
                   sector count (capacity / sector size), capacity in bytes, and
                   the same capacity in kB, MB, GB, and TB using decimal (SI)
                   prefixes (powers of 1000). Uses blockdev(8) when available,
                   otherwise /sys/block/*/size and queue/logical_block_size.

Examples
  jd.sh
  jd.sh --details
EOF
  exit 0
fi

if [[ "${1:-}" == -v || "${1:-}" == --version ]]; then
  _jd_ver=unknown
  _jd_date=
  while IFS= read -r _jd_line; do
    if [[ "$_jd_line" =~ ^#\ ([0-9]{4}\.[0-9]{2}\.[0-9]{2})\ -\ v\.\ ([0-9]+(\.[0-9]+)*)\ - ]]; then
      _jd_date="${BASH_REMATCH[1]}"
      _jd_ver="${BASH_REMATCH[2]}"
      break
    fi
  done < "$0"
  if [[ -n "$_jd_date" ]]; then
    printf '%s version %s (%s)\n' "$(basename "$0")" "$_jd_ver" "$_jd_date"
  else
    printf '%s version %s\n' "$(basename "$0")" "$_jd_ver"
  fi
  exit 0
fi

_jd_details=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    -d | --details)
      _jd_details=1
      shift
      ;;
    *)
      echo "(PGM) Unknown argument: $1" >&2
      echo "Try: $(basename "$0") --help" >&2
      exit 1
      ;;
  esac
done

. /root/bin/_script_header.sh

kod_powrotu=0

if [[ "$(id -u)" -ne 0 ]]; then
  echo
  echo "(PGM) Run as root for fdisk/hdparm/nvme listing."
  echo
  kod_powrotu=1
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

if [[ ! -f /etc/os-release && ! -f /etc/redhat-release ]]; then
  echo
  echo "(PGM) I don't know what OS is that - I am exiting..."
  echo
  kod_powrotu=1
  . /root/bin/_script_footer.sh
  exit "${kod_powrotu}"
fi

check_if_installed nvme nvme-cli
check_if_installed hdparm
check_if_installed gdisk

echo

if grep -qiE 'centos|rocky|almalinux|fedora|rhel|redhat' /etc/os-release 2>/dev/null || \
   grep -qi centos /etc/redhat-release 2>/dev/null; then
  echo CENTOS | boxes -s 40x5 -a c
  echo
fi

hardware_type=""
_m=$(uname -m)
case "${_m}" in
  x86_64)
    hardware_type='PC (x86_64)'
    ;;
  aarch64|armv7l|armv6l)
    hardware_type="ARM (${_m})"
    ;;
  *)
    hardware_type="${_m}"
    ;;
esac

if [[ -n "${hardware_type}" ]]; then
  echo "${hardware_type}" | boxes -s 40x5 -a c
  echo
fi

mapfile -t _jd_disks < <(
  fdisk -l 2>/dev/null | grep -E '^Disk /dev/' | grep -Ev 'mapper|/md|/ram|mmcblk|/dev/loop' |
    awk '{print $2}' | tr -d ':' | sort -u
)

_jd_nvme_sn() {
  local _p=$1
  if [[ "${_p}" =~ ^(/dev/nvme[0-9]+)n[0-9]+$ ]]; then
    nvme id-ctrl "${BASH_REMATCH[1]}" 2>/dev/null | grep -i '^sn[[:space:]]*:' | head -1 |
      sed 's/^[^:]*:[[:space:]]*//' | tr -d '\r'
  else
    nvme list 2>/dev/null | awk -v d="${_p}" 'index($0, d) {print $2; exit}'
  fi
}

# Sets _jd_bytes, _jd_ss, _jd_sectors for device $1; returns 0 on success.
_jd_disk_geom() {
  local _dev=$1 _base _sz512
  _jd_bytes=
  _jd_ss=
  _jd_sectors=
  if command -v blockdev >/dev/null 2>&1 &&
    _jd_bytes=$(blockdev --getsize64 "${_dev}" 2>/dev/null) &&
    _jd_ss=$(blockdev --getss "${_dev}" 2>/dev/null) &&
    [[ -n "${_jd_bytes}" && -n "${_jd_ss}" ]]; then
    :
  else
    _base=$(basename "${_dev}")
    if [[ ! -r "/sys/block/${_base}/size" || ! -r "/sys/block/${_base}/queue/logical_block_size" ]]; then
      return 1
    fi
    _sz512=$(<"/sys/block/${_base}/size")
    _jd_ss=$(<"/sys/block/${_base}/queue/logical_block_size")
    _jd_bytes=$((_sz512 * 512))
  fi
  [[ -n "${_jd_bytes}" && -n "${_jd_ss}" ]] || return 1
  ((_jd_ss > 0)) || return 1
  _jd_sectors=$((_jd_bytes / _jd_ss))
  return 0
}

_jd_c1=()
_jd_c2=()
_jd_c3=()

for p in "${_jd_disks[@]}"; do
  [[ -z "${p}" ]] && continue
  if [[ $(hdparm -I "${p}" 2>/dev/null | grep -c 'Serial Number') -gt 0 ]]; then
    _jd_gline=$(echo q | gdisk -l "${p}" 2>/dev/null | grep 'Disk /dev')
    _jd_gline="${_jd_gline//Your answer: /}"
    _jd_sn=$(hdparm -I "${p}" 2>/dev/null | grep 'Serial Number' | head -1 | sed 's/^[^:]*:[[:space:]]*//' | tr -d '\r' | tr -s ' ')
  else
    _jd_gline=$(gdisk -l "${p}" 2>/dev/null | grep 'Disk /dev')
    _jd_sn=$(_jd_nvme_sn "${p}")
  fi
  _jd_pref="Disk ${p}: "
  if [[ "${_jd_gline}" == "${_jd_pref}"* ]]; then
    _jd_desc="${_jd_gline#"${_jd_pref}"}"
  else
    _jd_desc="${_jd_gline}"
  fi
  [[ -z "${_jd_sn}" ]] && _jd_sn='?'
  _jd_sn="${_jd_sn#"${_jd_sn%%[![:space:]]*}"}"
  _jd_sn="${_jd_sn%"${_jd_sn##*[![:space:]]}"}"
  [[ -z "${_jd_sn}" ]] && _jd_sn='?'
  _jd_c1+=("${p}")
  _jd_c2+=("${_jd_desc}")
  _jd_c3+=("${_jd_sn}")
done

_jd_h1='Device'
_jd_h2='Sectors / size'
_jd_h3='Serial number'
_jd_w1=${#_jd_h1}
_jd_w2=${#_jd_h2}
_jd_w3=${#_jd_h3}
for _jd_row in "${_jd_c1[@]}"; do
  [[ ${#_jd_row} -gt ${_jd_w1} ]] && _jd_w1=${#_jd_row}
done
for _jd_row in "${_jd_c2[@]}"; do
  [[ ${#_jd_row} -gt ${_jd_w2} ]] && _jd_w2=${#_jd_row}
done
for _jd_row in "${_jd_c3[@]}"; do
  [[ ${#_jd_row} -gt ${_jd_w3} ]] && _jd_w3=${#_jd_row}
done

_jd_sep1=$(printf '%*s' "${_jd_w1}" '' | tr ' ' '-')
_jd_sep2=$(printf '%*s' "${_jd_w2}" '' | tr ' ' '-')
_jd_sep3=$(printf '%*s' "${_jd_w3}" '' | tr ' ' '-')

printf "%-${_jd_w1}s  %-${_jd_w2}s  %-${_jd_w3}s\n" "${_jd_h1}" "${_jd_h2}" "${_jd_h3}"
printf "%-${_jd_w1}s  %-${_jd_w2}s  %-${_jd_w3}s\n" "${_jd_sep1}" "${_jd_sep2}" "${_jd_sep3}"
for _jd_i in "${!_jd_c1[@]}"; do
  printf "%-${_jd_w1}s  %-${_jd_w2}s  %-${_jd_w3}s\n" "${_jd_c1[_jd_i]}" "${_jd_c2[_jd_i]}" "${_jd_c3[_jd_i]}"
done

echo
echo "# of disks in the system: ${#_jd_disks[@]}"

if [[ "${_jd_details}" -eq 1 ]]; then
  echo
  echo "Detailed sizes (kB/MB/GB/TB use decimal SI prefixes, powers of 1000):"
  echo
  for p in "${_jd_disks[@]}"; do
    [[ -z "${p}" ]] && continue
    if ! _jd_disk_geom "${p}"; then
      printf '%s\n  (could not read size / sector size)\n\n' "${p}"
      continue
    fi
    printf '%s\n' "${p}"
    printf '  Logical sector size:      %s bytes\n' "${_jd_ss}"
    printf '  Sectors (capacity / ss):  %s\n' "${_jd_sectors}"
    printf '  Bytes:                    %s\n' "${_jd_bytes}"
    LC_NUMERIC=C awk -v b="${_jd_bytes}" '
      BEGIN {
        printf "  kB (10^3):                %.3f\n", b / 1e3
        printf "  MB (10^6):                %.3f\n", b / 1e6
        printf "  GB (10^9):                %.3f\n", b / 1e9
        printf "  TB (10^12):               %.3f\n", b / 1e12
      }'
    echo
  done
fi

echo

. /root/bin/_script_footer.sh

exit "${kod_powrotu}"
