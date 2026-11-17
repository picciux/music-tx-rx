#! /bin/bash

set -e

[ $# -lt 2 ] && { echo "USAGE: $0 partition_device mount_point"; exit 1; }

DEV=$1
MP=$2

UUID=$( sudo blkid $DEV | grep -oP 'UUID="\K[^"]+' )
echo "Appending to /etc/fstab... "
echo "UUID=$UUID  $MP  ext4  defaults,ro,noatime,nofail  0  2" | sudo tee -a /etc/fstab
echo "done."
echo

