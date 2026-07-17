#!/bin/bash
# v. 20260716.164840 - add -h/--help, -v/--version, --no_startup_delay

# 2026.06.01 - v. 0.3 - config-archive (ARCHIWUM_CONFIGOW) backups now land directly in the server folder (UBNT/<Server>/), not a nested ARCHIWUM_CONFIGOW-<Server> subdir; rename SOURCE/DEST vars to SOURCE/DEST
# 2023.07.17 - v. 0.2 - added output redirection to /dev/null
# 2023.03.14 - v. 0.1 - initial release

##########
# EdgeSS #
##########

show_help() {
  cat <<EOF
Usage: $(basename "$0") [-h|--help] [-v|--version] [--no_startup_delay]

EdgeSS #

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

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeSS_kat1
SOURCE=192.168.17.1:/root/config/*
DEST=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeSS/EdgeSS-root_config
eval /root/bin/sciagnij-backupy.sh $SOURCE $DEST --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeSS_kat2
SOURCE=192.168.17.1:/root/adresy-ip-historia/*
DEST=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeSS/EdgeSS-root-adresy-ip-historia
eval /root/bin/sciagnij-backupy.sh $SOURCE $DEST --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeSS_kat3
SOURCE=192.168.17.1:/config/ARCHIWUM_CONFIGOW-EdgeSS/
DEST=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeSS/
eval /root/bin/sciagnij-backupy.sh $SOURCE $DEST --remove-source-files >/dev/null 2>&1

###########
# EdgeCHE #
###########

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeCHE_kat1
SOURCE=192.168.200.1:/root/config/*
DEST=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeCHE/EdgeCHE-root_config
eval /root/bin/sciagnij-backupy.sh $SOURCE $DEST --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeCHE_kat2
SOURCE=192.168.200.1:/root/adresy-ip-historia/*
DEST=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeCHE/EdgeCHE-root-adresy-ip-historia
eval /root/bin/sciagnij-backupy.sh $SOURCE $DEST --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeCHE_kat3
SOURCE=192.168.200.1:/config/ARCHIWUM_CONFIGOW-EdgeCHE/
DEST=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeCHE/
eval /root/bin/sciagnij-backupy.sh $SOURCE $DEST --remove-source-files >/dev/null 2>&1

#########
# EdgeR #
#########

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeR_kat1
SOURCE=192.168.1.1:/root/config/*
DEST=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeR/EdgeR-root_config
eval /root/bin/sciagnij-backupy.sh $SOURCE $DEST --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeR_kat2
SOURCE=192.168.1.1:/root/adresy-ip-historia/*
DEST=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeR/EdgeR-root-adresy-ip-historia
eval /root/bin/sciagnij-backupy.sh $SOURCE $DEST --remove-source-files >/dev/null 2>&1

export HEALTHCHECKS_FORCE_ID=sciagnij-backupy.sh-EdgeR_kat3
SOURCE=192.168.1.1:/config/ARCHIWUM_CONFIGOW-EdgeR/
DEST=/mnt/luks-buffalo2/_backupy-1dyne_kopie/UBNT/EdgeR/
eval /root/bin/sciagnij-backupy.sh $SOURCE $DEST --remove-source-files >/dev/null 2>&1
