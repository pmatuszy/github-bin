#!/bin/bash
# 2026.07.16 - v. 0.3 - compat wrapper: exec healthchecks-reboot-required.sh (cron migration retires this path)
# 2023.01.09 - v. 0.2 - small changes (along with the random delay) and a new crontab entry after the reboot
# 2022.11.03 - v. 0.1 - initial release (date unknown)
#
# sprawdz-czy-reboot-required.sh
#
# Legacy name kept for hosts not yet migrated; forwards to healthchecks-reboot-required.sh.
#

exec "$(cd "$(dirname "$0")" && pwd -P)/healthchecks-reboot-required.sh" "$@"
