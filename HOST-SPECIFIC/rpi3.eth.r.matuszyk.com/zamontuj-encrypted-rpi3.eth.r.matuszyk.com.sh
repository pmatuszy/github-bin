#!/bin/bash

# 2022.10.19 - v. 0.3 - dodane sprawdzenie czy dziala server vpn
# 2022.09.30 - v. 0.2 - dodane wsparcie dla healthcheckow
# 2021.09.06 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

nazwa_pliku=/encrypted.luks2
cryptsetup luksOpen ${nazwa_pliku} encrypted_luks_file_in_root
mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted

df -h /encrypted

echo startuje vpnserver

/encrypted/vpnserver/vpnserver start

/root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh
/root/bin/sprawdz-czy-dziala-server-vpn.sh

. /root/bin/_script_footer.sh
