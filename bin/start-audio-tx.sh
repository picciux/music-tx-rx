#!/bin/bash

# Carica le impostazioni (con valori di fallback di sicurezza)
CONFIG_FILE="/etc/default/audio-tx"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

AUDIO_DEVICE=${AUDIO_DEVICE:-"hw:CODEC"}
SAMPLE_RATE=${SAMPLE_RATE:-48000}
BUFFER_SIZE=${BUFFER_SIZE:-128}
PERIODS=${PERIODS:-2}

# Avvia JACK sulla scheda USB in background
/usr/bin/jackd -R -P 70 -d alsa -d "$AUDIO_DEVICE" -r "$SAMPLE_RATE" -p "$BUFFER_SIZE" -n "$PERIODS" -i 2 -o 0 &
JACK_PID=$!

# Aspetta che il server JACK sia pronto e attiva la trasmissione di rete
sleep 2
/usr/bin/jack_load netmanager

# Mantieni lo script attivo finché JACK è in esecuzione
wait $JACK_PID
