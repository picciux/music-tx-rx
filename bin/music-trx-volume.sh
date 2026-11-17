#! /bin/bash

case $1 in
    set)
        alsamixer
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

