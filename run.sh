#!/bin/bash

#    Watchful NginX container -- nginx docker container that watches for
#    logrotated logfiles and makes sure nginx reloads them when needed.
#    
#    Copyright (C) 2015 Organized Crime and Corruption Reporting Project
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as
#    published by the Free Software Foundation, either version 3 of the
#    License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.

# TODO FIXME actually monitoring the logfiles
# getting them via lsof $( cat PID_FILE )

# yes, this is dead-simple; just watch this file,
# and if it gets modified, send nginx the signal
WATCH_FILE="/srv/logs/nginx/logrotate"

# we need this for signal sending
PID_FILE="/var/run/nginx.pid"

# we need this for DHParram generation
DHPARAM_FILE="/etc/ssl/nginx/dhparam.pem"

# this waits for changes in $WATCH_FILE and sends nginx a USR1 signal to reload the logfiles
function watch_logfiles {

  # inform
  echo "+-- watching for changes in watchfile at: $WATCH_FILE"

  # loopy-loop!
  # FIXME we need to handle SIGHUP/SIGTERM/SIGKILL nicely some day
  while true; do
    # if the file is not there, create
    if [ ! -e "$WATCH_FILE" ]; then
      echo "    +-- watch file missing, creating it at: $WATCH_FILE"
      touch "$WATCH_FILE"
    fi
    # wait for events
    inotifywait -r -e modify -e move -e create -e delete -qq "$WATCH_FILE"
    # if a watched event occured, send the signal
    if [ $? -eq 0 ]; then
      echo "    +-- watch file changed, sending USR1 to nginx (pid $( cat "$PID_FILE" ))..."
      kill -USR1 "$( cat "$PID_FILE" )"
    fi
  done
}

# create the dhparams
if [ "$NO_DHPARAM" -eq "true" ]; then
  echo "+-- dhparam generation explicitly disabled"
  echo "    THIS IS INSECURE"
elif [ ! -e "$DHPARAM_FILE" ]; then
  echo "+-- generating dhparam in $DHPARAM_FILE"
  mkdir -p "$( dirname "$DHPARAM_FILE" )"
  openssl dhparam -out "$DHPARAM_FILE" 4096
  chown -R www-data:www-data "$( dirname "$DHPARAM_FILE" )"
  chmod ug=rX,o= "$( dirname "$DHPARAM_FILE" )"
else
  echo "+-- dhparam found in $DHPARAM_FILE"
fi

if [ "$NGINX_BOOT" = "false" ]; then
  echo "NGINX_BOOT is set to false, exiting."
  exit
fi

# start the watch
watch_logfiles &
sleep 1

# run nginx
echo "+-- starting nginx..."
exec /usr/sbin/nginx -g "daemon off;"