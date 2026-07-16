#!/bin/bash
# Run from Ansible control host (directory containing hosts.txt).
# Default: all github_bin inventory groups (rpi_ubuntu + rpi_raspbian + x86_ubuntu).

set -o nounset
set -o pipefail

export ANSIBLE_NOCOLOR=1

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "${SCRIPT_DIR}"

TARGETS="${1:-github_bin}"

ansible-playbook -i hosts.txt github-bin-pull.yaml \
  --extra-vars "gdzie_uruchomic=${TARGETS}"
