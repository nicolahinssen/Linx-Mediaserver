#!/bin/bash

episodefile_path="$1"

### Video variables ###

#bitrate=$(mediainfo --Inform="General;%BitRate%") "$sonarr_episodefile_path" 

### Find subtitles ###

subliminal --addic7ed escapereality tessel --opensubtitles escape-reality tessel download -l nl -l en  -p addic7ed -p opensubtitles -p podnapisi -p shooter -p thesubdb -p tvsubtitles -r metadata -f "$episodefile_path"

### Transcode ###

transcode-video --no-log --quick --mp4 --add-subtitle nld,eng "$episodefile_path" 

export episodefile_path=$(echo "$episodefile_path" | sed 's/\.mkv$/.mp4/')

### Tag mp4 ###

python /srv/scripts/sickbeard_mp4_automator/manual.py --nomove -a "$episodefile_path"

### Move ### 

filebot -script fn:amc --def seriesFormat="/srv/media/TV-Shows/{n}/Season {s}/{n} - {s00e00} - {t} [{source}-{vf}] {vc} {ac} {'-'+group}" --def extras=n --def artwork=n "$episodefile_path"
