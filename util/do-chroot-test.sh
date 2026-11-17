#! /bin/bash

if [ "$1" = "" ]; then
	echo "Missing target"
	exit 1
fi

MOUNT_HOME=
MOUNT_PULSE=
CMD=

ME=$USER

if [ "$2" = "-h" ]; then
	MOUNT_HOME=yes
	#MOUNT_PULSE=yes
elif [ "$2" ]; then
	# Use username specified on cmdline
	ME=$2
fi

[ "$3" ] && CMD="-c $3"

RUN_USER_DIR="/run/user/$( id -u )"

# Mount special filesystems
echo "- Mount filesystems..."
sudo mount -t proc proc $1/proc
sudo mount -t sysfs sys $1/sys
sudo mount --bind /dev $1/dev
sudo mount -t devpts devpts $1/dev/pts
sudo mkdir -p $1/$RUN_USER_DIR
sudo mount --bind $RUN_USER_DIR $1/$RUN_USER_DIR

[ "$MOUNT_HOME" = "yes" ] && mount --bind /home/$ME $1/home/$ME

echo "- Prepare system"
sudo cp /etc/resolv.conf $1/etc/

echo "- Enter test environment (type 'exit' to leave)."
debian_chroot="$1" sudo -E chroot $1 su --login -w debian_chroot,DISPLAY,Xauthority,XAUTHORITY,DBUS_SESSION_BUS_ADDRESS $CMD $ME

echo "Unmount filesystems"

[ "$MOUNT_HOME" = "yes" ] && umount $1/home/$ME
sudo umount --recursive $1/$RUN_USER_DIR
sudo umount $1/dev/pts
sudo umount $1/dev
sudo umount $1/sys
sudo umount $1/proc

cat << EOF

Exited from test environment.

Don't forget to remove the test and clear the environment, typing:

    $ $MYDIR/remove-chroot-test.sh $1

if you don't need it anymore.

EOF
