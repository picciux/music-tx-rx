#! /bin/bash

set -e

INSTALL=/usr/bin/install
CONFIG=/mnt/config
ASTATE=/var/lib/alsa/asound.state

# verifica l'argomento
[ "$1" = "tx" ] || [ "$1" = "rx" ] || { echo "USAGE: $0 tx|rx [config_path]"; exit 1; }

if [ "$2" ]; then CONFIG="$2"; fi

# Installa i pacchetti necessari
echo "Installo i pacchetti necessari..."
sudo apt-get update -q
sudo apt-get install --no-install-recommends jackd2 alsa-utils -yq

# Remounting config part read-write
echo "Preparing config partition for write"
sudo mount -o remount,rw $DESTDIR$CONFIG

echo "Installo i file..."
# Installa i file necessari
sudo $INSTALL -d $DESTDIR$CONFIG
sudo $INSTALL -d $DESTDIR/etc/default
sudo $INSTALL -d $DESTDIR/etc/systemd/system
sudo $INSTALL -d $DESTDIR/usr/local/bin

sudo $INSTALL -m 644 conf/audio-$1 $DESTDIR$CONFIG

[ -L $DESTDIR/etc/default/audio-$1 ] || sudo ln -s $DESTDIR$CONFIG/audio-$1 $DESTDIR/etc/default
sudo $INSTALL -m 644 systemd/audio-$1.service $DESTDIR/etc/systemd/system
sudo $INSTALL -m 755 bin/audio-* $DESTDIR/usr/local/bin
sudo $INSTALL -m 755 bin/start-audio-$1.sh $DESTDIR/usr/local/bin
sudo $INSTALL -m 755 bin/view-audio-$1-log.sh $DESTDIR/usr/local/bin

cat << EOF | sudo tee -a $DESTDIR$CONFIG/audio-$1

CONFIG=$CONFIG

EOF

sudo alsactl store
sudo mv $ASTATE $DESTDIR/mnt/config/
sudo ln -s $DESTDIR/mnt/config/asound.state $ASTATE

sudo systemctl mask alsa-store.service

# Abilita e avvia il servizio
sudo systemctl daemon-reload
sudo systemctl enable audio-$1.service

cat << EOF

La partizione $CONFIG è in modalità scrittura: completa le impostazioni
e digita

  $ audio-config-remount.sh ro

quando hai finito. Se avrai bisogno di modificarle di nuovo, potrai sempre
riabilitare la scrittura con

  $ audio-config-remount.sh rw

Per avviare o arrestare il servizio audio $1, digita

  $ sudo systemctl start|stop audio-$1.service

EOF
