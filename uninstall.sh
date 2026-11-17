#! /bin/bash

CF=/etc/default/music-trx

if [ ! -f "$CF" ]; then
    echo "ERROR: no audio config file found."
    exit 1
fi


source "$CF"

ASTATE=/var/lib/alsa/asound.state

# Remounting config part read-write
echo "- Preparo la partizione di config alla scrittura"
sudo mount -o remount,rw $DESTDIR$CONFIG

echo "- Arresto il servizio..."
sudo systemctl stop music-trx.service
sudo systemctl disable music-trx.service

echo "- Ripristino il salvataggio automatico dei volumi all'arresto del sistema"
sudo systemctl unmask alsa-store.service

echo "- Rimuovo i file..."

sudo rm $DESTDIR/etc/default/music-trx
sudo rm $DESTDIR/etc/systemd/system/music-trx.service
sudo rm $DESTDIR/usr/local/bin/music-trx-*
sudo rm $DESTDIR/usr/local/bin/start-music-trx.sh
sudo rm $DESTDIR$CONFIG/asound.state
sudo rm $DESTDIR$CONFIG/music-trx


# ricarica i servizi
sudo systemctl daemon-reload

# Installa i pacchetti necessari
echo "Disinstallo i pacchetti necessari..."
sudo apt-get purge --no-install-recommends jackd2 jack-example-tools alsa-utils -yq
sudo apt-get autoremove

