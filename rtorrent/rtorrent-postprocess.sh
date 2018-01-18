#!/bin/bash

logfile="/config/rtorrent/log/rtorrent-postprocess.log"
exec > >(tee -a $logfile)
exec 2>&1

(
flock 200

echo "$(date '+%d/%m/%y %H:%M:%S') | rtorrent-postprocess"

SAVEFILE=/config/rtorrent/vars.txt

cd "$1"

if find ./*/ -type d 2>/dev/null; then
  echo "Multiple folders detected."
  for d in */; do
    echo "base_path="\""$1/$d\"" > $SAVEFILE
    echo "name="\""$d\"" >> $SAVEFILE
    echo "custom1="\""$3\"" >> $SAVEFILE

    sed -i 's:/data/:/srv/rtorrent/data/:g' $SAVEFILE
    sed -i 's:%20: :g;s:%2F:/:g;s:%26:&:g' $SAVEFILE

    echo "Directory: $d"
    cat $SAVEFILE

    if [[ $1 == *"/data/HardBay"* ]] || [[ $1 == *"/data/Redacted"* ]]; then
      ssh nicola@192.168.178.13 /srv/rtorrent/config/rtorrent/music-postprocess.sh
    fi
  done
else
  echo "base_path="\""$1\"" > $SAVEFILE
  echo "name="\""$2\"" >> $SAVEFILE
  echo "custom1="\""$3\"" >> $SAVEFILE
  
  sed -i 's:/data/:/srv/rtorrent/data/:g' $SAVEFILE
  sed -i 's:%20: :g;s:%2F:/:g;s:%26:&:g' $SAVEFILE

  cat $SAVEFILE

  if [[ $1 == *"/data/HardBay"* ]] || [[ $1 == *"/data/Redacted"* ]]; then
    ssh nicola@192.168.178.13 /srv/rtorrent/config/rtorrent/music-postprocess.sh
  fi
fi

) 200>/config/rtorrent/postprocess.lock
