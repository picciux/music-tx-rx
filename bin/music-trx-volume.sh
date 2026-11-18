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
        echo "Run '$0 save' to persist volume level across reboots."
        ;;

    save)
        sudo alsactl store && echo "Volume saved!"
        ;;

    *)
        echo
        echo "USAGE: $0 set|save"
        echo
        exit 1
        ;;
esac

echo

