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
if mountpoint -q "$DESTDIR$CONFIG"; then
    sudo mount -o remount,rw "$DESTDIR$CONFIG"
fi

echo "- Arresto il servizio..."
sudo systemctl stop music-trx.service || true
sudo systemctl disable music-trx.service || true

echo "- Ripristino il salvataggio automatico dei volumi all'arresto del sistema"
sudo systemctl unmask alsa-store.service

echo "- Rimuovo i file..."

sudo rm -f $DESTDIR/etc/default/music-trx
sudo rm -f $DESTDIR/etc/systemd/system/music-trx.service
sudo rm -f $DESTDIR/usr/local/bin/music-trx-*
sudo rm -f $DESTDIR/usr/local/bin/start-music-trx.sh
# symlink dello stato ALSA (altrimenti resterebbe pendente)
sudo rm -f "$ASTATE"
sudo rm -f $DESTDIR$CONFIG/asound.state
sudo rm -f $DESTDIR$CONFIG/music-trx


# ricarica i servizi
sudo systemctl daemon-reload

# Rimuove i pacchetti JACK (alsa-utils resta: serve anche ad altro sul Pi)
echo "Disinstallo i pacchetti necessari..."
sudo apt-get purge jackd2 jack-example-tools -yq
sudo apt-get autoremove -yq

# Riprotegge la partizione di config
if mountpoint -q "$DESTDIR$CONFIG"; then
    sync
    sudo mount -o remount,ro "$DESTDIR$CONFIG"
fi

