#!/bin/sh

set -e

echo "INFO: Starting mv.sh pid $$ $(date)"

if [ `lsof | grep $0 | wc -l | tr -d ' '` -gt 1 ]
then
  echo "WARNING: A previous mv is still running. Skipping new mv command."
else

  echo $$ > /tmp/mv.pid

  cd $MV_SRC
#cd /mnt/mediashare/media/rclone/radarr/downloads
  find . -type f ! -name '*.partial' -exec sh -c 'mkdir -p "$MV_DEST/$(dirname "$0")" && mv "$0" "$MV_DEST/$0"' {} \;
  find . -type d -empty -delete
fi
