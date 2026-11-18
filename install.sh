#! /bin/bash

set -e

INSTALL=/usr/bin/install
CONFIG=/mnt/config
ASTATE=/var/lib/alsa/asound.state

# verifica l'argomento
[ "$1" = "tx" ] || [ "$1" = "rx" ] || { echo; echo "USO: $0 tx|rx [percorso_config]"; echo; exit 1; }

if [ "$2" ]; then CONFIG="$2"; fi

# Utente che eseguirà il servizio (anche se lanciato con sudo)
RUN_USER=${SUDO_USER:-$USER}
id -nG "$RUN_USER" | grep -qw audio || echo "ATTENZIONE: $RUN_USER non è nel gruppo audio (sudo usermod -aG audio $RUN_USER)"

# Installa i pacchetti necessari
echo "- Installo i pacchetti necessari..."
sudo apt-get update -q
sudo apt-get install --no-install-recommends jackd2 jack-example-tools alsa-utils -yq

# Remounting config part read-write
echo "- Preparo la partizione di config alla scrittura"
if mountpoint -q "$DESTDIR$CONFIG"; then
    sudo mount -o remount,rw "$DESTDIR$CONFIG"
fi

echo "- Installo i file..."
# Installa i file necessari
sudo $INSTALL -d $DESTDIR$CONFIG
sudo $INSTALL -d $DESTDIR/etc/default
sudo $INSTALL -d $DESTDIR/etc/systemd/system
sudo $INSTALL -d $DESTDIR/usr/local/bin

sudo $INSTALL -m 644 conf/music-trx.$1.template $DESTDIR$CONFIG/music-trx
[ -L $DESTDIR/etc/default/music-trx ] || sudo ln -s $DESTDIR$CONFIG/music-trx $DESTDIR/etc/default

cat systemd/music-trx.service.template | sed "s/%USERNAME%/$RUN_USER/" | sudo tee $DESTDIR/etc/systemd/system/music-trx.service > /dev/null
sudo $INSTALL -m 755 bin/* $DESTDIR/usr/local/bin

cat << EOF | sudo tee -a $DESTDIR$CONFIG/music-trx > /dev/null

CONFIG=$CONFIG

EOF

# Sposta lo stato ALSA sulla partizione di config (solo la prima volta)
if [ ! -L "$ASTATE" ]; then
    sudo alsactl store || echo "ATTENZIONE: alsactl store fallito (scheda USB collegata?)"
    if [ -f "$ASTATE" ]; then
        sudo mv "$ASTATE" "$DESTDIR$CONFIG/"
    fi
    sudo ln -sf "$DESTDIR$CONFIG/asound.state" "$ASTATE"
fi

# Maschera il salvataggio automatico dei volumi (se l'unit esiste)
if systemctl list-unit-files alsa-store.service 2>/dev/null | grep -q alsa-store; then
    echo "- Blocco il save automatico dei volumi all'arresto del sistema"
    sudo systemctl mask alsa-store.service
fi

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
