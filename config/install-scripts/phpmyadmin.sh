#!/usr/bin/env bash

if [ -f "/srv/sandboxer/setup-completed" ]; then
    echo "Setup not requested... Exiting setup..."
    exit 0
fi

echo "Running setup..."
cd /
wget https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
unzip -d /srv/sandboxer phpMyAdmin-5.2.1-all-languages.zip
mv /srv/sandboxer/phpMyAdmin-5.2.1-all-languages /srv/sandboxer/phpmyadmin
mv /config.inc.php /srv/sandboxer/phpmyadmin
touch /srv/sandboxer/setup-completed
echo "Setup complete."
cd /srv/sandboxer
