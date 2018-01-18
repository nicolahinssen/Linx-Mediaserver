#!/bin/bash

logfile="/srv/rtorrent/config/rtorrent/log/rtorrent-postprocess.log"
exec > >(tee -a $logfile)
exec 2>&1

(
flock 200

echo "$(date '+%d/%m/%y %H:%M:%S') | manual-postprocess"

SAVEFILE=/srv/rtorrent/config/rtorrent/vars.txt

echo "$1"
echo "$2"
echo "$3"

cd "$1"

if find ./*/ -type d 2>/dev/null; then
  echo "Multiple folders detected."
  for d in */; do
    echo "base_path="\""$1/$d\"" > $SAVEFILE
    echo "name="\""$d\"" >> $SAVEFILE
    echo "custom1="\""$3\"" >> $SAVEFILE

    sed -i 's:/srv/rtorrent/data/:/mnt/nfs/rtorrent/data/:g' $SAVEFILE

    echo "Directory: $d"
    cat $SAVEFILE

    if [[ $1 == *"/data/HardBay"* ]] || [[ $1 == *"/data/Redacted"* ]]; then
      ssh nicola@192.168.178.32 /mnt/nfs/rtorrent/config/rtorrent/postprocess.sh
    fi

    echo "Command executed on remote machine."
  done
else
  echo "base_path="\""$1\"" > $SAVEFILE
  echo "name="\""$2\"" >> $SAVEFILE
  echo "custom1="\""$3\"" >> $SAVEFILE
  
  sed -i 's:/srv/rtorrent/data/:/mnt/nfs/rtorrent/data/:g' $SAVEFILE
  # sed -i 's:%20: :g;s:%2F:/:g;s:%26:&:g'

  cat $SAVEFILE

  if [[ $1 == *"/data/HardBay"* ]] || [[ $1 == *"/data/Redacted"* ]]; then
    ssh nicola@192.168.178.32 /mnt/nfs/rtorrent/config/rtorrent/postprocess.sh
  fi

  echo "Command executed on remote machine."
fi

) 200>/srv/rtorrent/config/rtorrent/postprocess.lock
