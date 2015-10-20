FROM debian:jessie

#    Watchful NGinX container -- nginx docker container that watches for
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
#MAINTAINER NGINX Docker Maintainers "docker-maint@nginx.com"
MAINTAINER Michał "rysiek" Woźniak <rysiek@occrp.org>

RUN apt-key adv --keyserver hkp://pgp.mit.edu:80 --recv-keys 573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
RUN echo "deb http://nginx.org/packages/mainline/debian/ jessie nginx" >> /etc/apt/sources.list

# yeah, we'll pin on this
ENV NGINX_VERSION 1.9*

RUN DEBIAN_FRONTEND=noninteractive apt-get update && \
    apt-get install -y ca-certificates nginx="${NGINX_VERSION}" inotify-tools && \
    rm -rf /var/lib/apt/lists/*

# forward request and error logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log
RUN ln -sf /dev/stderr /var/log/nginx/error.log

# make sure the log dir exists
RUN mkdir -p /srv/logs/nginx/ && chown www-data:www-data /srv/logs/nginx/

COPY run.sh /run.sh
RUN chmod +x /run.sh

VOLUME ["/var/cache/nginx"]

EXPOSE 80 443
#CMD ["nginx", "-g", "daemon off;"]
CMD ["/run.sh"]