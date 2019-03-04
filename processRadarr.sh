#!/bin/bash

### Radarr variables ###

export radarr_movie_id="$radarr_movie_id"
export radarr_movie_title="$radarr_movie_title"
export radarr_movie_path="$radarr_movie_path"
export radarr_movie_imdbid="$radarr_movie_imdbid"
export radarr_moviefile_id="$radarr_moviefile_id"
export radarr_moviefile_relativepath="$radarr_moviefile_relativepath"
export radarr_moviefile_path="$radarr_moviefile_path"
export radarr_moviefile_quality="$radarr_moviefile_quality"
export radarr_moviefile_qualityversion="$radarr_moviefile_qualityversion"
export radarr_moviefile_releasegroup="$radarr_moviefile_releasegroup"
export radarr_moviefile_scenename="$radarr_moviefile_scenename"
export radarr_moviefile_sourcepath="$radarr_moviefile_sourcepath"
export radarr_moviefile_sourcefolder="$radarr_moviefile_sourcefolder"
export radarr_download_id="$radarr_download_id"

export -p | grep 'radarr_*' > /srv/scripts/radarr_variables.txt

cd "$(dirname "$radarr_moviefile_path")"

/srv/scripts/sickbeard_mp4_automator/venv/bin/python /srv/scripts/sickbeard_mp4_automator/postRadarr.py 
