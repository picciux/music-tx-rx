#! /bin/bash

[ "$1" = "set" ] || [ "$1" = "save" ] || { echo "USAGE: $0 set|save"; exit 1; }

[ "$1" = "set" ] && { alsamixer; echo "Run '$0 save' to persist volume level across reboots."; }
[ "$1" = "save" ] && sudo alsactl store $$ echo "Volume saved"

echo

