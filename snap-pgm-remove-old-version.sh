#!/bin/bash

# 2023.07.31 - v. 0.1 - initial release

. /root/bin/_script_header.sh

# from https://askubuntu.com/questions/1371833/howto-free-up-space-properly-on-my-var-lib-snapd-filesystem-when-snapd-is-unava

LANG=en_US.UTF-8 snap list --all | awk '/disabled/{print $1, $3}' |
while read pkg revision; do
  sudo snap remove "$pkg" --revision="$revision"
done

. /root/bin/_script_footer.sh
