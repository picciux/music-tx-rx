#! /bin/bash

if [ -z "$1" ]; then
	echo "Missing target"
	exit 1
fi

TARGET=${1%/}
PARTFILE=$TARGET.img
CFGDIR=$TARGET/mnt/config
LOOPDEV=$( grep /dev/loop "$TARGET/etc/fstab" | awk '{ print $1 }' )

echo "Removing test environment..."
echo
echo " - Unmount config file partition $CFGDIR"
sudo umount "$CFGDIR"

# Non cancellare mai se ci sono ancora mount attivi (es. /dev, /proc):
# rm -r li attraverserebbe e cancellerebbe file del sistema reale.
if [ "$( findmnt -Rn "$TARGET" 2>/dev/null | wc -l )" -gt 0 ]; then
	echo "ERROR: ci sono ancora mount attivi in $TARGET:" >&2
	findmnt -R "$TARGET" >&2
	echo "Smontali prima di rimuovere l'ambiente." >&2
	exit 1
fi

echo " - Remove config file partition $PARTFILE"
sudo rm -- "$PARTFILE"

echo " - Remove test environment $TARGET"
sudo rm -r --one-file-system -- "$TARGET"

echo " - Free loop device $LOOPDEV"
sudo losetup -d "$LOOPDEV"

echo
echo "Completed."
echo
