#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.07.15 - v. 0.3 - fix y/Y confirm (was always true); init p for nounset on read timeout
# 2023.05.09 - v. 0.2 - added checking if the script is run on the physical machine
# 2023.02.09 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Operational script (vmware-pgm-fix).

Options:
  -h, --help           Show this help and exit.
  -v, --version        Print script version and exit.
  --no_startup_delay   Skip random startup delay (recommended for cron).
EOF
}

HEADER_EXTRA_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    --no_startup_delay) HEADER_EXTRA_ARGS+=(NO_STARTUP_DELAY); shift ;;
    *) break ;;
  esac
done

. /root/bin/_script_header.sh "${HEADER_EXTRA_ARGS[@]}"

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help) show_help; exit 0 ;;
    -v|--version) print_version_banner; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; echo "Try: $(basename "$0") --help" >&2; exit 1 ;;
  esac
done

check_if_installed virt-what
if (( $(virt-what | wc -l) != 0 ));then
  echo ; echo "host is NOT a physical machine ... exiting...";echo
  exit 1
fi

export DISPLAY=

if [ -f /root/SECRET/vmware-pass.sh ];then
  . /root/SECRET/vmware-pass.sh
fi

type -fP vmrun 2>&1 > /dev/null
if (( $? != 0 )); then
  echo ; echo "(PGM) I can't find vmrun utility... exiting ..."; echo 
  exit 1
fi

boxes <<<"vmrun list"
vmrun list

export DISPLAY=
echo ; vmware -v ; echo

export wersja=$(vmware -v|awk '{print $3}')

echo "Do you want to fix vmware after the kernel update? [y/N]"
p=""
read -t 300 -n 1 p || true     # read one character (-n) with timeout of 300 seconds
echo
if [[ ! "${p}" =~ ^[yY]$ ]]; then
  echo "no means no - I am exiting..."
  exit 1
fi

apt install -y gcc build-essential linux-headers-generic linux-headers-$(uname -r) ;

vmware-modconfig --console --install-all ;
systemctl restart vmware.service ;

(
cd /usr/lib/vmware/modules/source ;
rm -rfv vmmon.tar vmnet.tar vmware-host-modules ; 
git clone https://github.com/mkubecek/vmware-host-modules ; 
cd vmware-host-modules ; 
git checkout workstation-${wersja} ; 
make && sudo make install ; 
)

(
cd /usr/lib/vmware/modules/source/vmware-host-modules ;
tar -cf vmnet_$(date '+%Y%m%d_%H%M%S').tar vmnet-only ; echo $?
tar -cf vmmon_$(date '+%Y%m%d_%H%M%S').tar vmmon-only ; echo $?
tar -cf vmnet.tar vmnet-only ; echo $?
tar -cf vmmon.tar vmmon-only ; echo $?
ls -l 
)

(
cd /usr/lib/vmware/modules/source/vmware-host-modules ;
mv -v vmnet.tar /usr/lib/vmware/modules/source/ ; echo $?
mv -v vmmon.tar /usr/lib/vmware/modules/source/ ; echo $?
)

(
vmware-modconfig --console --install-all ; 
systemctl restart vmware.service ;
)

. /root/bin/_script_footer.sh
