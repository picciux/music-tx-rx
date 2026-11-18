#!/bin/bash

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SERVICE="music-trx.service"
CONFIG_FILE="/etc/default/music-trx"

# Legge il ruolo dal file di configurazione
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

case "$ROLE" in
    tx|TX) ROLE_LABEL="TRASMETTITORE (Master)" ;;
    rx|RX) ROLE_LABEL="RICEVITORE (Slave)" ;;
    *)     ROLE_LABEL="NON CONFIGURATO ($ROLE)" ;;
esac

echo -e "${CYAN}==================================================${NC}"
echo -e "${CYAN}           MUSIC-TRX - STATO AUDIO                  ${NC}"
echo -e "${CYAN}==================================================${NC}"
echo -e "Ruolo Nodo    : ${YELLOW}$ROLE_LABEL${NC}"
echo -e "Device ALSA   : $AUDIO_DEVICE"

if systemctl is-active --quiet "$SERVICE"; then
    echo -e "Servizio      : ${GREEN}ATTIVO ($SERVICE)${NC}"
else
    echo -e "Servizio      : ${RED}FERMO / ERRORE ($SERVICE)${NC}"
fi

TEMP=$(vcgencmd measure_temp 2>/dev/null | cut -d'=' -f2)
TEMP=${TEMP:-N/D}
GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/D")
OVERLAY=$(mount | grep -q "overlayroot\|lowerdir=" && echo "${GREEN}ATTIVO (Read-Only)${NC}" || echo "${YELLOW}DISATTIVO (Read-Write)${NC}")
CFG=${CONFIG:-/mnt/config}
if ! mountpoint -q "$CFG" 2>/dev/null; then
    CFG_PART="${YELLOW}NON MONTATA ($CFG)${NC}"
elif findmnt -no OPTIONS "$CFG" | grep -qw ro; then
    CFG_PART="${GREEN}PROTETTA (Read-Only)${NC}"
else
    CFG_PART="${RED}SBLOCCATA (Read-Write)${NC}"
fi

echo -e "Temperatura   : $TEMP"
echo -e "CPU Governor  : $GOV"
echo -e "Overlay FS    : $OVERLAY"
echo -e "Part. Config  : $CFG_PART"
echo -e "${CYAN}--------------------------------------------------${NC}"

if pgrep -x "jackd" > /dev/null; then
    SR=$(jack_samplerate 2>/dev/null)
    BUF=$(jack_bufsize 2>/dev/null)

    if [ -n "$SR" ] && [ -n "$BUF" ] && [ "$SR" -gt 0 ]; then
        LAT_MS=$(awk "BEGIN {printf \"%.2f\", ($BUF / $SR) * 1000}")
        echo -e "Sample Rate   : ${GREEN}${SR} Hz${NC}"
        echo -e "Buffer Size   : ${GREEN}${BUF} frames${NC} (~${LAT_MS} ms per ciclo)"
    fi

    echo -e "\n${CYAN}Porte e Connessioni Attive:${NC}"
    jack_lsp -c 2>/dev/null | grep -E "capture|playback|net" -A 1 | sed 's/^/  /'
else
    echo -e "${RED}Server JACK non in esecuzione!${NC}"
fi

JLOG=$(journalctl -u "$SERVICE" -b --no-pager 2>/dev/null)
echo -e "\n${CYAN}--------------------------------------------------${NC}"
if [ -z "$JLOG" ]; then
    echo -e "Errori / XRUN : ${YELLOW}N/D (journal non leggibile: aggiungi l'utente al gruppo systemd-journal)${NC}"
else
    XRUNS=$(grep -icE "xrun|Process error|delay of" <<< "$JLOG")
    if [ "$XRUNS" -eq 0 ]; then
        echo -e "Errori / XRUN : ${GREEN}0 (Flusso perfetto)${NC}"
    else
        echo -e "Errori / XRUN : ${RED}$XRUNS rilevati dall'avvio${NC}"
    fi
fi
echo -e "${CYAN}==================================================${NC}"
