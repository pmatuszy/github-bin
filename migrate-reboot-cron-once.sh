#!/bin/bash

# 2026.07.16 - v. 0.1 - one-shot crontab migration: sprawdz-czy-reboot-required.sh → healthchecks-reboot-required.sh
#
# migrate-reboot-cron-once.sh
#
# Idempotent post-pull hook: rewrite root crontab paths to healthchecks-reboot-required.sh.
# Skips when marker ${profile_location_dir:-$HOME}/.git-bin-migrated-reboot-cron-v1 exists.
#

. /root/bin/_script_header.sh NO_STARTUP_DELAY

profile_root="${profile_location_dir:-$HOME}"
bin_dir="${profile_root}/bin"
marker="${profile_root}/.git-bin-migrated-reboot-cron-v1"
old_name=sprawdz-czy-reboot-required.sh
new_name=healthchecks-reboot-required.sh

if [[ -f "${marker}" ]]; then
  echo "(PGM) ${marker} exists — reboot cron migration already done"
  exit 0
fi

if [[ ! -f "${bin_dir}/${new_name}" ]]; then
  echo "(PGM) ${bin_dir}/${new_name} missing — skip reboot cron migration" >&2
  exit 0
fi

if ! crontab -l >/dev/null 2>&1; then
  echo "(PGM) no root crontab — nothing to migrate"
  touch "${marker}"
  exit 0
fi

if ! crontab -l 2>/dev/null | grep -qF "${old_name}"; then
  echo "(PGM) crontab has no ${old_name} — marking migration done"
  touch "${marker}"
  exit 0
fi

tmp="$(mktemp)"
crontab -l 2>/dev/null | sed "s|${old_name}|${new_name}|g" > "${tmp}"
crontab "${tmp}"
rm -f "${tmp}"

touch "${marker}"
echo "(PGM) crontab updated: ${old_name} → ${new_name}"

exit 0
