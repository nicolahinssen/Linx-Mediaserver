#!/bin/bash

masterlog="/srv/linx.log"
logfile="/srv/scripts/radarr/logfile.txt"
exec > >(tee -a $logfile)
exec 2> >(tee -a $masterlog)

(
flock 200

echo "$(date '+%d/%m/%y %H:%M:%S') | Radarr   | STARTING Post-processing $radarr_moviefile_scenename" >> "$masterlog"

echo "#######################################################################################"
echo ""
echo "$(date '+%d/%m/%y %H:%M:%S') | Post-processing $radarr_movie_title"
echo ""
echo "Exporting environment variables."
echo ""

export radarr_eventtype=$radarr_eventtype
export radarr_movie_id=$radarr_movie_id
export radarr_movie_title=$radarr_movie_title
export radarr_movie_path=$radarr_movie_path
export radarr_movie_imdbid=$radarr_movie_imdbid
export radarr_moviefile_id=$radarr_moviefile_id
export radarr_moviefile_relativepath=$radarr_moviefile_relativepath
export radarr_moviefile_path=$radarr_moviefile_path
export radarr_moviefile_quality=$radarr_moviefile_quality
export radarr_moviefile_qualityversion=$radarr_moviefile_qualityversion
export radarr_moviefile_releasegroup=$radarr_moviefile_releasegroup
export radarr_moviefile_scenename=$radarr_moviefile_scenename
export radarr_moviefile_sourcepath=$radarr_moviefile_sourcepath
export radarr_moviefile_sourcefolder=$radarr_moviefile_sourcefolder
export radarr_download_id=$radarr_download_id

echo "##  Environment variables  ##"

echo "radarr_eventtype=$radarr_eventtype"
echo "radarr_movie_id=$radarr_movie_id"
echo "radarr_movie_title=$radarr_movie_title"
echo "radarr_movie_path=$radarr_movie_path"
echo "radarr_movie_imdbid=$radarr_movie_imdbid"
echo "radarr_moviefile_id=$radarr_moviefile_id"
echo "radarr_moviefile_relativepath=$radarr_moviefile_relativepath"
echo "radarr_moviefile_path=$radarr_moviefile_path"
echo "radarr_moviefile_quality=$radarr_moviefile_quality"
echo "radarr_moviefile_qualityversion=$radarr_moviefile_qualityversion"
echo "radarr_moviefile_releasegroup=$radarr_moviefile_releasegroup"
echo "radarr_moviefile_scenename=$radarr_moviefile_scenename"
echo "radarr_moviefile_sourcepath=$radarr_moviefile_sourcepath"
echo "radarr_moviefile_sourcefolder=$radarr_moviefile_sourcefolder"
echo "radarr_download_id=$radarr_download_id"

echo ""
echo "Running postRadarr.py..."

python /srv/scripts/sickbeard_mp4_automator/postRadarr.py

# xmlrpc 192.168.178.13:9080/RPC2 d.erase $radarr_download_id

echo "Removing $sonarr_episodefile_sourcepath"
rm "$radarr_moviefile_sourcepath"

echo "$(date '+%d/%m/%y %H:%M:%S') | Radarr   | COMPLETED Post-processing $radarr_movie_title" >> "$masterlog"

) 200>/srv/scripts/radarr/postprocess.lock
