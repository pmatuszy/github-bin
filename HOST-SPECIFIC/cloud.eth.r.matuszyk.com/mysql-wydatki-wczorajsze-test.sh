#!/bin/bash

# 2023.03.14 - v. 0.2 - removing national characters
# 2023.03.11 - v. 0.2 - added messages to A.
# 2023.03.10 - v. 0.1 - initial release

. /root/bin/_script_header.sh

export MYSQL_USER=${MYSQL_USER:-root}

if [ ! -f "/root/SECRET/telefony.txt" ];then
  echo "ERROR: file /root/SECRET/telefony.txt doesn't exist"
  exit 2
fi

tel_a=$(cat /root/SECRET/telefony.txt | grep " a$" | awk '{print $1}')
tel_p=$(cat /root/SECRET/telefony.txt | grep " p$" | awk '{print $1}')

export wydatki_Ani=$(
echo wczorajsze i dzisiejsze wydatki Ani
mysql -u ${MYSQL_USER} --table --database=nextcloud_matuszyk_com <<END
-- wczorajsze wydatki Ani
select what "co",round(amount,2) "ile CHF)", from_unixtime(b.timestamp) "timestamp"
from oc_cospend_bills b, oc_cospend_members m, oc_cospend_projects p
where
upper(m.name) like '%ANIA%'
and p.id=b.projectid and p.name='wydatki - Pawel'
and b.payerid=m.id
and timestamp > unix_timestamp(subdate(current_date,30))
and timestamp < unix_timestamp(subdate(current_date,0))
order by b.timestamp;
END
)

message=$(echo "$wydatki_Ani" | iconv -f utf8 -t ascii//TRANSLIT)
echo "${message}"

