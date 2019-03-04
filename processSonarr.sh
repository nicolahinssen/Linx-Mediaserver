#!/bin/bash

### Sonarr variables ###

export sonarr_series_id="$sonarr_series_id"
export sonarr_series_title="$sonarr_series_title"
export sonarr_series_path="$sonarr_series_path"
export sonarr_series_tvdbid="$sonarr_series_tvdbid"
export sonarr_series_tvmazeid="$sonarr_series_tvmazeid"
export sonarr_series_imdb="$sonarr_series_imdb"
export sonarr_series_type="$sonarr_series_type"
export sonarr_episodefile_id="$sonarr_episodefile_id"
export sonarr_episodefile_relativepath="$sonarr_episodefile_relativepath"
export sonarr_episodefile_path="$sonarr_episodefile_path"
export sonarr_episodefile_episodecount="$sonarr_episodefile_episodecount"
export sonarr_episodefile_seasonnumber="$sonarr_episodefile_seasonnumber"
export sonarr_episodefile_episodenumbers="$sonarr_episodefile_episodenumbers"
export sonarr_episodefile_episodeairdates="$sonarr_episodefile_episodeairdates"
export sonarr_episodefile_episodeairdatesutc="$sonarr_episodefile_episodeairdatesutc"
export sonarr_episodefile_episodetitles="$sonarr_episodefile_episodetitles"
export sonarr_episodefile_quality="$sonarr_episodefile_quality"
export sonarr_episodefile_qualityversion="$sonarr_episodefile_qualityversion"
export sonarr_episodefile_releasegroup="$sonarr_episodefile_releasegroup"
export sonarr_episodefile_scenename="$sonarr_episodefile_scenename"
export sonarr_episodefile_sourcepath="$sonarr_episodefile_sourcepath"
export sonarr_episodefile_sourcefolder="$sonarr_episodefile_sourcefolder"
export sonarr_deletedrelativepaths="$sonarr_deletedrelativepaths"
export sonarr_deletedpaths="$sonarr_deletedpaths"
export sonarr_download_id="$sonarr_download_id"

export -p | grep 'sonarr_*' > /srv/scripts/sonarr_variables.txt

/srv/scripts/sickbeard_mp4_automator/venv/bin/python /srv/scripts/sickbeard_mp4_automator/postSonarr.py 
