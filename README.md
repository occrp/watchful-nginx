# Watchful NginX

Watchful NginX container -- `nginx` docker container that watches for logrotated logfiles using `inotify` and makes sure `nginx` reloads them when needed. A nasty, but functional, kludge of a work-around for [lack of PID namespaces in docker](https://github.com/docker/docker/issues/10163).

## Building

The image can be built with either [`nginx` package installed from `nginx.org` repository](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/?highlight=packages#official-debian-ubuntu-packages), or any of [`nginx-light`, `nginx-full`, `nginx-extras` installed from official Debian repository](https://wiki.debian.org/Nginx#Recap_of_the_different_modules_in_every_package_.28starting_Squeeze-Backports.29). This is controlled by `NGINX_PACKAGE` build argument.

By default, `nginx` package from `nginx.org` is being installed. If `NGINX_PACKAGE` is set to anything else than `nginx`, packages from default Debian repositories are used instead.

The `NGINX_VERSION` build argument controls the `nginx` package version that is going to be installed. By default, version `1.13*` (the latest) is used.

**NOTICE: package versions in official Debian repositories are much older than on `nginx.org`; hence, when using them, remember to set `NGINX_VERSION` accordingly. As of this writing Debian jessie package version is at `1.10*`.**

## Environment variables

***More documentation needed here***

 - `NGINX_BOOT` (default: unset)  
    if set to string `"false"`, the entrypoint script will exit immediately before running `nginx`, in effect making it possible to use the image to generate `dhparam` file and quit (curtesy [@cguess](https://twitter.com/cguess)).
    
 - `NO_DHPARAM` (default: unset)  
    if set to string `"true"`, `dhparam` generation will be skipped entirely; this is *not* a good idea, and should be used only for internal/utility nginx instances that run behind another webserver with TLS support.
    
 - `PID_FILE` (default: "`/var/run/nginx.pid`")
 - `WATCH_FILE` (default: "`/srv/logs/nginx/logrotate`")
 - `DHPARAM_FILE` (default: "`/etc/ssl/nginx/dhparam.pem`")
    these control the locations where the `run.sh` script expects to find the `nginx` pidfile, the file to watch for logrotate signalling, and the SSL DH parameters files; these should reflect `nginx` config.

### Examples

Building the image with `nginx` package from `nginx.org`, version `1.13.x` (i.e. the default):

```bash
docker build ./
# equivalent to
docker build --build-arg=NGINX_PACKAGE=nginx --build-arg=NGINX_VERSION=1.13* --no-cache ./
```

Building the image with `nginx-extras` package from the Debian repository, version `1.10*`:

```
docker build --build-arg=NGINX_PACKAGE=nginx-extras --build-arg=NGINX_VERSION=1.10* --no-cache ./
```

## Operation

Upon start it creates a dhparam file in `$DHPARAM_FILE` (if the file does not exist) and sets an `inotify` watch on `$WATCH_FILE`. Once the watch discovers that the watchfile has been modified, it sends the `USR1` signal to `nginx`, which causes it to reload the logfiles.

Use by volume-mounting the watchfile in this container and in a container that logrotate runs in, and making sure logrotate touches/modifies that file, for instance by using the following in your logrotate config files:

```
postrotate
      /bin/date > /srv/logs/nginx/logrotate # or whatever is in $WATCH_FILE
```

## ToDo

 - watch the logfiles themselves and remove the need for the explicit logrotate flag file
 - more configuration options (logfile/watchfile locations, etc)

