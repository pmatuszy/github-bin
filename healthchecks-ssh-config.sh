#!/bin/bash
# v. 20260716.163224 - versioning format v. YYYYMMDD.HH24MISS
# 2026.07.16 - v. 0.2 - rename from sprawdz-ssh-config.sh; add -h/-v/--no_startup_delay
# 2026.05.26 - user-facing messages translated from Polish to English
# 2023.02.08 - v. 0.1 - initial release
#
# healthchecks-ssh-config.sh
#
# Verify ssh-agent and keychain keys; report to Healthchecks.
#

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

Verify ssh-agent and keychain keys; report to Healthchecks.
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

check_if_installed keychain

##########################################################################################################
function spr_zaladowanie_klucze() {
  keychain --nocolor "${1}" 2>&1 | egrep -q "Known ssh key: .*$1" 2>/dev/null
  if [ $? -ne 0 ];then
    echo "(PGM) PROBLEM - Key ${1} is NOT loaded into ssh-agent"
    return 1
  else 
    echo "(PGM) OK - Key ${1} is loaded into ssh-agent"
    return 0
  fi
}
##########################################################################################################
spr_czy_agent_is_running() {
  pgrep  ssh-agent >/dev/null
  if [ $? -ne 0 ];then
    echo "(PGM) PROBLEM - ssh-agent is not running"
    agent_status="PROBLEM"
  else
    echo "(PGM) OK - ssh-agent is running"
    agent_status="OK"
  fi
}
##########################################################################################################
export agent_status="PROBLEM"
export key1_status="PROBLEM"
export key2_status="PROBLEM"

export HC_MESSAGE=""
HC_MESSAGE=$(
cat  $0|grep -e '# *20[123][0-9]'|head -n 1 | awk '{print "script version: " $5 " (dated "$2")"}'
echo "current date: `date '+%Y.%m.%d %H:%M'`"

spr_czy_agent_is_running
if spr_zaladowanie_klucze id_ed25519 ; then
  key1_status="OK"
else
  key1_status="PROBLEM"
fi
if spr_zaladowanie_klucze id_SSH_ed25519_20230207_OpenSSH ; then
  key2_status="OK"
else
  key2_status="PROBLEM"
fi
)

echo "====== HC_MESSAGE START"
echo "$HC_MESSAGE"
echo "====== HC_MESSAGE FINISH"

echo $agent_status $key1_status $key2_status

if [[ $agent_status == "OK" ]] && [[ "$key1_status" == "OK" ]] && [[ "$key2_status" == "OK" ]] ;then
  [ $script_is_run_interactively == 1 ] && echo "(PGM) all is good "
  echo "$HC_MESSAGE" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL" 2>/dev/null
else
  [ $script_is_run_interactively == 1 ] && echo "(PGM) PROBLEM - OVERALL status is BAD"
  echo "$HC_MESSAGE" | /usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 --data-binary @- -o /dev/null "$HEALTHCHECK_URL"/fail 2>/dev/null
fi

exit $?

#####
# new crontab entry

0 * * * * /root/bin/healthchecks-ssh-config.sh --no_startup_delay
