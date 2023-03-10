#!/bin/bash

# 2023.03.10 - v. 0.1 - initial release

. /root/bin/_script_header.sh

export MYSQL_USER=${MYSQL_USER:-root}

( mysql -u ${MYSQL_USER} --table --database=nextcloud_matuszyk_com <<END
-- wczorajsze wydatki
select what "co",round(amount,2) "ile CHF)", from_unixtime(b.timestamp) "timestamp",m.name "kto"
from oc_cospend_bills b, oc_cospend_members m, oc_cospend_projects p
where 
p.id=b.projectid and p.name='wydatki - Pawel'
and b.payerid=m.id
and timestamp > unix_timestamp(subdate(current_date,1))
order by b.timestamp;
END
) | strings | /opt/signal-cli/bin/signal-cli send --message-from-stdin  --note-to-self >/dev/null 2>&1 

exit $?
#####
# new crontab entry

1 6 * * * /root/bin/mysql-wydatki-wczorajsze.sh

