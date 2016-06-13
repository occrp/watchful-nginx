# Watchful NginX

Watchful NginX container -- `nginx` docker container that watches for logrotated logfiles using `inotify` and makes sure `nginx` reloads them when needed. A nasty, but functional, kludge of a work-around for [lack of PID namespaces in docker](https://github.com/docker/docker/issues/10163).

Upon start it creates a dhparam file in `/etc/ssl/nginx/dhparam.pem` (if the file does not exist) and sets an `inotify` watch on `/srv/logs/nginx/logrotate`. Once the watch discovers that the watchfile has been modified, it sends the `USR1` signal to `nginx`, which causes it to reload the logfiles.

Use by volume-mounting the watchfile in this container and in a container that logrotate runs in, and making sure logrotate touches/modifies that file, for instance by using the following in your logrotate config files:

```
postrotate
      /bin/date > /srv/logs/nginx/logrotate
```

## ToDo

 - watch the logfiles themselves and remove the need for the explicit logrotate flag file
 - more configuration options (logfile/watchfile locations, etc)

