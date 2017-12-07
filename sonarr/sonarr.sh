#!/bin/bash

printf "Running vartofile.sh...\n\n"

SAVEFILE=/downloads/Scripts/vars.txt

printf "Saving variables...\n\n"

echo "sonarr_eventtype="\""$sonarr_eventtype\"" > $SAVEFILE
echo "sonarr_isupgrade="\""$sonarr_isupgrade\"" >> $SAVEFILE
echo "sonarr_series_id="\""$sonarr_series_id\"" >> $SAVEFILE
echo "sonarr_series_title="\""$sonarr_series_title\"" >> $SAVEFILE
echo "sonarr_series_path="\""$sonarr_series_path\"" >> $SAVEFILE
echo "sonarr_series_tvdbid="\""$sonarr_series_tvdbid\"" >> $SAVEFILE
echo "sonarr_series_tvmazeid="\""$sonarr_series_tvmazeid\"" >> $SAVEFILE
echo "sonarr_series_imdb="\""$sonarr_series_imdb\"" >> $SAVEFILE
echo "sonarr_series_type="\""$sonarr_series_type\"" >> $SAVEFILE
echo "sonarr_episodefile_id="\""$sonarr_episodefile_id\"" >> $SAVEFILE
echo "sonarr_episodefile_relativepath="\""$sonarr_episodefile_relativepath\"" >> $SAVEFILE
echo "sonarr_episodefile_path="\""$sonarr_episodefile_path\"" >> $SAVEFILE
echo "sonarr_episodefile_episodecount="\""$sonarr_episodefile_episodecount\"" >> $SAVEFILE
echo "sonarr_episodefile_seasonnumber="\""$sonarr_episodefile_seasonnumber\"" >> $SAVEFILE
echo "sonarr_episodefile_episodenumbers="\""$sonarr_episodefile_episodenumbers\"" >> $SAVEFILE
echo "sonarr_episodefile_episodeairdates="\""$sonarr_episodefile_episodeairdates\"" >> $SAVEFILE
echo "sonarr_episodefile_episodeairdatesutc="\""$sonarr_episodefile_episodeairdatesutc\"" >> $SAVEFILE
echo "sonarr_episodefile_episodetitles="\""$sonarr_episodefile_episodetitles\"" >> $SAVEFILE
echo "sonarr_episodefile_quality="\""$sonarr_episodefile_quality\"" >> $SAVEFILE
echo "sonarr_episodefile_qualityversion="\""$sonarr_episodefile_qualityversion\"" >> $SAVEFILE
echo "sonarr_episodefile_releasegroup="\""$sonarr_episodefile_releasegroup\"" >> $SAVEFILE
echo "sonarr_episodefile_scenename="\""$sonarr_episodefile_scenename\"" >> $SAVEFILE
echo "sonarr_episodefile_sourcepath="\""$sonarr_episodefile_sourcepath\"" >> $SAVEFILE
echo "sonarr_episodefile_sourcefolder="\""$sonarr_episodefile_sourcefolder\"" >> $SAVEFILE
echo "sonarr_deletedrelativepaths="\""$sonarr_deletedrelativepaths\"" >> $SAVEFILE
echo "sonarr_deletedpaths="\""$sonarr_deletedpaths\"" >> $SAVEFILE
echo "sonarr_download_id="\""$sonarr_download_id\"" >> $SAVEFILE

sed -i 's:/tv:/srv/media/TV-Shows:g' $SAVEFILE
sed -i 's:/downloads:/srv/rtorrent/data/sonarr:g' $SAVEFILE

cat $SAVEFILE

ssh nicola@192.168.178.13 /srv/rtorrent/data/sonarr/Scripts/postprocess.sh
