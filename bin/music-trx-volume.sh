#! /bin/bash

CF=/etc/default/music-trx
[ -f "$CF" ] && source "$CF"

case $1 in
    set)
        # Apre il mixer della scheda configurata, non quella di default
        if [ -n "$AUDIO_DEVICE" ]; then
            alsamixer -D "$AUDIO_DEVICE"
        else
            alsamixer
        fi
        echo "Esegui '$0 save' per mantenere il volume anche dopo il riavvio."
        ;;

    save)
        sudo alsactl store && echo "Volume salvato!"
        ;;

    *)
        echo
        echo "USO: $0 set|save"
        echo
        exit 1
        ;;
esac

echo

