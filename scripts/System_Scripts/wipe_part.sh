#!/bin/bash
DEVICE="/dev/sdc1" #actually partition not DEVICE

if [[ $EUID -ne 0 ]]; then
  # root check
  echo "Wipe-Prozess erfordert Root-Privilegien." 1>&2
  exit 1
fi

read -p "Are you sure to wipe the elasticsearch data on partition $DEVICE? Press [y] to continue." -n 1 -r
echo

if [[ $REPLY =~ ^[Yy]$ ]]
#sanity check
then

    PASS=$(tr -cd '[:alnum:]' < /dev/urandom | head -c128)
    # generate random key
    openssl enc -aes-256-ctr -pass pass:"$PASS" -nosalt </dev/zero | dd bs=64K ibs=64K of=$DEVICE status=progress
    # fill data with encrypted zeros under rnadom key which is random data

    echo "Done wiping the partition.. Reinitializing file system.."
    mkfs.ext4 $DEVICE
    mount -a
    mkdir -p /data/elasticsearch
    chown -R elasticsearch:elasticsearch /data/elasticsearch
    echo "Done."
    exit 0
fi
exit 1
