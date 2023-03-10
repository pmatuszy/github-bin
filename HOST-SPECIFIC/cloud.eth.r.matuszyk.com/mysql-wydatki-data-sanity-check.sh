#!/bin/bash

# 2023.03.10 - v. 0.1 - initial release

. /root/bin/_script_header.sh

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
