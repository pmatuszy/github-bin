#!/bin/bash
# 2022.02.20 - v. 0.3 - zmiana nazwy komputera i dodano mkdir -p
# 2021.04.09 - v. 0.2 - changed IP to machine DNS name 
# 2020.0x.xx - v. 0.1 - initial release (date unknown)


. /root/bin/_script_header.sh

set +x

echo
echo
echo  pgm-che
echo
echo

mkdir -p /mnt/pgm-che/DyskC /mnt/pgm-che/DyskD /mnt/pgm-che/DyskE /mnt/pgm-che/DyskF

set -x

mount.cifs -o user=administrator //pgm-che.eth.che.matuszyk.com/DyskC /mnt/pgm-che/DyskC ; df -hP /mnt/desktopche/DyskC
mount.cifs -o user=administrator //pgm-che.eth.che.matuszyk.com/DyskD /mnt/pgm-che/DyskD ; df -hP /mnt/desktopche/DyskD
mount.cifs -o user=administrator //pgm-che.eth.che.matuszyk.com/DyskE /mnt/pgm-che/DyskE ; df -hP /mnt/desktopche/DyskE

set +x

. /root/bin/_script_footer.sh

