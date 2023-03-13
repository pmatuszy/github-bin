#!/bin/bash

# 2023.03.13 - v. 0.1 - initial release

export HEALTHCHECKS_FORCE_ID=rotate-backups.sh-www02 
/root/bin/rotate-backups.sh --dry-run --relaxed --hourly="20*24" --daily=366 --weekly=56 --monthly=24 --yearly=always --ionice=idle /mnt/luks-buffalo2/_backupy-1dyne_kopie/www02

export HEALTHCHECKS_FORCE_ID=rotate-backups.sh-cloud
/root/bin/rotate-backups.sh --dry-run --relaxed --hourly="20*24" --daily=366 --weekly=56 --monthly=24 --yearly=always --ionice=idle /mnt/luks-buffalo2/_backupy-1dyne_kopie/cloud-var-www


