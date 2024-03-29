#!/bin/bash

# 2023.02.28 - v. 0.5 - curl with kod_powrotu
# 2022.07.01 - v. 0.4 - dodalem wywolanie /root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh na koncu
# 2022.06.21 - v. 0.3 - dodalem obsluge healthcheckow
# 2021.09.19 - v. 0.2 - dodana funkcja fsck, czytanie hasla do zmiennej
# 2021.01.30 - v. 0.1 - initial release (date unknown)

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

echo
read -r -p "Wpisz haslo: " -s PASSWD
echo

################################################################################
zrob_fsck() {
################################################################################

echo "################################################################################"

echo
echo czas na fsck $1 ...
echo
echo "################################################################################"

fsck -C -M -R -T -V $1

echo
echo ... and once again fsck
echo
fsck $1
}
################################################################################

nazwa_pliku=/encrypted.luks2

echo -n "$PASSWD" | cryptsetup luksOpen ${nazwa_pliku} encrypted_luks_file_in_root -d -
zrob_fsck /dev/mapper/encrypted_luks_file_in_root

mount -o noatime /dev/mapper/encrypted_luks_file_in_root /encrypted
kod_powrotu=$?

/usr/bin/curl -fsS -m 100 --retry 10 --retry-delay 10 -o /dev/null "$HEALTHCHECK_URL"/${kod_powrotu} 2>/dev/null

df -h /encrypted
echo

/root/bin/sprawdz-czy-encrypted-jest-zamontowany.sh

. /root/bin/_script_footer.sh
exit ${kod_powrotu}
