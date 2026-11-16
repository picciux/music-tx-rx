#! /bin/bash

if [ -z "$1" ]; then
	echo "Missing target"
	exit 1
fi

SUITE=trixie
ME=$USER

[ "$2" ] && SUITE=$2 
[ "$3" ] && ME=$3 

mkdir -p $1

sudo debootstrap --components=main,non-free $SUITE $1 || exit 1

for f in passwd group shadow hosts; do
	sudo cp /etc/$f $1/etc/$f
done

sudo mkdir $1/home/$ME
sudo chown $ME:$ME $1/home/$ME

cp $HOME/.profile $1/home/$ME/
cp $HOME/.bashrc $1/home/$ME/
sudo chown $ME:$ME $1/home/$ME/.profile
sudo chown $ME:$ME $1/home/$ME/.bashrc

sudo mount -t proc proc $1/proc
sudo mount -t sysfs sys $1/sys
sudo mount --bind /dev $1/dev
sudo mount -t devpts devpts $1/dev/pts

sudo chroot $1 su -c 'apt-get --yes install sudo locales'
echo "en_US.UTF-8 UTF-8" | sudo tee -a $1/etc/locale.gen
sudo chroot $1 su -c 'locale-gen && update-locale LANG=en_US.UTF-8'

# enable user to sudo without password
TMPF=$( mktemp )
cat > $TMPF << EOF

$ME  ALL=(ALL:ALL) NOPASSWD: ALL

EOF
sudo mv $TMPF $1/etc/sudoers.d/$ME
sudo chown root:root $1/etc/sudoers.d/$ME
sudo chmod 440 $1/etc/sudoers.d/$ME

# Done: we can unmount special filesystems
sudo umount $1/dev/pts
sudo umount $1/dev
sudo umount $1/sys
sudo umount $1/proc

PARTFILE=$1/../$1.img
DESTDIR=$1/mnt/config

sudo dd if=/dev/zero of=$PARTFILE bs=1M count=10
sudo mkfs.ext4 -F $PARTFILE

sudo mkdir -p $DESTDIR

# Associa il file immagine a un loop device libero (di default in lettura/scrittura)
LOOPDEV=$( sudo losetup -f --show $PARTFILE )
# (Supponiamo che ti risponda /dev/loop0)

# Ora monta il device /dev/loop0 specificando 'ro' solo a livello di filesystem
sudo mount -o ro $LOOPDEV $DESTDIR

echo "$LOOPDEV  /mnt/config  ext4  defaults,ro,noatime,nofail  0  2" | sudo tee -a $1/etc/fstab

mkdir $1/home/$ME/package

cp -pr $( dirname $0 )/../* $1/home/$ME/package/
