#!/bin/bash

# $1 = Full Path
# $2 = Genre

logfile="/srv/rtorrent/config/rtorrent/log/rtorrent-postprocess.log"
exec > >(tee -a $logfile)
exec 2>&1

echo "$(date '+%d/%m/%y %H:%M:%S') | manual-postprocess"

SAVEFILE=/srv/rtorrent/config/rtorrent/vars.txt

base_path="$1"
name=$(basename "$base_path")
custom1="$2"

cd "$base_path"

if find ./*/ -type d 2>/dev/null && [ -z "$(find . -maxdepth 1 -type d -iname 'disc*' -or -iname 'cd*' | head -1)" ]; then
  echo "Multiple folders detected."

  for d in */; do
    echo "base_path="\""$base_path/$d\"" > $SAVEFILE
    echo "name="\""$d\"" >> $SAVEFILE
    echo "custom1="\""$custom1\"" >> $SAVEFILE

    echo "Directory: $d"
    cat $SAVEFILE

    /srv/rtorrent/config/rtorrent/music-postprocess.sh
  done

else
  echo "base_path="\""$base_path\"" > $SAVEFILE
  echo "name="\""$name\"" >> $SAVEFILE
  echo "custom1="\""$custom1\"" >> $SAVEFILE

  cat $SAVEFILE

  /srv/rtorrent/config/rtorrent/music-postprocess.sh
fi
