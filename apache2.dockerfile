FROM alpine:3.20.1
RUN apk add --no-cache \
        shadow \
        apache2 \
        apache2-proxy \
        apache2-webdav \
        apache-mod-fcgid \
        bash


COPY ./config/apache2/conf.d/sandboxer.conf /etc/apache2/conf.d/sandboxer.conf
COPY ./config/apache2/conf.d/phpmyadmin.conf /etc/apache2/conf.d/phpmyadmin.conf
COPY ./config/apache2/httpd.conf /etc/apache2/httpd.conf

RUN mkdir /srv/sandboxer
WORKDIR /srv/sandboxer

# Ensure Apache runs in the foreground
CMD ["httpd", "-D", "FOREGROUND"]