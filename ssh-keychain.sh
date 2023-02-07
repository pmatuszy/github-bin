#!/bin/bash

# 2023.02.08 - v. 0.1 - initial release

. /root/bin/_script_header.sh

if [ -f "$HEALTHCHECKS_FILE" ];then
  HEALTHCHECK_URL=$(cat "$HEALTHCHECKS_FILE" |grep "^`basename $0`"|awk '{print $2}')
fi

check_if_installed keychain
eval $(keychain -q --eval id_rsa id_SSH_ed25519_20230207_OpenSSH)

keychain -l
echo
keychain -L

. /root/bin/_script_footer.sh
exit

