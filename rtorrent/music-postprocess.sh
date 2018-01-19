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

temppath="/srv/rtorrent/config/rtorrent/tmp"
histfile="/srv/rtorrent/config/rtorrent/history.txt"
masterlog="/srv/linx.log"

echo "$(date '+%d/%m/%y %H:%M:%S') | Music    | STARTING Processing $name" >> "$masterlog"

echo ""
echo ""
echo "#####  Post-Processing started for $name  #####"

cp -rv "$base_path/" "$temppath"/
cd "$temppath/$name" || exit


###################################################################################
#                                   NFO PARSING                                   #
###################################################################################

if ls ./*.nfo >/dev/null 2>&1; then

  sed -i 's; N/A;;g' ./*.nfo
  sed -i 's/ None$//g' ./*.nfo

  ### Album ###

  NFO_PUBLISHER=$(cat ./*.nfo | grep -oP -i '(?:album|title).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_PUBLISHER" ]]; then
    NFO_PUBLISHER=$(cat ./*.nfo | grep -oP -i '(?:album|title).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))' | sed 's/ *$//g')
  fi

  ### Publisher ###

  NFO_PUBLISHER=$(cat ./*.nfo | grep -oP -i '(?:label|company|publisher).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_PUBLISHER" ]]; then
    NFO_PUBLISHER=$(cat ./*.nfo | grep -oP -i '(?:label|company|publisher).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))' | sed 's/ *$//g')
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

  ### Track Total ###

  NFO_TRACKTOTAL=$(cat ./*.nfo | grep -oP -i '(?:tracks|trackcount).*(?:\:|\[|\]|\=|\-)[\s]* 0?\K(((?:[0-9]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_TRACKTOTAL" ]]; then
    NFO_TRACKTOTAL=$(cat ./*.nfo | grep -oP -i '(?:tracks|trackcount).*(?:\:|\[|\]|\=|\-)[\s]* 0?\K(((?:[0-9]+ ?)*))' | sed 's/ *$//g')
  fi

  ### Year ###

  NFO_YEAR=$(cat ./*.nfo | grep -oP -i '(?:date|year).*(?:\:|\[|\]|\=|\-)[\s]* .*(?=[0-9]{4})\K([1-2][0-9]{3})' | sed 's/ *$//g')

fi


###################################################################################
#                                   MP3 PARSING                                   #
###################################################################################

if ls ./*.mp3 >/dev/null 2>&1; then
  for i in ./*.mp3; do
    echo ""
    echo "PROCESSING MP3 TRACK | $i"
    echo ""
    echo "### ORIGINAL TAGS ###"
    echo ""
    mid3v2 --list "$i"
    echo ""

    ############ FILENAME PARSING ############

    ### Track Number ###

    MP3_FILENAME_TRACKNUMBER=$(echo "$i" | sed 's;\./;;' | sed 's/-/_/g' | sed 's/^0//g' | cut -d_ -f1)

    ### Artist ###

    filename_artist_tmp=$(echo "$i" | sed 's;\./;;' | sed 's/_-_/=/g' | sed 's/-/_/g' | sed 's/[[:digit:]]\+_//g' | cut -d= -f1)
    MP3_FILENAME_ARTIST=$(echo "$filename_artist_tmp" | sed 's/_/ /g' | sed 's/^\([[:lower:]]\)/\u\1/g;s/(\([[:lower:]]\)/(\u\1/g;s/ \([[:lower:]]\)/ \u\1/g;s/Dj/DJ/g' | sed 's/\s+$//g')

    ### Title ###

    filename_title_tmp=$(echo "$i" | sed 's;\./;;' | sed 's/_-_/=/g' | sed 's/-/_/g' | sed 's/[[:digit:]]\+_//g' | cut -d= -f2)
    MP3_FILENAME_TITLE=$(echo "$filename_title_tmp" | sed 's/_/ /g' | sed 's/^\([[:lower:]]\)/\u\1/g;s/(\([[:lower:]]\)/(\u\1/g;s/ \([[:lower:]]\)/ \u\1/g;s/Dj/DJ/g' | sed 's/\s+$//g;s/.mp3//')


    ############ WRITING TAGS ############

    declare -A mp3_tag=()
    while IFS== read -r key value; do 
      [[ $key ]] && mp3_tag[$key]=$value
    done < <( mid3v2 --list "$i" | sed 's/=\([[:lower:]]\)/=\u\1/g;s/(\([[:lower:]]\)/(\u\1/g;s/ \([[:lower:]]\)/ \u\1/g;s/Dj/DJ/g' | sed 's/\s+$//' | sed '/TXXX/c\')

    declare -A mp3_tag_TXXX=()
    while IFS== read -r TXXX key value; do
      [[ $key ]] && mp3_tag[$key]=$value
    done < <( mid3v2 --list "$i" | sed 's/=\([[:lower:]]\)/=\u\1/g;s/(\([[:lower:]]\)/(\u\1/g;s/ \([[:lower:]]\)/ \u\1/g;s/Dj/DJ/g' | sed 's/\s+$//' | grep 'TXXX' )

    ### Language ###

    mp3_tag[TLAN]=$(echo "${mp3_tag[TLAN]}" | tr '[:upper:]' '[:lower:]')

    if [ "${mp3_tag[TLAN]}" == "english" ]; then
      mp3_tag[TLAN]="eng"
    fi

    if [ "${mp3_tag[TLAN]}" == "dutch" ]; then
      mp3_tag[TLAN]="nld"
    fi

    if [[ -n "${mp3_tag[TLAN]}" ]]; then
      mid3v2 --TLAN "${mp3_tag[TLAN]}" "$i"
    fi

    ### Title ###

    if [[ -z "${mp3_tag[TIT2]}" ]]; then
      mp3_tag[TIT2]="$MP3_FILENAME_TITLE"
    fi

    if [[ -n "${mp3_tag[TIT2]}" ]]; then
      mid3v2 --TIT2 "${mp3_tag[TIT2]}" "$i"
    fi

    ### Artist ###

    if [[ -z "${mp3_tag[TPE1]}" ]]; then
      mp3_tag[TPE1]="$MP3_FILENAME_ARTIST"
    fi

    if [[ "${mp3_tag[TPE1]}" =~ ^[Vv][^[:alnum:]_]*[Aa][^[:alnum:]_]*(rious)?[^[:alnum:]]*([Aa]rtist(s)?)?[^[:alnum:]_]*$ ]]; then
      mp3_tag[TPE1]="Various Artists"
    fi

    if [[ -n "${mp3_tag[TPE1]}" ]]; then
      mid3v2 --TPE1 "${mp3_tag[TPE1]}" "$i"
    fi

    ### Album ###

    if [[ -n "${mp3_tag[TALB]}" ]]; then
      mp3_tag[TALB]=$(echo "${mp3_tag[TALB]}" | sed 's/\sWEB//' | sed 's/\sEP//')
      mid3v2 --TALB "${mp3_tag[TALB]}" "$i"
    fi

    ### Track Number ###

    if [[ -z "${mp3_tag[TRCK]}" ]]; then
      mp3_tag[TRCK]="$MP3_FILENAME_TRACKNUMBER"
    fi

    if [[ -n "${mp3_tag[TRCK]}" ]]; then
      mp3_tag[TRCK]=$(echo "${mp3_tag[TRCK]}" | sed 's;^0;;' | sed 's;/0;/;')
      mid3v2 --TRCK "${mp3_tag[TRCK]}" "$i"
    fi

    ### Track Total ###

    if [[ -n "${mp3_tag[TRCK]}" && -n "$NFO_TRACKTOTAL" ]]; then
      if [[ "${mp3_tag[TRCK]}" != */* ]]; then
        mp3_tag[TRCK]="${mp3_tag[TRCK]}/$NFO_TRACKTOTAL"
        mid3v2 --TRCK "${mp3_tag[TRCK]}" "$i"
      fi
    fi

    ### Disc Number ###

    if [[ -n "${mp3_tag[TPOS]}" ]]; then
      mp3_tag[TPOS]=$(echo "${mp3_tag[TPOS]}" | sed 's;^0;;' | sed 's;/0;/;')
      mid3v2 --TPOS "${mp3_tag[TPOS]}" "$i"
    fi

    ### Publisher ###

    if [[ -z "${mp3_tag[TPUB]}" ]]; then
      mp3_tag[TPUB]="$NFO_PUBLISHER"
    fi

    if [[ -n "${mp3_tag[TPUB]}" ]]; then
      mid3v2 --TPUB "${mp3_tag[TPUB]}" "$i"
    fi

    ### Album Artist ###

    if [[ -z "${mp3_tag[TPE2]}" ]]; then
      mp3_tag[TPE2]="$NFO_ALBUMARTIST"
    fi

    if [[ -z "${mp3_tag[TPE2]}" ]]; then
      mp3_tag[TPE2]="${mp3_tag[TPE1]}"
    fi

    if [[ "${mp3_tag[TPE2]}" =~ ^[Vv][^[:alnum:]_]*[Aa][^[:alnum:]_]*(rious)?[^[:alnum:]]*([Aa]rtist(s)?)?[^[:alnum:]_]*$ ]]; then
      mp3_tag[TPE2]="Various Artists"
    fi

    if [ "${mp3_tag[TPE2]}" == "Various Artists" ]; then
      compilation="1"
    fi

    if [[ -n "${mp3_tag[TPE2]}" ]]; then
      mid3v2 --TPE2 "${mp3_tag[TPE2]}" "$i"
    fi

    ### Catalog Number ###

    if [[ -z "${mp3_tag_TXXX[CATALOGNUMBER]}" ]]; then
      mp3_tag_TXXX[CATALOGNUMBER]="$NFO_CATALOGNUMBER"
    fi

    if [[ -z "${mp3_tag_TXXX[CATALOGNUMBER]}" ]]; then
      mp3_tag_TXXX[CATALOGNUMBER]=$(mid3v2 --list "$i" | grep -oP -i 'TXXX=(?:cat|catalog).? ?(?:nr|number|#)=\K(((?:[a-zA-Z0-9]+ ?)*))(?:\s|$)' | sed 's/ *$//g')
    fi

    if [[ -n "${mp3_tag_TXXX[CATALOGNUMBER]}" ]]; then
      mid3v2 --TXXX "CATALOGNUMBER:${mp3_tag_TXXX[CATALOGNUMBER]}" "$i"
    fi

    ### Genre ###

    mp3_tag[TCON]="$custom1"

    if [[ -n "${mp3_tag[TCON]}" ]]; then
      mid3v2 --TCON "${mp3_tag[TCON]}" "$i"
    fi

    ### Date ###

    if [[ -z "${mp3_tag[TDRC]}" ]]; then
      mp3_tag[TDRC]="$NFO_YEAR"
      mid3v2 --TDRC "${mp3_tag[TDRC]}" "$i"
    fi

    ### Beats per minute ###

    if [[ -z "${mp3_tag[TBPM]}" ]]; then
      if [ "${mp3_tag[TCON]}" == "Hardstyle" ]; then
        /srv/rtorrent/config/rtorrent/bpmwrap.sh -v -w -m 130 -x 200 "$i"
      else
        /srv/rtorrent/config/rtorrent/bpmwrap.sh -v -w -m 80 -x 320 "$i"
      fi
    fi

    echo ""
    echo "### NEW  TAGS ###"
    echo ""
    mid3v2 --list "$i"

    unset mp3_tag
    unset mp3_tag_TXXX
  done
fi


###################################################################################
#                                  FLAC PARSING                                   #
###################################################################################

if ls ./*.flac >/dev/null 2>&1; then
  for i in ./*.flac; do
    echo ""
    echo "PROCESSING MP3 TRACK | $i"
    echo ""
    echo "### ORIGINAL TAGS ###"
    echo ""
    metaflac --export-tags-to=- "$i"
    echo ""


    ############ FILENAME PARSING ############

    ### Track Number ###

    FLAC_FILENAME_TRACKNUMBER=$(echo "$i" | sed 's;\./;;' | sed 's/-/_/g' | sed 's/^0//g' | cut -d_ -f1)

    ### Artist ###

    filename_artist_tmp=$(echo "$i" | sed 's;\./;;' | sed 's/_-_/=/g' | sed 's/-/_/g' | sed 's/[[:digit:]]\+_//g' | cut -d= -f1)
    FLAC_FILENAME_ARTIST=$(echo "$filename_artist_tmp" | sed 's/_/ /g' | sed 's/^\([[:lower:]]\)/\u\1/g;s/(\([[:lower:]]\)/(\u\1/g;s/ \([[:lower:]]\)/ \u\1/g;s/Dj/DJ/g' | sed 's/\s+$//g')

    ### Title ###

    filename_title_tmp=$(echo "$i" | sed 's;\./;;' | sed 's/_-_/=/g' | sed 's/-/_/g' | sed 's/[[:digit:]]\+_//g' | cut -d= -f2)
    FLAC_FILENAME_TITLE=$(echo "$filename_title_tmp" | sed 's/_/ /g' | sed 's/^\([[:lower:]]\)/\u\1/g;s/(\([[:lower:]]\)/(\u\1/g;s/ \([[:lower:]]\)/ \u\1/g;s/Dj/DJ/g' | sed 's/\s+$//g;s/.flac//')


    ############ WRITING TAGS ############

    declare -A flac_tag=()
    while IFS== read -r key value; do 
      [[ $key ]] && flac_tag[$key]=$value
    done < <( metaflac --export-tags-to=- "$i" | sed 's/=\([[:lower:]]\)/=\u\1/g;s/(\([[:lower:]]\)/(\u\1/g;s/ \([[:lower:]]\)/ \u\1/g;s/Dj/DJ/g' | sed 's/\s+$//' )

    ### Title ###

    if [[ -z "${flac_tag[TITLE]}" ]]; then
      flac_tag[TITLE]="$FLAC_FILENAME_TITLE"
    fi

    if [[ -n "${flac_tag[TITLE]}" ]]; then
      metaflac --set-tag="TITLE=${flac_tag[TITLE]}" "$i"
    fi

    ### Artist ###

    if [[ -z "${flac_tag[ARTIST]}" ]]; then
      flac_tag[ARTIST]="$FLAC_FILENAME_ARTIST"
    fi

    if [[ "${flac_tag[ARTIST]}" =~ ^[Vv][^[:alnum:]_]*[Aa][^[:alnum:]_]*(rious)?[^[:alnum:]]*([Aa]rtist(s)?)?[^[:alnum:]_]*$ ]]; then
      flac_tag[ARTIST]="Various Artists"
    fi

    if [[ -n "${flac_tag[ARTIST]}" ]]; then
      metaflac --set-tag="ARTIST=${flac_tag[ARTIST]}" "$i"
    fi

    ### Album ###

    if [[ -n "${flac_tag[ALBUM]}" ]]; then
      flac_tag[ALBUM]="$(echo "${flac_tag[ALBUM]}" | sed 's/\sWEB//' | sed 's/\sEP//')"
      metaflac --set-tag="ALBUM=${flac_tag[ALBUM]}" "$i"
    fi

    ### Track Number ###

    if [[ -z "${flac_tag[TRACKNUMBER]}" && -n "${flac_tag[TRACK]}" ]]; then
      flac_tag[TRACKNUMBER]=$(echo "${flac_tag[TRACK]}" | sed 's/^0//')
    fi

    if [[ -z "${flac_tag[TRACKNUMBER]}" ]]; then
      flac_tag[TRACKNUMBER]="$FLAC_FILENAME_TRACKNUMBER"
    fi

    if [[ -n "${flac_tag[TRACKNUMBER]}" ]]; then
      flac_tag[TRACKNUMBER]=$(echo "${flac_tag[TRACKNUMBER]}" | sed 's/^0//')
      metaflac --remove-tag="TRACK" --set-tag="TRACKNUMBER=${flac_tag[TRACKNUMBER]}" "$i"
    fi

    ### Track Total ###

    if [[ -z "${flac_tag[TRACKTOTAL]}" && -n "${flac_tag[TOTALTRACKS]}" ]]; then
      flac_tag[TRACKTOTAL]=$(echo "${flac_tag[TOTALTRACKS]}" | sed 's/^0//')
    fi

    if [[ -z "${flac_tag[TRACKTOTAL]}" ]]; then
      flac_tag[TRACKTOTAL]="$NFO_TRACKTOTAL"
    fi    

    if [[ -n "${flac_tag[TRACKTOTAL]}" ]]; then
      flac_tag[TRACKTOTAL]=$(echo "${flac_tag[TRACKTOTAL]}" | sed 's/^0//')
      metaflac --remove-tag="TRACKC" --set-tag="TRACKTOTAL=${flac_tag[TRACKTOTAL]}" --set-tag="TOTALTRACKS=${flac_tag[TRACKTOTAL]}" "$i"
    fi

    ### Disc Number ###

    if [[ -z "${flac_tag[DISCNUMBER]}" && -n "${flac_tag[DISC]}" ]]; then
      flac_tag[DISCNUMBER]=$(echo "${flac_tag[DISC]}" | sed 's;^0;;')     
    fi

    if [[ -n "${flac_tag[DISCNUMBER]}" ]]; then
      flac_tag[DISCNUMBER]=$(echo "${flac_tag[DISCNUMBER]}" | sed 's/^0//')
      metaflac --remove-tag="DISC" --set-tag="DISCNUMBER=${flac_tag[DISCNUMBER]}" "$i"
    fi

    ### Disc Total ###

    if [[ -z "${flac_tag[DISCTOTAL]}" && -n "${flac_tag[TOTALDISCS]}" ]]; then
      flac_tag[DISCTOTAL]=$(echo "${flac_tag[TOTALDISCS]}" | sed 's/^0//')
    fi

    if [[ -n "${flac_tag[DISCTOTAL]}" ]]; then
      flac_tag[TOTALDISCS]=$(echo "${flac_tag[DISCTOTAL]}" | sed 's/^0//')
      metaflac --set-tag="TOTALDISCS=${flac_tag[TOTALDISCS]}" --set-tag="DISCTOTAL=${flac_tag[DISCTOTAL]}" "$i"
    fi

    ### Publisher ###

    if [[ -z "${flac_tag[PUBLISHER]}" ]]; then
      flac_tag[PUBLISHER]="$NFO_PUBLISHER"
    fi

    if [[ -n "${flac_tag[PUBLISHER]}" ]]; then
      metaflac --set-tag="PUBLISHER=${flac_tag[PUBLISHER]}" "$i"
    fi

    ### Album Artist ###

    if [[ -z "${flac_tag[ALBUMARTIST]}" ]]; then
      flac_tag[ALBUMARTIST]="$NFO_ALBUMARTIST"
    fi

    if [[ -z "${flac_tag[ALBUMARTIST]}" ]]; then
      flac_tag[ALBUMARTIST]="${flac_tag[ALBUM ARTIST]}"
    fi

    if [[ -z "${flac_tag[ALBUMARTIST]}" ]]; then
      flac_tag[ALBUMARTIST]="${flac_tag[ARTIST]}"
    fi

    if [[ "${flac_tag[ALBUMARTIST]}" =~ ^[Vv][^[:alnum:]_]*[Aa][^[:alnum:]_]*(rious)?[^[:alnum:]]*([Aa]rtist(s)?)?[^[:alnum:]_]*$ ]]; then
      flac_tag[ALBUMARTIST]="Various Artists"
    fi

    if [ "${flac_tag[ALBUMARTIST]}" == "Various Artists" ]; then
      flac_tag[COMPILATION]="1"
      compilation="1"
    fi

    if [[ -n "${flac_tag[ALBUMARTIST]}" ]]; then
      metaflac --remove-tag="ALBUM ARTIST" --set-tag="ALBUMARTIST=${flac_tag[ALBUMARTIST]}" "$i"
    fi

    ### Catalog Number ###

    if [[ -z "${flac_tag[CATALOGNUMBER]}" ]]; then
      flac_tag[CATALOGNUMBER]="$NFO_CATALOGNUMBER"
    fi

    if [[ -z "${flac_tag[CATALOGNUMBER]}" ]]; then
      flac_tag[CATALOGNUMBER]=$(metaflac --export-tags-to=- "$i" | grep -oP -i '(?:cat|catalog).? ?(?:nr|number|#)=\K(((?:[a-zA-Z0-9]+ ?)*))(?:\s|$)' | sed 's/ *$//g')
    fi

    if [[ -n "${flac_tag[CATALOGNUMBER]}" ]]; then
      metaflac --set-tag="CATALOGNUMBER=${flac_tag[CATALOGNUMBER]}" "$i"
    fi

    ### Genre ###

    flac_tag[GENRE]="$custom1"

    if [[ -n "${flac_tag[GENRE]}" ]]; then
      metaflac --set-tag="GENRE=${flac_tag[GENRE]}" "$i"
    fi

    ### Date ###

    if [[ -z "${flac_tag[DATE]}" ]]; then
      flac_tag[DATE]="$NFO_YEAR"
      metaflac --set-tag="DATE=${flac_tag[DATE]}" "$i"
    fi

    ### Beats per minute ###

    if [[ -z "${flac_tag[BPM]}" ]]; then
      if [ "${flac_tag[GENRE]}" == "Hardstyle" ]; then
        /srv/rtorrent/config/rtorrent/bpmwrap.sh -v -t flac -w -m 130 -x 200 "$i"
      else
        /srv/rtorrent/config/rtorrent/bpmwrap.sh -v -t flac -w -m 80 -x 320 "$i"
      fi
    fi

    echo ""
    echo "### NEW  TAGS ###"
    echo ""
    metaflac --export-tags-to=- "$i"

    unset flac_tag
  done
fi

### Beets Import ###

if [ "$compilation" == "1" ]; then
  beet -v import -q --set comp="True" "$temppath/$name"
else
  beet -v import -q "$temppath/$name"
fi

rm -r "${temppath:?}/${name:?}"

echo "-------------------------------"
echo "||   Processing completed!   ||"
echo "-------------------------------"

echo "$(date '+%d/%m/%y %H:%M:%S') | $name" >> "$histfile"
echo "$(date '+%d/%m/%y %H:%M:%S') | Music    | COMPLETED Processing $name" >> "$masterlog"
