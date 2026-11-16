#! /bin/bash

set -e

CF="$( ls /etc/default/audio-?x )"

if [ ! -f $CF ]; then
    echo "ERROR: no audio config file found."
    exit 1
fi

source $CF
#T="${CF: -2}"

case $1 in
  rw)
    echo -n "Enable $CONFIG for write: "
    sudo mount -o remount,rw $CONFIG
    echo 'done.'
    ;;

  ro)
    echo -n "Protect $CONFIG read-only: "
    sync
    sudo mount -o remount,ro $CONFIG
    echo 'done.'
    ;;

  *)
    echo "USAGE: $0 rw|ro"
    exit 1
    ;;
esac

