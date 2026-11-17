#! /bin/bash

set -e

INSTALL=/usr/bin/install
CONFIG=/mnt/config
ASTATE=/var/lib/alsa/asound.state

# verifica l'argomento
[ "$1" = "tx" ] || [ "$1" = "rx" ] || { echo; echo "USAGE: $0 tx|rx [config_path]"; echo; exit 1; }

if [ "$2" ]; then CONFIG="$2"; fi

# Installa i pacchetti necessari
echo "- Installo i pacchetti necessari..."
sudo apt-get update -q
sudo apt-get install --no-install-recommends jackd2 jack-example-tools alsa-utils -yq

# Remounting config part read-write
echo "- Preparo la partizione di config alla scrittura"
sudo mount -o remount,rw $DESTDIR$CONFIG

echo "- Installo i file..."
# Installa i file necessari
sudo $INSTALL -d $DESTDIR$CONFIG
sudo $INSTALL -d $DESTDIR/etc/default
sudo $INSTALL -d $DESTDIR/etc/systemd/system
sudo $INSTALL -d $DESTDIR/usr/local/bin

sudo $INSTALL -m 644 conf/music-trx.$1.template $DESTDIR$CONFIG/music-trx
[ -L $DESTDIR/etc/default/music-trx ] || sudo ln -s $DESTDIR$CONFIG/music-trx $DESTDIR/etc/default

cat systemd/music-trx.service.template | sed "s/%USERNAME%/$USER/" | sudo tee $DESTDIR/etc/systemd/system/music-trx.service > /dev/null
sudo $INSTALL -m 755 bin/* $DESTDIR/usr/local/bin

cat << EOF | sudo tee -a $DESTDIR$CONFIG/music-trx > /dev/null

CONFIG=$CONFIG

EOF

sudo alsactl store
sudo mv $ASTATE $DESTDIR/mnt/config/
sudo ln -s $DESTDIR/mnt/config/asound.state $ASTATE

echo "- Blocco il save automatico dei volumi all'arresto del sistema"
sudo systemctl mask alsa-store.service

echo "- Abilito il servizio music-trx"
# Abilita e avvia il servizio
sudo systemctl daemon-reload
sudo systemctl enable music-trx.service

cat << EOF
- Completato!

La partizione $CONFIG è in modalità scrittura: completa le impostazioni
e digita

  $ music-trx-config.sh disable

quando hai finito. Se avrai bisogno di modificarle di nuovo, potrai sempre
riabilitare la scrittura con

  $ music-trx-config.sh enable

Per avviare o arrestare il servizio $1, digita

  $ sudo systemctl start|stop music-trx.service

Digita:

  $ music-trx-help.sh

per gli altri comandi disponibili.

EOF
