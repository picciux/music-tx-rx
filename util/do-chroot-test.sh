#! /bin/bash

if [ "$1" = "" ]; then
	echo "ERRORE: manca la directory di destinazione"
	exit 1
fi

MOUNT_HOME=
MOUNT_PULSE=
CMD=

ME=$USER
MYDIR="$( cd "$( dirname "$0" )" && pwd )"

if [ "$2" = "-h" ]; then
	MOUNT_HOME=yes
	#MOUNT_PULSE=yes
elif [ "$2" ]; then
	# Usa il nome utente indicato da riga di comando
	ME=$2
fi

[ "$3" ] && CMD="-c $3"

RUN_USER_DIR="/run/user/$( id -u )"

# Monta i filesystem speciali
echo "- Monto i filesystem..."
sudo mount -t proc proc $1/proc
sudo mount -t sysfs sys $1/sys
sudo mount --bind /dev $1/dev
sudo mount -t devpts devpts $1/dev/pts
sudo mount --bind /dev/shm $1/dev/shm
sudo mkdir -p $1/$RUN_USER_DIR
sudo mount --bind $RUN_USER_DIR $1/$RUN_USER_DIR

[ "$MOUNT_HOME" = "yes" ] && sudo mount --bind /home/$ME $1/home/$ME

echo "- Preparo il sistema"
sudo cp /etc/resolv.conf $1/etc/

echo "- Entro nell'ambiente di test (digita 'exit' per uscire)."
debian_chroot="$1" sudo -E chroot $1 su --login -w debian_chroot,DISPLAY,Xauthority,XAUTHORITY,DBUS_SESSION_BUS_ADDRESS $CMD $ME

echo "Smonto i filesystem"

[ "$MOUNT_HOME" = "yes" ] && sudo umount $1/home/$ME
sudo umount --recursive $1/$RUN_USER_DIR
sudo umount $1/dev/shm
sudo umount $1/dev/pts
sudo umount $1/dev
sudo umount $1/sys
sudo umount $1/proc

cat << EOF

Uscito dall'ambiente di test.

Non dimenticare di rimuovere il test e ripulire l'ambiente, digitando:

    $ $MYDIR/remove-chroot-test.sh $1

quando non ti serve più.

EOF
