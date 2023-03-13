#!/bin/bash

# 2023.03.13 - v. 0.1 - initial release

policy='--dry-run --relaxed --hourly="20*24" --daily=366 --weekly=56 --monthly=24 --yearly=always --ionice=idle'

export HEALTHCHECKS_FORCE_ID=rotate-backups.sh-www02 
export katalog=/mnt/luks-buffalo2/_backupy-1dyne_kopie/www02
eval /root/bin/rotate-backups.sh $policy $katalog

export HEALTHCHECKS_FORCE_ID=rotate-backups.sh-cloud
export katalog=/mnt/luks-buffalo2/_backupy-1dyne_kopie/cloud-var-www
eval /root/bin/rotate-backups.sh $policy $katalog
