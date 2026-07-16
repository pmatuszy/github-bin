#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2023.03.10 - v. 0.1 - initial release

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

new crontab entry

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

export MYSQL_USER=${MYSQL_USER:-root}

{
echo data sanity check;
 mysql -u ${MYSQL_USER} --table --database=nextcloud_matuszyk_com <<END
-- rachunki z wiecej niz 1 "For Whom" (powinien byc max 1, czyli entries, ktore zwroci to zapytanie
-- powinny byc poprawione)
select p.name,b.id,what,amount,m.id,m.name, from_unixtime(b.timestamp) 
from oc_cospend_bills b , oc_cospend_members m, oc_cospend_paymentmodes p
where 
  b.payerid=m.id and b.paymentmodeid=p.id
and upper(p.name)='CASH'
and
b.id in
(select billid from oc_cospend_bill_owers 
group by billid having count(*)>1)
order by b.timestamp desc;
END
} | strings | /opt/signal-cli/bin/signal-cli send --message-from-stdin  --note-to-self >/dev/null 2>&1 

exit $?
#####
# new crontab entry

1 6 * * * /root/bin/mysql-wydatki-data-sanity-check.sh
