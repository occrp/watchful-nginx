# Watchful NginX

Watchful NginX container -- `nginx` docker container that watches for logrotated logfiles using `inotify` and makes sure `nginx` reloads them when needed. A nasty, but functional, kludge of a work-around for [lack of PID namespaces in docker](https://github.com/docker/docker/issues/10163).

## Building

The image can be built with either [`nginx` package installed from `nginx.org` repository](https://www.nginx.com/resources/wiki/start/topics/tutorials/install/?highlight=packages#official-debian-ubuntu-packages), or any of [`nginx-light`, `nginx-full`, `nginx-extras` installed from official Debian repository](https://wiki.debian.org/Nginx#Recap_of_the_different_modules_in_every_package_.28starting_Squeeze-Backports.29). This is controlled by `NGINX_PACKAGE` build argument.

By default, `nginx` package from `nginx.org` is being installed. If `NGINX_PACKAGE` is set to anything else than `nginx`, packages from default Debian repositories are used instead.

The `NGINX_VERSION` build argument controls the `nginx` package version that is going to be installed. By default, version `1.11*` (the latest) is used.

**NOTICE: package versions in official Debian repositories are much older than on `nginx.org`; hence, when using them, remember to set `NGINX_VERSION` accordingly. As of this writing Debian jessie package version is at `1.6*`.**

### Examples

Building the image with `nginx` package from `nginx.org`, version `1.11.x` (i.e. the default):

```bash
docker build ./
# equivalent to
docker build --build-arg=NGINX_PACKAGE=nginx --build-arg=NGINX_VERSION=1.11* --no-cache ./
```

Building the image with `nginx-extras` package from the Debian repository, version `1.6*`:

```
docker build --build-arg=NGINX_PACKAGE=nginx-extras --build-arg=NGINX_VERSION=1.6* --no-cache ./
```

## Operation

Upon start it creates a dhparam file in `/etc/ssl/nginx/dhparam.pem` (if the file does not exist) and sets an `inotify` watch on `/srv/logs/nginx/logrotate`. Once the watch discovers that the watchfile has been modified, it sends the `USR1` signal to `nginx`, which causes it to reload the logfiles.

Use by volume-mounting the watchfile in this container and in a container that logrotate runs in, and making sure logrotate touches/modifies that file, for instance by using the following in your logrotate config files:

```
postrotate
      /bin/date > /srv/logs/nginx/logrotate
```

## ToDo

 - watch the logfiles themselves and remove the need for the explicit logrotate flag file
 - more configuration options (logfile/watchfile locations, etc)

