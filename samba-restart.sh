# 2020.12.25 - v. 0.1 - initial release

set -x
systemctl restart smbd.service 
systemctl restart nmbd.service
set +x
