#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS

# 2026.07.16 - v. 0.72 - add -h/--help, -v/--version, --no_startup_delay (parsed before header)
# 2026.05.26 - user-facing messages translated from Polish to English
# 2025.10.27 - v. 0.71- changed MAX_ALLOWED_SWAP_MB limit 950 ==> 1500
# 2025.10.22 - v. 0.7 - changed MAX_ALLOWED_SWAP_MB limit 600 ==> 950
# 2023.02.28 - v. 0.6 - curl with return_code
# 2023.01.03 - v. 0.5 - added random delay when script runs non-interactively
# 2022.07.01 - v. 0.4 - added swap trimming even when under limit but partially allocated
#                       swap is trimmed without triggering healthcheck alert
# 2022.06.15 - v. 0.3 - changed MAX_ALLOWED_SWAP_MB limit 400 ==> 600
# 2022.06.06 - v. 0.2 - changed MAX_ALLOWED_SWAP_MB limit 100 ==> 400
# 2022.06.01 - v. 0.1 - initial release
#
# healthchecks-swap-usage.sh
#
# Monitor swap usage; trim when over limits; report status to Healthchecks.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Monitor swap usage and trim when over limits; ping Healthchecks with exit code.
Lookup URL in healthchecks-ids.txt by script basename.

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

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

export MAX_ALLOWED_SWAP_MB=1900 # in MB
export MIN_RAM_FREE=100                    # in MB
export MAX_USED_SWAP_TO_TRIM_ANYWAY=50     # in MB - trim but return ok not fail

m=$( echo "${SCRIPT_VERSION}";echo ;
     cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}' ; echo ; echo
     free_ram_mb=$(free -m|grep '^Mem:'|awk '{print $7}');
     swap_used_mb=$(free -m|grep '^Swap:'|awk '{print $3}');
     let effective_free_ram_mb=$free_ram_mb-$swap_used_mb;
     if (( $effective_free_ram_mb >= $MIN_RAM_FREE && $swap_used_mb > ${MAX_ALLOWED_SWAP_MB} ));then
       echo "forcing SWAP usage reduction,"
       echo "because MAX_ALLOWED_SWAP_MB ($MAX_ALLOWED_SWAP_MB) < swap_used_mb ($swap_used_mb)"
       echo "RAM is also free: free_ram_mb ($free_ram_mb) > MIN_RAM_FREE ($MIN_RAM_FREE)"
       echo "~~~~~~~~ BEFORE ~~~~~~~~"
       printf "free_ram_mb    = %5d [MiB]\n" $free_ram_mb
       printf "swap_used_mb  = %5d [MiB]\n" $swap_used_mb
       printf "effective_free_ram_mb = %5d [MiB]\n" $effective_free_ram_mb
       echo

       swapoff -a ; sleep 2; swapon -a 

       free_ram_mb=$(free -m|grep '^Mem:'|awk '{print $7}');
       swap_used_mb=$(free -m|grep '^Swap:'|awk '{print $3}');
       let effective_free_ram_mb=$free_ram_mb-$swap_used_mb;

       echo "~~~~~~~~ AFTER ~~~~~~~~"
       printf "free_ram_mb    = %5d [MiB]\n" $free_ram_mb
       printf "swap_used_mb  = %5d [MiB]\n" $swap_used_mb
       printf "effective_free_ram_mb = %5d [MiB]\n" $effective_free_ram_mb
       echo

       exit 1
     else  # no critical condition; check other criteria
       if (( $effective_free_ram_mb >= $MIN_RAM_FREE && $swap_used_mb > $MAX_USED_SWAP_TO_TRIM_ANYWAY )); then
         echo "trimming swap (some usage, below MAX_ALLOWED_SWAP_MB ($MAX_ALLOWED_SWAP_MB))"
         echo "RAM is also free: free_ram_mb ($free_ram_mb) > MIN_RAM_FREE ($MIN_RAM_FREE)"
         echo "~~~~~~~~ BEFORE ~~~~~~~~"
         printf "free_ram_mb    = %5d [MiB]\n" $free_ram_mb
         printf "swap_used_mb  = %5d [MiB]\n" $swap_used_mb
         printf "effective_free_ram_mb = %5d [MiB]\n" $effective_free_ram_mb
         echo

         swapoff -a ; sleep 2; swapon -a

         free_ram_mb=$(free -m|grep '^Mem:'|awk '{print $7}');
         swap_used_mb=$(free -m|grep '^Swap:'|awk '{print $3}');
         let effective_free_ram_mb=$free_ram_mb-$swap_used_mb;

         echo "~~~~~~~~ AFTER ~~~~~~~~"
         printf "free_ram_mb    = %5d [MiB]\n" $free_ram_mb
         printf "swap_used_mb  = %5d [MiB]\n" $swap_used_mb
         printf "effective_free_ram_mb = %5d [MiB]\n" $effective_free_ram_mb
         echo
         exit 0

       fi
       echo "MAX_ALLOWED_SWAP_MB ($MAX_ALLOWED_SWAP_MB) > swap_used_mb ($swap_used_mb) nothing to do ..."
       printf "free_ram_mb    = %5d [MiB]\n" $free_ram_mb
       printf "swap_used_mb  = %5d [MiB]\n" $swap_used_mb
       printf "effective_free_ram_mb = %5d [MiB]\n" $effective_free_ram_mb
       exit 0
     fi
    )

return_code=$?

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-raw "$m" -o /dev/null "$HEALTHCHECK_URL"/${return_code} 2>/dev/null

. /root/bin/_script_footer.sh

exit ${return_code}

######
# template crontab entry:

# @reboot ( sleep 15 && /root/bin/healthchecks-swap-usage.sh --no_startup_delay) 2>&1

# 1 */12 * * *  /root/bin/healthchecks-swap-usage.sh --no_startup_delay
