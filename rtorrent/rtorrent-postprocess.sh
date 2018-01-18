#!/bin/bash

savefile="/config/rtorrent/vars.txt"
logfile="/config/rtorrent/log/rtorrent-postprocess.log"
exec > >(tee -a $logfile)
exec 2>&1

(
flock 200

echo "$(date '+%d/%m/%y %H:%M:%S') | rtorrent-postprocess"

cd "$1"

if find ./*/ -type d 2>/dev/null; then
  echo "Multiple folders detected."
  for d in */; do
    echo "base_path="\""$1/$d\"" > $savefile
    echo "name="\""$d\"" >> $savefile
    echo "custom1="\""$3\"" >> $savefile

    sed -i 's:/data/:/mnt/nfs/rtorrent/data/:g' $savefile

    echo "Directory: $d"
    cat $savefile

    if [[ $1 == *"/data/HardBay"* ]] || [[ $1 == *"/data/Redacted"* ]]; then
      ssh nicola@192.168.178.32 /mnt/nfs/rtorrent/config/rtorrent/postprocess.sh
    fi

    echo "Command executed on remote machine."
  done
else
  echo "base_path="\""$1\"" > $savefile
  echo "name="\""$2\"" >> $savefile
  echo "custom1="\""$3\"" >> $savefile
  
  sed -i 's:/data/:/mnt/nfs/rtorrent/data/:g' $savefile
  # sed -i 's:%20: :g;s:%2F:/:g;s:%26:&:g'

  cat $savefile

  if [[ $1 == *"/data/HardBay"* ]] || [[ $1 == *"/data/Redacted"* ]]; then
    ssh nicola@192.168.178.32 /mnt/nfs/rtorrent/config/rtorrent/postprocess.sh
  fi

  echo "Command executed on remote machine."
fi

) 200>/config/rtorrent/postprocess.lock