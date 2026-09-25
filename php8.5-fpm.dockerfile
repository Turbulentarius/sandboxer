FROM alpine:3.24.2
RUN apk add --no-cache \
        bash \
        shadow \
        curl \
        php85 \
        php85-fpm \
        sqlite \
        php85-pdo_sqlite \
        imagemagick \
        imagemagick-pdf \
        imagemagick-jpeg \
        imagemagick-raw \
        imagemagick-tiff \
        imagemagick-heic \
        imagemagick-webp \
        imagemagick-svg

# PHP extensions (OPcache is built into PHP 8.5).
RUN apk add --no-cache \
        php85-session \
        php85-posix \
        php85-ctype \
        php85-pecl-imagick \
        php85-fileinfo \
        php85-dom \
        php85-xml \
        php85-sodium \
        php85-simplexml \
        php85-curl \
        php85-xmlwriter \
        php85-xmlreader \
        php85-bcmath \
        php85-exif \
        php85-ftp \
        php85-gd \
        php85-gmp \
        php85-intl \
        php85-ldap \
        php85-pecl-redis \
        php85-pcntl \
        php85-mysqli \
        php85-pdo_mysql \
        php85-mbstring \
        php85-sysvsem \
        php85-zip \
        php85-phar \
        php85-openssl \
        php85-tokenizer

COPY ./config/php85/php-fpm.d/www.conf /etc/php85/php-fpm.d/www.conf
COPY ./config/php85/php.ini /etc/php85/php.ini

RUN mkdir -p /srv/sandboxer && \
    chmod -R 775 /srv/sandboxer

WORKDIR /srv/sandboxer

RUN curl -sS https://getcomposer.org/installer | php85 -- --install-dir=/usr/local/bin --filename=composer

# Ensure PHP-FPM runs in the foreground
CMD ["php-fpm85", "-R", "-F"]
