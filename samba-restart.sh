#!/bin/bash

# 2026.04.21 - v. 0.2 - shebang; set -e; optional DEBUG=1 for xtrace; single systemctl restart
# 2020.12.25 - v. 0.1 - initial release

set -e
[[ "${DEBUG:-}" == 1 ]] && set -x

systemctl restart smbd.service nmbd.service
