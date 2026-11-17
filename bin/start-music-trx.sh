#!/bin/bash

# Carica la configurazione (segue automaticamente il symlink verso /mnt/config/music-trx)
CONFIG_FILE="/etc/default/music-trx"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
else
    echo "ERRORE: File di configurazione $CONFIG_FILE non trovato!" >&2
    exit 1
fi

# Valori di fallback di sicurezza
ROLE=${ROLE:-"rx"}
AUDIO_DEVICE=${AUDIO_DEVICE:-"hw:Headphones"}
SAMPLE_RATE=${SAMPLE_RATE:-48000}
BUFFER_SIZE=${BUFFER_SIZE:-256}
PERIODS=${PERIODS:-2}

# Funzione di pulizia alla chiusura del servizio (evita processi zombie al restart)
cleanup() {
    echo "Arresto dei processi audio ($ROLE)..."
    kill $(jobs -p) 2>/dev/null
    wait
}
trap cleanup SIGTERM SIGINT

case "$ROLE" in
    tx|TX)
        echo "Avvio nodo in modalita TRASMETTITORE (Device: $AUDIO_DEVICE, SR: $SAMPLE_RATE, Buf: $BUFFER_SIZE)..."
        /usr/bin/jackd -R -P 70 -d alsa -d "$AUDIO_DEVICE" -r "$SAMPLE_RATE" -p "$BUFFER_SIZE" -n "$PERIODS" -i 2 -o 0 &
        JACK_PID=$!

        /usr/bin/jack_wait -w -t 10
        /usr/bin/jack_load netmanager

        wait $JACK_PID
        ;;

    rx|RX)
        echo "Avvio nodo in modalita RICEVITORE (Device: $AUDIO_DEVICE, SR: $SAMPLE_RATE, Buf: $BUFFER_SIZE)..."
        /usr/bin/jackd -R -P 70 -d net &
        JACK_PID=$!

        /usr/bin/jack_wait -w -t 10
        /usr/bin/alsa_out -d "$AUDIO_DEVICE" -r "$SAMPLE_RATE" -p "$BUFFER_SIZE" -n "$PERIODS" &
        ALSA_PID=$!

        sleep 2
        /usr/bin/jack_connect system:capture_1 alsa_out:playback_1
        /usr/bin/jack_connect system:capture_2 alsa_out:playback_2

        wait $JACK_PID
        ;;

    *)
        echo "ERRORE: Valore ROLE='$ROLE' non valido in $CONFIG_FILE. Usa 'tx' o 'rx'." >&2
        exit 1
        ;;
esac
