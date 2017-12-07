#!/bin/bash

SAVEFILE=/config/rtorrent/vars.txt

## /data/music/Album.Name.2017 (d.get_base_path)
echo "base_path="\""$1\"" > $SAVEFILE

## Album.Name.2017 (d.name)
echo "name="\""$2\"" >> $SAVEFILE

## Genre (d.get_custom1)
echo "custom1="\""$3\"" >> $SAVEFILE

sed -i 's:/data/HardBay:/mnt/nfs/rtorrent/data/HardBay:g' $SAVEFILE

if [[ $1 == *"/data/HardBay"* ]]; then
  ssh nicola@192.168.178.32 /mnt/nfs/rtorrent/config/rtorrent/postprocess.sh
fi
