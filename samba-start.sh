# 2020.12.25 - v. 0.1 - initial release

set -x
systemctl start smbd.service 
systemctl start nmbd.service
set +x
