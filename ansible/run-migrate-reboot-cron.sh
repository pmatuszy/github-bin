#!/bin/bash
# Migrate reboot crontab on selected hosts (no git-pull).
# Usage: ./run-migrate-reboot-cron.sh [gdzie_uruchomic]
# Example: ./run-migrate-reboot-cron.sh x86_ubuntu

set -o nounset
set -o pipefail

export ANSIBLE_NOCOLOR=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

TARGETS="${1:-github_bin}"

ansible-playbook -i hosts.txt github-bin-migrate-reboot-cron.yaml \
  --extra-vars "gdzie_uruchomic=${TARGETS}"
