#! /bin/bash

CF=/etc/default/music-trx

if [ ! -f "$CF" ]; then
    echo "ERRORE: file di configurazione audio non trovato."
    exit 1
fi

set -e

source "$CF"
#T="${CF: -2}"

case $1 in
  rw|enable)
    echo -n "Abilito la scrittura su $CONFIG: "
    sudo mount -o remount,rw $CONFIG
    echo 'fatto.'
    ;;

  ro|disable)
    echo -n "Proteggo $CONFIG in sola lettura: "
    sync
    sudo mount -o remount,ro $CONFIG
    echo 'fatto.'
    ;;

  *)
    echo
    echo "USO: $0 enable|disable"
    echo
    exit 1
    ;;
esac

