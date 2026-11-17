#! /bin/bash

if [ -z "$1" ]; then
	echo "Missing target"
	exit 1
fi

PARTFILE=$1.img
CFGDIR=$1/mnt/config
LOOPDEV=$( cat $1/etc/fstab | grep /dev/loop | awk '{ print $1 }' )

echo "Removing test environment..."
echo
echo " - Unmount config file partition $CFGDIR"
sudo umount $CFGDIR

echo " - Remove config file partition $PARTFILE"
sudo rm $PARTFILE

echo " - Remove test environment $1"
sudo rm -r $1

echo " - Free loop device $LOOPDEV"
sudo losetup -d $LOOPDEV

echo
echo "Completed."
echo
