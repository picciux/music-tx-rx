#! /bin/bash

set -e

[ -z "$1" ] && { echo "USAGE: $0 partition_device mount_point"; exit 1; }

DEV=$1
MP=$2

echo "===================================="
sudo blkid $DEV
echo "===================================="
echo
cat << EOF
Use UUID and append a line in /etc/fstab as follows:

  UUID=xxxx-xxxx-xxxx-xxxx  $MP  ext4  defaults,ro,noatime,nofail  0  2

EOF

