#!/bin/bash

# Carica le impostazioni (con valori di fallback di sicurezza se mancano)
CONFIG_FILE="/etc/default/audio-rx"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

AUDIO_DEVICE=${AUDIO_DEVICE:-"hw:Headphones"}
SAMPLE_RATE=${SAMPLE_RATE:-48000}
BUFFER_SIZE=${BUFFER_SIZE:-256}
PERIODS=${PERIODS:-2}

# Avvia JACK in modalità ricezione rete
/usr/bin/jackd -R -P 70 -d net &
JACK_PID=$!

sleep 2

# Avvia alsa_out usando le variabili configurate
/usr/bin/alsa_out -d "$AUDIO_DEVICE" -r "$SAMPLE_RATE" -p "$BUFFER_SIZE" -n "$PERIODS" &
ALSA_PID=$!

sleep 2
/usr/bin/jack_connect system:capture_1 alsa_out:playback_1
/usr/bin/jack_connect system:capture_2 alsa_out:playback_2

wait $JACK_PID
