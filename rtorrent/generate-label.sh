#!/bin/bash

echo "$(date '+%d/%m/%y %H:%M:%S') | generate-label" >> /config/rtorrent/execute.log

HASH="$1"
TAGS="$2"

echo "Hash = $HASH"
echo "Tags = $TAGS"

LABEL=$(echo "$TAGS" | sed 's/,/ , /g;s/\s\+/ /g;s:\s*/*\s*$::g' | sed 's/"\([[:lower:]]\)/"\u\1/g;s/^\([[:lower:]]\)/\u\1/g;s/ \([[:lower:]]\)/ \u\1/g' | sed 's:,:/:g')

xmlrpc 172.17.0.3:9080/RPC2 d.custom1.set "$HASH" "$LABEL"
