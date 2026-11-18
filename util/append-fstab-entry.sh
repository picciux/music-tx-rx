#! /bin/bash

set -e

[ $# -lt 2 ] && { echo "USO: $0 device_partizione punto_di_mount"; exit 1; }

DEV=$1
MP=$2

UUID=$( sudo blkid $DEV | grep -oP 'UUID="\K[^"]+' )
echo "Aggiungo a /etc/fstab... "
echo "UUID=$UUID  $MP  ext4  defaults,ro,noatime,nofail  0  2" | sudo tee -a /etc/fstab
echo "fatto."
echo

