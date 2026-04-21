#!/bin/bash

# 2026.04.22 - v. 0.3 - omit --top-* / --cpufreq on Python 3.12+ (removed stdlib imp)
# 2026.04.22 - v. 0.2 - PYTHONWARNINGS: hide Python 3.12+ SyntaxWarning from /usr/bin/dstat regex strings
# 2023.10.12 - v. 0.1 - initial release

. /root/bin/_script_header.sh

check_if_installed dstat

type -fP dstat 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find dstat utility... exiting ..."; echo 
  exit 1
fi

clear

# dstat ships regex as non-raw strings; Python 3.12+ prints SyntaxWarning on \d \( etc.
export PYTHONWARNINGS="ignore::SyntaxWarning${PYTHONWARNINGS:+,${PYTHONWARNINGS}}"

# Several dstat plugins still import imp; Python 3.12 removed imp (PEP 594).
_mi_dstat_imp_extras=(--top-cpu --top-io --top-mem --cpufreq)
if ! python3 -c "import imp" 2>/dev/null; then
  _mi_dstat_imp_extras=()
  echo "(PGM) dstat: skipping --top-cpu/--top-io/--top-mem/--cpufreq (Python 3.12+ has no imp)." >&2
fi

if (( $# == 0 ));then
  dstat -tcdnmg -D mmcblk0,nvme0n1,/dev/sda -N ens33,eth0,eno1 -C total "${_mi_dstat_imp_extras[@]}" -C total --bw --nocolor -f 1
else
  dstat -tcdnmg -D mmcblk0,nvme0n1,/dev/sda -N ens33,eth0,eno1 -C total "${_mi_dstat_imp_extras[@]}" -C total --bw --nocolor --noupdate -f "$1"
fi

. /root/bin/_script_footer.sh
