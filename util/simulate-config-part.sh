#! /bin/bash

set -e

[ "$1" ] && [ "$2" ]

PARTFILE=$1
DESTDIR=$2

sudo dd if=/dev/zero of=$PARTFILE bs=1M count=10
sudo mkfs.ext4 -F $PARTFILE

mkdir -p $DESTDIR

# Associa il file immagine a un loop device libero (di default in lettura/scrittura)
LOPPDEV=$( sudo losetup -f --show $PARTFILE )
# (Supponiamo che ti risponda /dev/loop0)

# Ora monta il device /dev/loop0 specificando 'ro' solo a livello di filesystem
sudo mount -o ro /dev/loop0 $DESTDIR

#/boot/firmware/config_test.img  /mnt/config  ext4  loop,ro,noatime,nofail  0  0
