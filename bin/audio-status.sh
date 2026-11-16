#!/bin/bash

# Colori per la lettura rapida
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}        JACK AUDIO STREAMING - STATUS             ${NC}"
echo -e "${CYAN}==================================================${NC}"

# 1. Rileva automaticamente se questo Pi è TX o RX
if systemctl is-enabled --quiet audio-tx.service 2>/dev/null; then
    SERVICE="audio-tx.service"
    ROLE="TRASMETTITORE (Master)"
elif systemctl is-enabled --quiet audio-rx.service 2>/dev/null; then
    SERVICE="audio-rx.service"
    ROLE="RICEVITORE (Slave)"
else
    SERVICE="Nessuno"
    ROLE="Non configurato"
fi

echo -e "Ruolo Nodo    : ${YELLOW}$ROLE${NC}"

# 2. Stato Servizio Systemd
if systemctl is-active --quiet "$SERVICE"; then
    echo -e "Servizio      : ${GREEN}ATTIVO ($SERVICE)${NC}"
else
    echo -e "Servizio      : ${RED}FERMO / ERRORE ($SERVICE)${NC}"
fi

# 3. Parametri Hardware & Sistema
TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2 || echo "N/D")
GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/D")
OVERLAY=$(mount | grep -q "overlayroot\|lowerdir=" && echo "${GREEN}ATTIVO (Read-Only)${NC}" || echo "${YELLOW}DISATTIVO (Read-Write)${NC}")

echo -e "Temperatura   : $TEMP"
echo -e "CPU Governor  : $GOV"
echo -e "Overlay FS    : $OVERLAY"

echo -e "${CYAN}--------------------------------------------------${NC}"

# 4. Parametri Audio Reali (interroga il server JACK attivo)
if pgrep -x "jackd" > /dev/null; then
    SR=$(jack_samplerate 2>/dev/null)
    BUF=$(jack_bufsize 2>/dev/null)

    # Calcola la latenza base di un singolo ciclo buffer in ms
    if [ -n "$SR" ] && [ -n "$BUF" ] && [ "$SR" -gt 0 ]; then
        LAT_MS=$(awk "BEGIN {printf \"%.2f\", ($BUF / $SR) * 1000}")
        echo -e "Sample Rate   : ${GREEN}${SR} Hz${NC}"
        echo -e "Buffer Size   : ${GREEN}${BUF} frames${NC} (~${LAT_MS} ms per ciclo)"
    fi

    # 5. Verifica connessioni attive
    echo -e "\n${CYAN}Porte e Connessioni Attive:${NC}"
    jack_lsp -c 2>/dev/null | grep -E "capture|playback|net" -A 1 | sed 's/^/  /'
else
    echo -e "${RED}Server JACK non in esecuzione!${NC}"
fi

# 6. Conteggio XRUN nei log dall'ultimo avvio
XRUNS=$(journalctl -u "$SERVICE" -b --no-pager 2>/dev/null | grep -icE "xrun|Process error|delay of")
echo -e "\n${CYAN}--------------------------------------------------${NC}"
if [ "$XRUNS" -eq 0 ]; then
    echo -e "Errori / XRUN : ${GREEN}0 (Flusso perfetto)${NC}"
else
    echo -e "Errori / XRUN : ${RED}$XRUNS rilevati dall'avvio${NC}"
fi
echo -e "${CYAN}==================================================${NC}"
