#!/bin/bash

###################################################################################
#                                  DEPENDENCIES                                   #      
###################################################################################
#                                                                                 #
# bpmwrap.sh                                                                      #
#   https://github.com/meridius/bpmwrap/blob/master/bpmwrap.sh                    #
#                                                                                 #
# beets                                                                           #
#   https://github.com/beetbox/beets                                              #
#                                                                                 #
# metaflac (from "flac" package)                                                  #
#   https://github.com/xiph/flac                                                  #
#                                                                                 #
# mid3v2 (from "python-mutagen" package)                                          #
#   https://github.com/quodlibet/python-mutagen                                   #
#                                                                                 #
###################################################################################


source /srv/rtorrent/config/rtorrent/vars.txt

temppath="/srv/rtorrent/config/rtorrent/tmp"
histfile="/srv/rtorrent/config/rtorrent/history.txt"
masterlog="/srv/linx.log"

echo "$(date '+%d/%m/%y %H:%M:%S') | Music    | STARTING Processing $name" >> "$masterlog"

echo ""
echo ""
echo "#####  Post-Processing started for $name  #####"

if [ ! -d "$base_path" ]; then
  exit
fi

cp -rv "$base_path/" "$temppath"/
cd "$temppath/$name" || exit


parse_nfo () {
  sed -i 's; N/A;;g' "./$1"*.nfo
  sed -i 's/ None$//g' "./$1"*.nfo

  ### Album ###

  NFO_PUBLISHER=$(cat "./$1"*.nfo | grep -oP -i '(?:album|title).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_PUBLISHER" ]]; then
    NFO_PUBLISHER=$(cat "./$1"*.nfo | grep -oP -i '(?:album|title).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))' | sed 's/ *$//g')
  fi

  ### Publisher ###

  NFO_PUBLISHER=$(cat "./$1"*.nfo | grep -oP -i '(?:label|company|publisher).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_PUBLISHER" ]]; then
    NFO_PUBLISHER=$(cat "./$1"*.nfo | grep -oP -i '(?:label|company|publisher).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))' | sed 's/ *$//g')
  fi

  ### Album Artist ###

  NFO_ALBUMARTIST=$(cat "./$1"*.nfo | grep -oP -i '(?:artist|artists|performer).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_ALBUMARTIST" ]]; then
    NFO_ALBUMARTIST=$(cat "./$1"*.nfo | grep -oP -i '(?:artist|artists|performer).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9-&-.]+ ?)*))' | sed 's/ *$//g')
  fi

  ### Catalog Number ###

  NFO_CATALOGNUMBER=$(cat "./$1"*.nfo | grep -oP -i '(?:cat|catalog).? ?(?:nr|number|#).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_CATALOGNUMBER" ]]; then
    NFO_CATALOGNUMBER=$(cat "./$1"*.nfo | grep -oP -i '(?:cat|catalog).? ?(?:nr|number|#).*(?:\:|\[|\]|\=|\-)[\s]* \K(((?:[a-zA-Z0-9]+ ?)*))' | sed 's/ *$//g')
  fi

  ### Track Total ###

  NFO_TRACKTOTAL=$(cat "./$1"*.nfo | grep -oP -i '(?:tracks|trackcount).*(?:\:|\[|\]|\=|\-)[\s]* 0?\K(((?:[0-9]+ ?)*))(?:\s|$)' | sed 's/ *$//g')

  if [[ -z "$NFO_TRACKTOTAL" ]]; then
    NFO_TRACKTOTAL=$(cat "./$1"*.nfo | grep -oP -i '(?:tracks|trackcount).*(?:\:|\[|\]|\=|\-)[\s]* 0?\K(((?:[0-9]+ ?)*))' | sed 's/ *$//g')
  fi

  ### Year ###

  NFO_YEAR=$(cat "./$1"*.nfo | grep -oP -i '(?:date|year).*(?:\:|\[|\]|\=|\-)[\s]* .*(?=[0-9]{4})\K([1-2][0-9]{3})' | sed 's/ *$//g')
}


parse_mp3 () {
  for i in "./$1"*.mp3; do
    echo ""
    echo "PROCESSING MP3 TRACK | $i"
    echo ""
    echo ""
    echo "###############################################################################"
    echo "###############################  ORIGINAL TAGS  ###############################"
    echo "###"
    echo "###"
    mid3v2 --list "$i" | sed 's/^/###  /'
    echo "###"
    echo "###"
    echo "###############################################################################"
    echo "###############################################################################"
    echo ""
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
      mp3_tag[TPE2]=$(echo "${mp3_tag[TPE2]}" | sed -E 's| [fF](ea)?t\.? .*||g')
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

    if [[ -n "${mp3_tag[TCON]}" && "${mp3_tag[TCON]}" != "Upload" ]]; then
      mid3v2 --TCON "${mp3_tag[TCON]}" "$i"
    fi

    ### Date ###

    if [[ -z "${mp3_tag[TDRC]}" && -z "${mp3_tag[TYER]}" ]]; then
      mp3_tag[TDRC]="$NFO_YEAR"
      mid3v2 --TDRC "${mp3_tag[TDRC]}" "$i"
    fi

    ### Beats per minute ###

    if [[ -z "${mp3_tag[TBPM]}" ]]; then
      if [ "${mp3_tag[TCON]}" == "Hardstyle" ]; then
        /srv/rtorrent/config/rtorrent/bpmwrap.sh -v -w -m 130 -x 200 "$i"
      elif [ "${mp3_tag[TCON]}" == "Pop" ]; then
        /srv/rtorrent/config/rtorrent/bpmwrap.sh -v -w -m 70 -x 180 "$i"
      else
        /srv/rtorrent/config/rtorrent/bpmwrap.sh -v -w -m 70 -x 300 "$i"
      fi
    fi

    echo ""
    echo ""
    echo "###############################################################################"
    echo "#################################  NEW TAGS  ##################################"
    echo "###"
    echo "###"
    mid3v2 --list "$i" | sed 's/^/###  /'
    echo "###"
    echo "###"
    echo "###############################################################################"
    echo "###############################################################################"
    echo ""
    echo ""

    unset mp3_tag
    unset mp3_tag_TXXX
  done
}


parse_flac () {
  for i in "./$1"*.flac; do
    echo ""
    echo "PROCESSING FLAC TRACK | $i"
    echo ""
    echo ""
    echo "###############################################################################"
    echo "###############################  ORIGINAL TAGS  ###############################"
    echo "###"
    echo "###"
    metaflac --export-tags-to=- "$i" | sed 's/^/###  /'
    echo "###"
    echo "###"
    echo "###############################################################################"
    echo "###############################################################################"
    echo ""
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

      if [[ -n "${flac_tag[TITLE]}" ]]; then
        metaflac --set-tag="TITLE=${flac_tag[TITLE]}" "$i"
      fi
    fi

    ### Artist ###

    if [[ -z "${flac_tag[ARTIST]}" ]]; then
      flac_artist="$FLAC_FILENAME_ARTIST"
    
      if [[ "$flac_artist" =~ ^[Vv][^[:alnum:]_]*[Aa][^[:alnum:]_]*(rious)?[^[:alnum:]]*([Aa]rtist(s)?)?[^[:alnum:]_]*$ ]]; then
        flac_artist="Various Artists"
      fi

      if [[ -n "$flac_artist" ]]; then
        metaflac --set-tag="ARTIST=$flac_artist" "$i"
      fi
    fi

    flac_artist=""

    ### Album ###

    if [[ -n "${flac_tag[ALBUM]}" ]]; then
      flac_album="$(echo "${flac_tag[ALBUM]}" | sed 's/\sWEB//' | sed 's/\sEP//')"
      metaflac --remove-tag="ALBUM" "$1"
      metaflac --set-tag="ALBUM=$flac_album" "$i"
    fi

    flac_album=""

    ### Track Number ###

    if [[ -n "${flac_tag[TRACKNUMBER]}" ]]; then
      flac_tracknumber="${flac_tag[TRACKNUMBER]}"
      metaflac --remove-tag="TRACKNUMBER" "$1"
    fi

    if [[ -n "${flac_tag[TRACK]}" ]]; then
      flac_tracknumber="${flac_tag[TRACK]}"
      metaflac --remove-tag="TRACK" "$1"
    fi

    if [[ -z "$flac_tracknumber" ]]; then
      flac_tracknumber="$FLAC_FILENAME_TRACKNUMBER"
    fi

    if [[ -n "$flac_tracknumber" ]]; then
      flac_tracknumber=$(echo "$flac_tracknumber" | sed 's/^0//')
      metaflac --set-tag="TRACKNUMBER=$flac_tracknumber" "$i"
    fi

    flac_tracknumber=""

    ### Track Total ###

    if [[ -n "${flac_tag[TOTALTRACKS]}" ]]; then
      flac_totaltracks="${flac_tag[TOTALTRACKS]}"
      metaflac --remove-tag="TOTALTRACKS" "$1"
    fi

    if [[ -n "${flac_tag[TRACKTOTAL]}" ]]; then
      flac_totaltracks="${flac_tag[TRACKTOTAL]}"
      metaflac --remove-tag="TRACKTOTAL" "$1"
    fi

    if [[ -z "$flac_totaltracks" ]]; then
      flac_totaltracks="$NFO_TRACKTOTAL"
    fi    

    if [[ -n "$flac_totaltracks" ]]; then
      flac_totaltracks=$(echo "$flac_totaltracks" | sed 's/^0//')
      metaflac --remove-tag="TRACKC" --set-tag="TOTALTRACKS=$flac_totaltracks" "$i"
    fi

    flac_totaltracks=""

    ### Disc Number ###

    if [[ -n "${flac_tag[DISCNUMBER]}" ]]; then
      flac_discnumber="${flac_tag[DISCNUMBER]}"
      metaflac --remove-tag="DISCNUMBER" "$1"
    fi

    if [[ -n "${flac_tag[DISC]}" ]]; then
      flac_discnumber="${flac_tag[DISC]}"
      metaflac --remove-tag="DISC" "$1"
    fi

    if [[ -n "$flac_discnumber" ]]; then
      flac_discnumber=$(echo "$flac_discnumber" | sed 's/^0//')
      metaflac --set-tag="DISCNUMBER=$flac_discnumber" "$i"
    fi

    flac_discnumber=""

    ### Disc Total ###

    if [[ -n "${flac_tag[TOTALDISCS]}" ]]; then
      flac_totaldiscs="${flac_tag[TOTALDISCS]}"
      metaflac --remove-tag="TOTALDISCS" "$1"
    fi

    if [[ -n "${flac_tag[DISCTOTAL]}" ]]; then
      flac_totaldiscs="${flac_tag[DISCTOTAL]}"
      metaflac --remove-tag="DISCTOTAL" "$1"
    fi

    if [[ -z "$flac_totaldiscs" ]]; then
      flac_totaldiscs="$NFO_DISCTOTAL"
    fi    

    if [[ -n "$flac_totaldiscs" ]]; then
      flac_totaldiscs=$(echo "$flac_totaldiscs" | sed 's/^0//')
      metaflac --set-tag="TOTALDISCS=$flac_totaldiscs" "$i"
    fi

    flac_totaldiscs=""

    ### Publisher ###

    if [[ -n "${flac_tag[PUBLISHER]}" ]]; then
      flac_publisher="${flac_tag[PUBLISHER]}"
      metaflac --remove-tag="PUBLISHER" "$1"
    fi

    if [[ -z "$flac_publisher" ]]; then
      flac_publisher="$NFO_PUBLISHER"
    fi

    if [[ -n "$flac_publisher" ]]; then
      metaflac --set-tag="PUBLISHER=$flac_publisher" "$i"
    fi

    flac_publisher=""

    ### Album Artist ###

    if [[ -n "${flac_tag[ALBUMARTIST]}" ]]; then
      flac_albumartist="${flac_tag[ALBUMARTIST]}"
      metaflac --remove-tag="ALBUMARTIST" "$1"
    fi

    if [[ -n "${flac_tag[ALBUM ARTIST]}" ]]; then
      flac_albumartist="${flac_tag[ALBUM ARTIST]}"
      metaflac --remove-tag="ALBUM ARTIST" "$1"
    fi

    if [[ -z "$flac_albumartist" ]]; then
      flac_albumartist="$NFO_ALBUMARTIST"
    fi

    if [[ -z "$flac_albumartist" ]]; then
      flac_albumartist="${flac_tag[ARTIST]}"
    fi

    if [[ "$flac_albumartist" =~ ^[Vv][^[:alnum:]_]*[Aa][^[:alnum:]_]*(rious)?[^[:alnum:]]*([Aa]rtist(s)?)?[^[:alnum:]_]*$ ]]; then
      flac_albumartist="Various Artists"
    fi

    if [ "$flac_albumartist" == "Various Artists" ]; then
      if [[ -z "${flac_tag[COMPILATION]}" ]]; then
        metaflac --set-tag="COMPILATION=1" "$i"
      fi
      compilation="1"
    fi

    if [[ -n "$flac_albumartist" ]]; then
      metaflac --set-tag="ALBUMARTIST=$flac_albumartist" "$i"
    fi

    flac_albumartist=""

    ### Catalog Number ###

    if [[ -z "${flac_tag[CATALOGNUMBER]}" ]]; then
      flac_tag[CATALOGNUMBER]="$NFO_CATALOGNUMBER"
    
      if [[ -z "${flac_tag[CATALOGNUMBER]}" ]]; then
        flac_tag[CATALOGNUMBER]=$(metaflac --export-tags-to=- "$i" | grep -oP -i '(?:cat|catalog).? ?(?:nr|number|#)=\K(((?:[a-zA-Z0-9]+ ?)*))(?:\s|$)' | sed 's/ *$//g')
      fi

      if [[ -n "${flac_tag[CATALOGNUMBER]}" ]]; then
        metaflac --set-tag="CATALOGNUMBER=${flac_tag[CATALOGNUMBER]}" "$i"
      fi
    fi

    ### Genre ###

    flac_genre="$custom1"

    if [[ -n "$flac_genre" ]]; then
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
        /srv/rtorrent/config/rtorrent/bpmwrap.sh -v -t flac -w -m 135 -x 180 "$i"
      elif [ "${flac_tag[GENRE]}" == "Hardcore" ]; then
        /srv/rtorrent/config/rtorrent/bpmwrap.sh -v -t flac -w -m 160 -x 320 "$i"
      else 
        /srv/rtorrent/config/rtorrent/bpmwrap.sh -v -t flac -w -m 80 -x 320 "$i"
      fi
    fi

    echo ""
    echo ""
    echo "###############################################################################"
    echo "#################################  NEW TAGS  ##################################"
    echo "###"
    echo "###"
    metaflac --export-tags-to=- "$i" | sed 's/^/###  /'
    echo "###"
    echo "###"
    echo "###############################################################################"
    echo "###############################################################################"
    echo ""
    echo ""

    unset flac_tag
  done
}

if ls ./*.nfo >/dev/null 2>&1; then
  parse_nfo
fi

if find ./*/ -type d 2>/dev/null; then
  echo "Multiple disc-folders detected."
  for d in */; do
    if ls "./$d"*.nfo >/dev/null 2>&1; then
      parse_nfo "$d"
    fi

    if ls "./$d"*.mp3 >/dev/null 2>&1; then
      parse_mp3 "$d"
    fi

    if ls "./$d"*.flac >/dev/null 2>&1; then
      parse_flac "$d"
    fi
  done
else
  if ls ./*.mp3 >/dev/null 2>&1; then
    parse_mp3
  fi

  if ls ./*.flac >/dev/null 2>&1; then
    parse_flac
  fi
fi


### Beets Import ###

if [ "$compilation" == "1" ]; then
  beet -v import -q --set comp="True" "$temppath/$name"
else
  beet -v import -q "$temppath/$name"
fi

rm -r "${temppath:?}/${name:?}"

echo "-----------------------------------------------------------"
echo "||                 Processing completed!                 ||"
echo "-----------------------------------------------------------"

echo "$(date '+%d/%m/%y %H:%M:%S') | $name" >> "$histfile"
echo "$(date '+%d/%m/%y %H:%M:%S') | Music    | COMPLETED Processing $name" >> "$masterlog"
