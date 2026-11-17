#! /bin/bash

CF=/etc/default/music-trx

if [ ! -f "$CF" ]; then
    echo "ERROR: no audio config file found."
    exit 1
fi

set -e

source "$CF"
#T="${CF: -2}"

case $1 in
  rw|enable)
    echo -n "Enable $CONFIG for write: "
    sudo mount -o remount,rw $CONFIG
    echo 'done.'
    ;;

  ro|disable)
    echo -n "Protect $CONFIG read-only: "
    sync
    sudo mount -o remount,ro $CONFIG
    echo 'done.'
    ;;

  *)
    echo
    echo "USAGE: $0 enable|disable"
    echo
    exit 1
    ;;
esac

