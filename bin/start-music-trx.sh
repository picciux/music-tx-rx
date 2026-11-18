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

        if ! /usr/bin/jack_wait -w -t 10; then
            echo "ERRORE: il server JACK non e' partito" >&2
            cleanup
            exit 1
        fi
        if ! /usr/bin/jack_load netmanager; then
            echo "ERRORE: caricamento di netmanager fallito" >&2
            cleanup
            exit 1
        fi

        wait $JACK_PID
        ;;

    rx|RX)
        echo "Avvio nodo in modalita RICEVITORE (Device: $AUDIO_DEVICE, SR: $SAMPLE_RATE, Buf: $BUFFER_SIZE)..."
        /usr/bin/jackd -R -P 70 -d net &
        JACK_PID=$!

        # Il server net (slave) e' utilizzabile solo quando compare il master:
        # attende senza timeout, ma esce se jackd termina.
        until /usr/bin/jack_wait -c -q >/dev/null 2>&1; do
            if ! kill -0 "$JACK_PID" 2>/dev/null; then
                echo "ERRORE: jackd terminato prima di essere pronto" >&2
                exit 1
            fi
            sleep 1
        done

        /usr/bin/alsa_out -d "$AUDIO_DEVICE" -r "$SAMPLE_RATE" -p "$BUFFER_SIZE" -n "$PERIODS" &
        ALSA_PID=$!
        sleep 1

        # Supervisione: ricollega le porte se mancano; se jackd o alsa_out
        # muoiono esce con errore, cosi' systemd riavvia il servizio.
        while kill -0 "$JACK_PID" 2>/dev/null; do
            if ! kill -0 "$ALSA_PID" 2>/dev/null; then
                echo "ERRORE: alsa_out terminato" >&2
                cleanup
                exit 1
            fi
            /usr/bin/jack_connect system:capture_1 alsa_out:playback_1 2>/dev/null
            /usr/bin/jack_connect system:capture_2 alsa_out:playback_2 2>/dev/null
            sleep 3 &
            wait $!
        done
        echo "ERRORE: jackd terminato (master perso?)" >&2
        cleanup
        exit 1
        ;;

    *)
        echo "ERRORE: Valore ROLE='$ROLE' non valido in $CONFIG_FILE. Usa 'tx' o 'rx'." >&2
        exit 1
        ;;
esac
