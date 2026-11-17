#! /bin/bash

DEFSUITE=trixie

print_usage() {
	echo
	echo "USAGE: $0 target [suite [username]]"
	echo "   target    folder to prepare test environment in"
	echo "   suite     debian suite to prepare. Defaults to $DEFSUITE"
	echo "   username  username to prepare. Defaults to current user ($USER)"
	echo
}

if [ -z "$1" ]; then
	echo "ERROR: missing target!"
	print_usage
	exit 1
fi

if [ "$1" = "-h" ]; then
	print_usage
	exit 0
fi

# Use argumens with defaults
SUITE=${2:-$DEFSUITE}
ME=${3:-$USER}

echo "Preparing test environment in $1..."

echo " - Create $1"
mkdir -p $1

echo " - Install the base system"
sudo debootstrap --components=main,non-free $SUITE $1 || exit 1

echo " - Prepare the environment"
for f in passwd group shadow hosts; do
	sudo cp /etc/$f $1/etc/$f
done

echo " - Prepare home for $ME"
sudo mkdir -p $1/home/$ME
sudo chown $ME:$ME $1/home/$ME

cp $HOME/.profile $1/home/$ME/
cp $HOME/.bashrc $1/home/$ME/
sudo chown $ME:$ME $1/home/$ME/.profile
sudo chown $ME:$ME $1/home/$ME/.bashrc

echo " - Mount special filesystems"
sudo mount -t proc proc $1/proc
sudo mount -t sysfs sys $1/sys
sudo mount --bind /dev $1/dev
sudo mount -t devpts devpts $1/dev/pts

echo " - Chroot in test environment to setup locales"
sudo chroot $1 su -c 'apt-get --yes install sudo locales'
echo "en_US.UTF-8 UTF-8" | sudo tee -a $1/etc/locale.gen
sudo chroot $1 su -c 'locale-gen && update-locale LANG=en_US.UTF-8'

echo " - Enable $ME to sudo without password (in test environment only)"
# enable user to sudo without password
TMPF=$( mktemp )
cat > $TMPF << EOF

$ME  ALL=(ALL:ALL) NOPASSWD: ALL

EOF
sudo mv $TMPF $1/etc/sudoers.d/$ME
sudo chown root:root $1/etc/sudoers.d/$ME
sudo chmod 440 $1/etc/sudoers.d/$ME

echo " - Unmount special filasystems"
# Done: we can unmount special filesystems
sudo umount $1/dev/pts
sudo umount $1/dev
sudo umount $1/sys
sudo umount $1/proc

PARTFILE=$1.img
CFGDIR=$1/mnt/config

echo " - Create $PARTFILE to simulate config partition"
sudo dd if=/dev/zero of=$PARTFILE bs=1M count=10
sudo mkfs.ext4 -F $PARTFILE

echo " - Create $CFGDIR to mount simulated config partition"
sudo mkdir -p $CFGDIR

# Associa il file immagine a un loop device libero (di default in lettura/scrittura)
LOOPDEV=$( sudo losetup -f --show $PARTFILE )

echo " - Mount $LOOPDEV on $CFGDIR in read-only mode to simulate config partition."
# Ora monta il device /dev/loopX specificando 'ro' solo a livello di filesystem
sudo mount -o ro $LOOPDEV $CFGDIR

echo " - Add simulated config partition to $1/etc/fstab"
echo "$LOOPDEV  /mnt/config  ext4  defaults,ro,noatime,nofail  0  2" | sudo tee -a $1/etc/fstab > /dev/null

echo " - Copy installation package to $1/home/$ME/package"
mkdir -p $1/home/$ME/package
cp -pr $( dirname $0 )/../* $1/home/$ME/package/

MYDIR="$( dirname $0 )"

cat << EOF
Completed!

To enter test environment, type:

    $ $MYDIR/do-chroot-test.sh $1

Don't forget to remove the test and clear the environment, typing:

    $ $MYDIR/remove-chroot-test.sh $1

when you're done.

EOF

