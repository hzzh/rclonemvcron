#!/bin/sh

set -e

# Make sure UID and GID are both supplied
if [ -z "$GID" -a ! -z "$UID" ] || [ -z "$UID" -a ! -z "$GID" ]
then
  echo "WARNING: Must supply both UID and GID or neither. Stopping."
  exit 1
fi

# Process UID and GID
if [ ! -z "$GID" ]
then

  #Get group name or add it
  GROUP=$(getent group "$GID" | cut -d: -f1)
  if [ -z "$GROUP" ]
  then
    GROUP=rclonemv
    addgroup --gid "$GID" "$GROUP"
  fi

  #get user or add it
  USER=$(getent passwd "$UID" | cut -d: -f1)
  if [ -z "$USER" ]
  then
    USER=rclonemv
    adduser \
      --disabled-password \
      --gecos "" \
      --no-create-home \
      --ingroup "$GROUP" \
      --uid "$UID" \
      "$USER" >/dev/null
  fi
else
  USER=$(whoami)
fi

# Re-write cron shortcut
case "$(echo "$CRON" | tr '[:lower:]' '[:upper:]')" in
    *@YEARLY* ) echo "INFO: Cron shortcut $CRON re-written to 0 0 1 1 *" && CRONS="0 0 1 1 *";;
    *@ANNUALLY* ) echo "INFO: Cron shortcut $CRON re-written to 0 0 1 1 *" && CRONS="0 0 1 1 *";;
    *@MONTHLY* ) echo "INFO: Cron shortcut $CRON re-written to 0 0 1 * *" && CRONS="0 0 1 * * ";;
    *@WEEKLY* ) echo "INFO: Cron shortcut $CRON re-written to 0 0 * * 0" && CRONS="0 0 * * 0";;
    *@DAILY* ) echo "INFO: Cron shortcut $CRON re-written to 0 0 * * *" && CRONS="0 0 * * *";;
    *@MIDNIGHT* ) echo "INFO: Cron shortcut $CRON re-written to 0 0 * * *" && CRONS="0 0 * * *";;
    *@HOURLY* ) echo "INFO: Cron shortcut $CRON re-written to 0 * * * *" && CRONS="0 * * * *";;
    *@* ) echo "WARNING: Cron shortcut $CRON is not supported. Stopping." && exit 1;;
    * ) CRONS=$CRON;;
esac

# Set time zone if passed in
if [ ! -z "$TZ" ]
then
  cp /usr/share/zoneinfo/$TZ /etc/localtime
  echo $TZ > /etc/timezone
fi

rm -f /tmp/mv.pid

# Check for source and destination ; launch config if missing
if [ -z "$MV_SRC" ] || [ -z "$MV_DEST" ]
then
  echo "INFO: No MV_SRC and MV_DEST found. Stopping"
  exit 1
else
  # run mv either once or in cron depending on CRON

  if [ -z "$FORCE_MV" ]
  then
    echo "INFO: Add FORCE_MV=1 to perform a sync upon boot"
  else
    su "$USER" -c /mv.sh
  fi

  # Setup cron schedule
  crontab -d
  echo "$CRONS su $USER -c /mv.sh >>/tmp/mv.log 2>&1" > /tmp/crontab.tmp
  crontab /tmp/crontab.tmp
  rm /tmp/crontab.tmp

  # Start cron
  echo "INFO: Starting crond ..."
  touch /tmp/mv.log
  touch /tmp/crond.log
  crond -b -l 0 -L /tmp/crond.log
  echo "INFO: crond started"
  tail -F /tmp/crond.log
fi
