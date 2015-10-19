# Watchful NginX

Watchful NGinX container -- an `nginx` docker container that watches for logrotated logfiles using `inotify` and makes sure nginx reloads them when needed.

A nasty, but functional, kludge of a work-around for [lack of PID namespaces in docker](https://github.com/docker/docker/issues/10163).
