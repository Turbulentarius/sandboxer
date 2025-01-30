FROM alpine:3.20.1
RUN apk add --no-cache \
        bash \
        shadow \
        php82 \
        php82-fpm \
        imagemagick \
        imagemagick-pdf \
        imagemagick-jpeg \
        imagemagick-raw \
        imagemagick-tiff \
        imagemagick-heic \
        imagemagick-webp \
        imagemagick-svg

    # PHP Extensions
RUN apk add --no-cache \
        php82-session \
        php82-posix \
        php82-ctype \
        php82-pecl-imagick \
        php82-fileinfo \
        php82-opcache \
        php82-dom \
        php82-xml \
        php82-sodium \
        php82-simplexml \
        php82-curl \
        php82-xmlwriter \
        php82-xmlreader \
        php82-bcmath \
        php82-exif \
        php82-ftp \
        php82-gd \
        php82-gmp \
        php82-intl \
        php82-ldap \
        php82-redis \
        php82-opcache \
        php82-pcntl \
        php82-mysqli \
        php82-pdo_mysql \
        php82-mbstring \
        php82-sysvsem \
        php82-zip

COPY ./config/php82/php-fpm.d/www.conf /etc/php82/php-fpm.d/www.conf
COPY ./config/php82/php.ini /etc/php82/php.ini

RUN mkdir -p /srv/sandboxer && \
    chmod -R 775 /srv/sandboxer

WORKDIR /srv/sandboxer

# Ensure PHP-FPM runs in the foreground
CMD ["php-fpm82", "-R", "-F"]