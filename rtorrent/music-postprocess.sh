#!/bin/bash

################################################################
#                         DEPENDENCIES                         #      
################################################################
#                                                              #
# bpmwrap.sh                                                   #
#   https://github.com/meridius/bpmwrap/blob/master/bpmwrap.sh #
#                                                              #
# beets                                                        #
#   https://github.com/beetbox/beets                           #
#                                                              #
# metaflac (from "flac" package)                               #
#   https://github.com/xiph/flac                               #
#                                                              #
# mid3v2 (from "python-mutagen" package)                       #
#   https://github.com/quodlibet/python-mutagen                #
#                                                              #
################################################################


source /srv/rtorrent/config/rtorrent/vars.txt

#base_path="$1"
#name="$2"
#custom1="$3"

bpmwrap_path="/srv/rtorrent/config/rtorrent"
histfile="/srv/rtorrent/config/rtorrent/history.txt"
masterlog="/srv/linx.log"
temppath="/srv/rtorrent/config/rtorrent/tmp"   

echo "$(date '+%d/%m/%y %H:%M:%S') | Music    | STARTING Processing $name" >> "$masterlog"
printf "#####  Post-Processing started for %s  #####\n\n\n" "$name"

cp -rv "$base_path/" "$temppath"
cd "$temppath/$name" || exit


####### NFO PARSING #######

if ls ./*.nfo >/dev/null 2>&1; then

  ### Publisher ###

  NFO_PUBLISHER=$(cat ./*.nfo | grep -oP -i '(?:label|company).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_PUBLISHER" ]]; then
    NFO_PUBLISHER=$(cat ./*.nfo | grep -oP -i '(?:label|company).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))' | sed 's/ *$//g')
  fi

  ### Album Artist ###

  NFO_ALBUMARTIST=$(cat ./*.nfo | grep -oP -i '(?:artist|artists|performer).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_ALBUMARTIST" ]]; then
    NFO_ALBUMARTIST=$(cat ./*.nfo | grep -oP -i '(?:artist|artists|performer).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))' | sed 's/ *$//g')
  fi

  ### Catalog Number ###

  NFO_CATALOGNUMBER=$(cat ./*.nfo | grep -oP -i '(?:cat|catalog).? ?(?:nr|number|#).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_CATALOGNUMBER" ]]; then
    NFO_CATALOGNUMBER=$(cat ./*.nfo | grep -oP -i '(?:cat|catalog).? ?(?:nr|number|#).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9]+ ?)*))' | sed 's/ *$//g')
  fi
fi


####### MP3 PARSING #######

if ls ./*.mp3 >/dev/null 2>&1; then
  for i in ./*.mp3; do

    printf "PROCESSING MP3 TRACK | %s\n\n" "$i"

    printf "### ORIGINAL TAGS ###\n\n"
    mid3v2 --list "$i"
    printf "\n"
    
    declare -A data=()
    while IFS== read -r key value; do 
      [[ $key ]] && data[$key]=$value
    done < <( mid3v2 --list "$i" | sed 's/=\([[:lower:]]\)/=\u\1/g;s/(\([[:lower:]]\)/(\u\1/g;s/ \([[:lower:]]\)/ \u\1/g;s/Dj/DJ/g' | sed 's/\s+$//' | sed '/TXXX/c\')

    declare -A dataTXXX=()
    while IFS== read -r TXXX key value; do
      [[ $key ]] && data[$key]=$value
    done < <( mid3v2 --list "$i" | sed 's/=\([[:lower:]]\)/=\u\1/g;s/(\([[:lower:]]\)/(\u\1/g;s/ \([[:lower:]]\)/ \u\1/g;s/Dj/DJ/g' | sed 's/\s+$//' | grep 'TXXX' )

    ### Language ###

    data[TLAN]=$(echo "${data[TLAN]}" | tr '[:upper:]' '[:lower:]')

    if [ "${data[TLAN]}" == "english" ]; then
      data[TLAN]="eng"
    fi

    if [ "${data[TLAN]}" == "dutch" ]; then
      data[TLAN]="nld"
    fi

    if [[ -n "${data[TLAN]}" ]]; then
      mid3v2 --TLAN "${data[TLAN]}" "$i"
    fi

    ### Title ###

    if [[ -n "${data[TIT2]}" ]]; then
      mid3v2 --TIT2 "${data[TIT2]}" "$i"
    fi

    ### Track Number ###

    if [[ -n "${data[TRCK]}" ]]; then
      data[TRCK]=$(echo "${data[TRCK]}" | sed 's;^0;;' | sed 's;/0;/;')
      mid3v2 --TRCK "${data[TRCK]}" "$i"
    fi

    ### Disc Number ###

    if [[ -n "${data[TPOS]}" ]]; then
      data[TPOS]=$(echo "${data[TPOS]}" | sed 's;^0;;' | sed 's;/0;/;')
      mid3v2 --TPOS "${data[TPOS]}" "$i"
    fi

    ### Album ###

    if [[ -n "${data[TALB]}" ]]; then
      data[TALB]=$(echo "${data[TALB]}" | sed 's/\sWEB//' | sed 's/\sEP//')
      mid3v2 --TALB "${data[TALB]}" "$i"
    fi

    ### Artist ###

    if [[ "${data[TPE1]}" =~ ^[Vv][^[:alnum:]_]*[Aa][^[:alnum:]_]*(rious)?[^[:alnum:]]*([Aa]rtist(s)?)?[^[:alnum:]_]*$ ]]; then
      data[TPE1]="Various Artists"
    fi

    if [[ -n "${data[TPE1]}" ]]; then
      mid3v2 --TPE1 "${data[TPE1]}" "$i"
    fi

    ### Publisher ###

    if [[ -z "${data[TPUB]}" ]]; then
      data[TPUB]="$NFO_PUBLISHER"
    fi

    if [[ -n "${data[TPUB]}" ]]; then
      mid3v2 --TPUB "${data[TPUB]}" "$i"
    fi

    ### Album Artist ###

    if [[ -z "${data[TPE2]}" ]]; then
      data[TPE2]="$NFO_ALBUMARTIST"
    fi

    if [[ -z "${data[TPE2]}" ]]; then
      data[TPE2]="${data[TPE1]}"
    fi

    if [[ "${data[TPE2]}" =~ ^[Vv][^[:alnum:]_]*[Aa][^[:alnum:]_]*(rious)?[^[:alnum:]]*([Aa]rtist(s)?)?[^[:alnum:]_]*$ ]]; then
      data[TPE2]="Various Artists"
    fi

    if [ "${data[TPE2]}" == "Various Artists" ]; then
      compilation="1"
    fi

    if [[ -n "${data[TPE2]}" ]]; then
      mid3v2 --TPE2 "${data[TPE2]}" "$i"
    fi

    ### Catalog Number ###

    if [[ -z "${dataTXXX[CATALOGNUMBER]}" ]]; then
      if [ "$NFO_CATALOGNUMBER" == "N" ]; then
        NFO_CATALOGNUMBER=""
      else
        dataTXXX[CATALOGNUMBER]="$NFO_CATALOGNUMBER"
      fi
    fi

    if [[ -z "${dataTXXX[CATALOGNUMBER]}" ]]; then
      dataTXXX[CATALOGNUMBER]=$(mid3v2 --list "$i" | grep -oP -i 'TXXX=(?:cat|catalog).? ?(?:nr|number|#)=\K(((?:[a-zA-Z0-9]+ ?)*))(?:\s|$)' | sed 's/ *$//g')
    fi

    if [[ -n "${dataTXXX[CATALOGNUMBER]}" ]]; then
      mid3v2 --TXXX "CATALOGNUMBER:${dataTXXX[CATALOGNUMBER]}" "$i"
    fi

    ### Genre ###

    data[TCON]="$custom1"

    if [[ -n "${data[TCON]}" ]]; then
      mid3v2 --TCON "${data[TCON]}" "$i"
    fi

    ### Beats per minute ###

    if [[ -z "${data[TBPM]}" ]]; then
      if [ "${data[TCON]}" == "Hardstyle" ]; then
        $bpmwrap_path/bpmwrap.sh -v -w -m 130 -x 200 "$i"
      else
        $bpmwrap_path/bpmwrap.sh -v -w -m 80 -x 320 "$i"
      fi
    fi

    printf "### NEW TAGS ###\n\n"

    mid3v2 --list "$i"

    unset data
    unset dataTXXX
  done
fi


####### FLAC PARSING #######

if ls ./*.flac >/dev/null 2>&1; then
  for i in ./*.flac; do
    printf "PROCESSING FLAC TRACK | %s\n\n" "$i"
    printf "### ORIGINAL TAGS ###\n\n"

    metaflac --export-tags-to=- "$i"

    declare -A data=()
    while IFS== read -r key value; do 
      [[ $key ]] && data[$key]=$value
    done < <( metaflac --export-tags-to=- "$i" | sed 's/=\([[:lower:]]\)/=\u\1/g;s/(\([[:lower:]]\)/(\u\1/g;s/ \([[:lower:]]\)/ \u\1/g;s/Dj/DJ/g' | sed 's/\s+$//' )

    ### Title ###

    if [[ -n "${data[TITLE]}" ]]; then
      metaflac --set-tag="TITLE=${data[TITLE]}" "$i"
    fi

    ### Track Number ###

    if [[ -n "${data[TRACKNUMBER]}" ]]; then
      data[TRACKNUMBER]=$(echo "${data[TRACKNUMBER]}" | sed 's/^0//')
    fi

    if [[ -z "${data[TRACKNUMBER]}" ]]; then
      data[TRACKNUMBER]=$(echo "${data[TRACK]}" | sed 's;^0;;')
    fi

    metaflac --remove-tag="TRACK" --set-tag="TRACKNUMBER=${data[TRACKNUMBER]}" "$i"

    ### Total Tracks ###

    if [[ -n "${data[TOTALTRACKS]}" ]]; then
      data[TRACKTOTAL]=$(echo "${data[TOTALTRACKS]}" | sed 's/^0//')
    fi

    if [[ -n "${data[TRACKTOTAL]}" ]]; then
      data[TOTALTRACKS]=$(echo "${data[TRACKTOTAL]}" | sed 's/^0//')
    fi

    metaflac --remove-tag="TRACKC" --set-tag="TOTALTRACKS=${data[TOTALTRACKS]}" --set-tag="TRACKTOTAL=${data[TRACKTOTAL]}" "$i"

    ### Disc Number ###

    if [[ -n "${data[DISCNUMBER]}" ]]; then
      data[DISCNUMBER]=$(echo "${data[DISCNUMBER]}" | sed 's/^0//')
    fi

    if [[ -z "${data[DISCNUMBER]}" ]]; then
      data[DISCNUMBER]=$(echo "${data[DISC]}" | sed 's;^0;;')
    fi

    metaflac --remove-tag="DISC" --set-tag="DISCNUMBER=${data[DISCNUMBER]}" "$i"

    ### Total Discs ###

    if [[ -n "${data[TOTALDISCS]}" ]]; then
      data[DISCTOTAL]=$(echo "${data[TOTALDISCS]}" | sed 's/^0//')
    fi

    if [[ -n "${data[DISCTOTAL]}" ]]; then
      data[TOTALDISCS]=$(echo "${data[DISCTOTAL]}" | sed 's/^0//')
    fi

    metaflac --set-tag="TOTALDISCS=${data[TOTALDISCS]}" --set-tag="DISCTOTAL=${data[DISCTOTAL]}" "$i"
  
    ### Album ###

    if [[ -n "${data[ALBUM]}" ]]
      data[ALBUM]="$(echo ${data[ALBUM]} | sed 's/\sWEB//' | sed 's/\sEP//')"
      metaflac --set-tag="ALBUM=${data[ALBUM]}" "$i"
    fi

    ### Artist ###

    if [[ "${data[ARTIST]}" =~ ^[Vv][^[:alnum:]_]*[Aa][^[:alnum:]_]*(rious)?[^[:alnum:]]*([Aa]rtist(s)?)?[^[:alnum:]_]*$ ]]; then
      data[ARTIST]="Various Artists"
    fi

    if [[ -n "${data[ARTIST]}" ]]; then
      metaflac --set-tag="ARTIST=${data[ARTIST]}" "$i"
    fi

    ### Publisher ###

    if [[ -z "${data[PUBLISHER]}" ]]; then
      data[PUBLISHER]="$NFO_PUBLISHER"
    fi

    if [[ -n "${data[PUBLISHER]}" ]]; then
      metaflac --set-tag="PUBLISHER=${data[PUBLISHER]}" "$i"
    fi

    ### Album Artist ###

    if [[ -z "${data[ALBUMARTIST]}" ]]; then
      data[ALBUMARTIST]="$NFO_ALBUMARTIST"
    fi

    if [[ -z "${data[ALBUMARTIST]}" ]]; then
      data[ALBUMARTIST]="${data[ALBUM ARTIST]}"
    fi

    if [[ -z "${data[ALBUMARTIST]}" ]]; then
      data[ALBUMARTIST]="${data[ARTIST]}"
    fi

    if [[ "${data[ALBUMARTIST]}" =~ ^[Vv][^[:alnum:]_]*[Aa][^[:alnum:]_]*(rious)?[^[:alnum:]]*([Aa]rtist(s)?)?[^[:alnum:]_]*$ ]]; then
      data[ALBUMARTIST]="Various Artists"
    fi

    if [ "${data[ALBUMARTIST]}" == "Various Artists" ]; then
      data[COMPILATION]="1"
      compilation="1"
    fi

    if [[ -n "${data[ALBUMARTIST]}" ]]; then
      metaflac --remove-tag="ALBUM ARTIST" --set-tag="ALBUMARTIST=${data[ALBUMARTIST]}" "$i"
    fi

    ### Catalog Number ###

    if [[ -z "${data[CATALOGNUMBER]}" ]]; then
      if [ "$NFO_CATALOGNUMBER" == "N" ]; then
        NFO_CATALOGNUMBER=""
      else
        data[CATALOGNUMBER]="$NFO_CATALOGNUMBER"
      fi
    fi

    if [[ -z "${data[CATALOGNUMBER]}" ]]; then
      data[CATALOGNUMBER]=$(metaflac --export-tags-to=- "$i" | grep -oP -i '(?:cat|catalog).? ?(?:nr|number|#)=\K(((?:[a-zA-Z0-9]+ ?)*))(?:\s|$)' | sed 's/ *$//g')
    fi

    if [[ -n "${data[CATALOGNUMBER]}" ]]; then
      metaflac --set-tag="CATALOGNUMBER=${data[CATALOGNUMBER]}" "$i"
    fi

    ### Genre ###

    data[GENRE]="$custom1"

    if [[ -n "${data[GENRE]}" ]]; then
      metaflac --set-tag="GENRE=${data[GENRE]}" "$i"
    fi

    ### Beats per minute ###

    if [[ -z "${data[BPM]}" ]]; then
      if [ "${data[GENRE]}" == "Hardstyle" ]; then
        $bpmwrap_path/bpmwrap.sh -v -t flac -w -m 130 -x 200 "$i"
      else
        $bpmwrap_path/bpmwrap.sh -v -t flac -w -m 80 -x 320 "$i"
      fi
    fi

    printf "### NEW TAGS ###\n\n"

    metaflac --export-tags-to=- "$i"

    unset data
  done
fi

### Beets Import ###

if [ "$compilation" == "1" ]; then
  beet -v import -q --set comp="True" "$temppath/$name"
else
  beet -v import -q "$temppath/$name"
fi

rm -r "$temppath/$name"

echo "## $name ##"
echo ""
echo "-------------------------------"
echo "||   Processing completed!   ||"
echo "-------------------------------"

echo "$(date '+%d/%m/%y %H:%M:%S') | $name" >> "$histfile"
echo "$(date '+%d/%m/%y %H:%M:%S') | Music    | COMPLETED Processing $name" >> "$masterlog"
