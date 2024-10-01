FROM alpine:3.20.1
RUN apk add --no-cache \
        shadow \
        bash

COPY ./config/install-scripts/phpmyadmin.sh /phpmyadmin.sh
COPY ./config/host/phpMyAdmin/config.inc.php /

# Make the script executable
RUN chmod +x /phpmyadmin.sh