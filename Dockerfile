FROM debian:stretch

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

# based on: https://github.com/nginxinc/docker-nginx/blob/1eea9f7d082dff426e7923a90138de804038266d/Dockerfile
MAINTAINER Michał "rysiek" Woźniak <rysiek@occrp.org>

#
# which package do we want?
# possible versions: nginx, nginx-light, nginx-full, nginx-extras
# 
# if version is the default -- "nginx" -- the nginx.org package is installed
# otherwise, the Debian-provided package is installed; compare versions here:
# https://wiki.debian.org/Nginx#Recap_of_the_different_modules_in_every_package_.28starting_Squeeze-Backports.29
ARG NGINX_PACKAGE=nginx

# NOTICE: Debian-provided packages are *older*, so adjust NGINX_VERSION accordingly
#         (as of this writing Debian stretch package version is at 1.10*)
ARG NGINX_VERSION=1.15*

# requirements
RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y ca-certificates inotify-tools gnupg2 lsb-release curl && \
    rm -rf /var/lib/apt/lists/*

# reality check
RUN case $NGINX_PACKAGE in \
    nginx) \
        echo "+-- building with nginx.org package: ${NGINX_PACKAGE}"; \
        apt-key adv --no-tty --keyserver keyserver.ubuntu.com --recv-keys ABF5BD827BD9BF62 && \
        echo "deb http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" >> /etc/apt/sources.list; \
        ;; \
    nginx-light|nginx-full|nginx-extras) \
        echo "+-- building with Debian-provided package: ${NGINX_PACKAGE}"; \
        echo "\n* * * NOTICE: if build fails, make sure NGINX_VERSION is properly adjusted to what is available in Debian repository!\n\n"; \
        ;; \
    *) \
        echo "\n* * * ERROR: unknown nginx package: ${NGINX_PACKAGE}; please use one of: nginx, nginx-light, nginx-full, nginx-extras\n\n"; \
        exit 1; \
        ;; \
    esac

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y "${NGINX_PACKAGE}"="${NGINX_VERSION}" && \
    rm -rf /var/lib/apt/lists/*

# we might need to install some packages, but doing this in the entrypoint doesn't make any sense
ARG INSTALL_PACKAGES
RUN if [ "$INSTALL_PACKAGES" != "" ]; then \
        export DEBIAN_FRONTEND=noninteractive && apt-get update && apt-get install -y \
            $INSTALL_PACKAGES \
            --no-install-recommends && \
        rm -rf /var/lib/apt/lists/* ; \
    fi

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# make sure the log dir exists
RUN mkdir -p /srv/logs/nginx/ && chown www-data:www-data /srv/logs/nginx/

COPY run.sh /run.sh
RUN chmod +x /run.sh

VOLUME ["/var/cache/nginx", "/etc/nginx"]

EXPOSE 80 443
CMD ["/run.sh"]
