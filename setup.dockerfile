FROM alpine:3.24.2 AS setup-base
RUN apk add --no-cache \
        shadow bash \
        php85 php85-ctype php85-curl php85-dom php85-fileinfo \
        php85-mbstring php85-openssl php85-pdo_sqlite php85-session \
        php85-tokenizer php85-xml php85-xmlwriter php85-phar php85-zip \
        php85-pcntl php85-posix

# Build the example once; first-run setup needs no Composer or Laravel download.
FROM setup-base AS laravel-template
RUN apk add --no-cache curl unzip
RUN curl -fsSLo /usr/local/bin/composer https://getcomposer.org/download/2.10.3/composer.phar && \
    echo '7a2d379d5b8ffdaa028580ef26494c36d2feef4b178d3dd1473a4dbc5e17c8d6  /usr/local/bin/composer' | sha256sum -c -
# Official laravel/laravel skeleton v13.10.1; update hash and dependency lock together.
RUN curl -fsSLo /tmp/laravel.zip https://codeload.github.com/laravel/laravel/zip/refs/tags/v13.10.1 && \
    echo '0369aaebb8083eaa0a1763a6ae44248fa04d1fd15de9124f186cd962e0f84caa  /tmp/laravel.zip' | sha256sum -c - && \
    unzip -q /tmp/laravel.zip -d /opt && \
    mv /opt/laravel-13.10.1 /opt/laravel && rm /tmp/laravel.zip
WORKDIR /opt/laravel
COPY ./config/laravel/composer.lock ./composer.lock
RUN COMPOSER_ALLOW_SUPERUSER=1 php85 /usr/local/bin/composer install \
    --prefer-dist --no-interaction --no-progress --no-scripts --no-plugins && \
    php85 /usr/local/bin/composer check-platform-reqs
COPY ./config/laravel/vite.config.js ./vite.config.js

FROM setup-base
COPY --from=laravel-template /opt/laravel /opt/laravel
COPY ./config/install-scripts/phpmyadmin.sh /phpmyadmin.sh
COPY ./config/install-scripts/laravel.sh /laravel.sh
COPY ./config/install-scripts/setup.sh /setup.sh
COPY ./config/install-scripts/default.sh /default.sh
COPY ./config/host/default/ /opt/default/
COPY ./config/host/phpMyAdmin/config.inc.php /
CMD ["/bin/sh", "/setup.sh"]
