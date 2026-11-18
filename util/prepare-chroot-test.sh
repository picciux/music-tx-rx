#! /bin/bash

DEFSUITE=trixie

print_usage() {
	echo
	echo "USO: $0 destinazione [suite [utente]]"
	echo "   destinazione  cartella in cui preparare l'ambiente di test"
	echo "   suite         suite debian da preparare. Predefinita: $DEFSUITE"
	echo "   utente        utente da preparare. Predefinito: utente corrente ($USER)"
	echo
}

if [ -z "$1" ]; then
	echo "ERRORE: manca la destinazione!"
	print_usage
	exit 1
fi

if [ "$1" = "-h" ]; then
	print_usage
	exit 0
fi

# Usa gli argomenti, con valori predefiniti
SUITE=${2:-$DEFSUITE}
ME=${3:-$USER}

echo "Preparo l'ambiente di test in $1..."

echo " - Creo $1"
mkdir -p $1

echo " - Installo il sistema di base"
sudo debootstrap --components=main,non-free $SUITE $1 || exit 1

echo " - Preparo l'ambiente"
for f in passwd group shadow hosts; do
	sudo cp /etc/$f $1/etc/$f
done

echo " - Preparo la home per $ME"
sudo mkdir -p $1/home/$ME
sudo chown $ME:$ME $1/home/$ME

cp $HOME/.profile $1/home/$ME/
cp $HOME/.bashrc $1/home/$ME/
sudo chown $ME:$ME $1/home/$ME/.profile
sudo chown $ME:$ME $1/home/$ME/.bashrc

echo " - Monto i filesystem speciali"
sudo mount -t proc proc $1/proc
sudo mount -t sysfs sys $1/sys
sudo mount --bind /dev $1/dev
sudo mount -t devpts devpts $1/dev/pts

echo " - Entro in chroot nell'ambiente di test per impostare i locale"
sudo chroot $1 su -c 'apt-get --yes install sudo locales'
echo "en_US.UTF-8 UTF-8" | sudo tee -a $1/etc/locale.gen
sudo chroot $1 su -c 'locale-gen && update-locale LANG=en_US.UTF-8'

echo " - Abilito $ME a usare sudo senza password (solo nell'ambiente di test)"
# abilita l'utente a usare sudo senza password
TMPF=$( mktemp )
cat > $TMPF << EOF

$ME  ALL=(ALL:ALL) NOPASSWD: ALL

EOF
sudo mv $TMPF $1/etc/sudoers.d/$ME
sudo chown root:root $1/etc/sudoers.d/$ME
sudo chmod 440 $1/etc/sudoers.d/$ME

echo " - Smonto i filesystem speciali"
# Fatto: possiamo smontare i filesystem speciali
sudo umount $1/dev/pts
sudo umount $1/dev
sudo umount $1/sys
sudo umount $1/proc

PARTFILE=$1.img
CFGDIR=$1/mnt/config

echo " - Creo $PARTFILE per simulare la partizione di config"
sudo dd if=/dev/zero of=$PARTFILE bs=1M count=10
sudo mkfs.ext4 -F $PARTFILE

echo " - Creo $CFGDIR dove montare la partizione di config simulata"
sudo mkdir -p $CFGDIR

# Associa il file immagine a un loop device libero (di default in lettura/scrittura)
LOOPDEV=$( sudo losetup -f --show $PARTFILE )

echo " - Monto $LOOPDEV su $CFGDIR in sola lettura per simulare la partizione di config."
# Ora monta il device /dev/loopX specificando 'ro' solo a livello di filesystem
sudo mount -o ro $LOOPDEV $CFGDIR

echo " - Aggiungo la partizione di config simulata a $1/etc/fstab"
echo "$LOOPDEV  /mnt/config  ext4  defaults,ro,noatime,nofail  0  2" | sudo tee -a $1/etc/fstab > /dev/null

echo " - Copio il pacchetto di installazione in $1/home/$ME/package"
mkdir -p $1/home/$ME/package
cp -pr $( dirname $0 )/../* $1/home/$ME/package/

MYDIR="$( dirname $0 )"

cat << EOF
Completato!

Per entrare nell'ambiente di test, digita:

    $ $MYDIR/do-chroot-test.sh $1

Non dimenticare di rimuovere il test e ripulire l'ambiente, digitando:

    $ $MYDIR/remove-chroot-test.sh $1

quando hai finito.

EOF

