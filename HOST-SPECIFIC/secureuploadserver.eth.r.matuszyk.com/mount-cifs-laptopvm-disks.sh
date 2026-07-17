#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay
# 2022.12.31 - v. 0.3 - this script should mount nothing from now on
# 2022.09.11 - v. 0.2 - zmiany kosmetyczne o KeePassie
# 2022.07.30 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

set +x

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

remote_server=laptopvm.eth.b.matuszyk.com

echo 
echo 
echo  "remote_server = $remote_server"
echo 
echo 


echo WE DO NOT MOUNT ANYTHING FROM THIS SERVER !!!!
echo WE DO NOT MOUNT ANYTHING FROM THIS SERVER !!!!
echo WE DO NOT MOUNT ANYTHING FROM THIS SERVER !!!!
echo WE DO NOT MOUNT ANYTHING FROM THIS SERVER !!!!
echo WE DO NOT MOUNT ANYTHING FROM THIS SERVER !!!!
echo WE DO NOT MOUNT ANYTHING FROM THIS SERVER !!!!
echo WE DO NOT MOUNT ANYTHING FROM THIS SERVER !!!!
echo WE DO NOT MOUNT ANYTHING FROM THIS SERVER !!!!
exit 1


echo ; echo "w KeePassie:" ; echo "Samba (p @ laptopvm.eth.b.matuszyk.com)"
read -p "Enter password: " -s PASSWD ; echo 


loc_dir_name="/mnt/rsync-master-DivX"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/DivX-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


loc_dir_name="/mnt/rsync-master-DVDs"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/DVDs-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


loc_dir_name="/mnt/rsync-master-ksiazki"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/ksiazki-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


loc_dir_name="/mnt/rsync-master-mp3"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/mp3-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


loc_dir_name="/mnt/rsync-master-_na_DVD"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/_na_DVD-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


loc_dir_name="/mnt/rsync-master-SkyPlus"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/SkyPlus-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"

loc_dir_name="/mnt/rsync-master-BBC"
rem_dir_name="//laptopvm.eth.b.matuszyk.com/BBC-MASTER-SOURCE_read_only"

umount "${loc_dir_name}" 2>/dev/null  # unmount first if already mounted, to avoid "mount error(16): Device or resource busy"
mount.cifs -o user=p,password=$PASSWD "${rem_dir_name}" "${loc_dir_name}"
#df -hP "${loc_dir_name}"


df -hP |egrep 'Filesystem|laptopvm.eth.b.matuszyk.com'

# set +x

. /root/bin/_script_footer.sh
