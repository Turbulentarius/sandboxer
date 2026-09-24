#!/bin/sh
set -eu

destination=${SANDBOXER_ROOT:-/srv/sandboxer}
configuration=${PHPMYADMIN_CONFIG:-/config.inc.php}

if [ -f "$destination/setup-completed" ]; then
    echo "Setup not requested... Exiting setup..."
    exit 0
fi

echo "Running setup..."

# Preserve existing installations instead of merging a retry into their files.
if [ -e "$destination/phpmyadmin" ] || [ -L "$destination/phpmyadmin" ]; then
    echo "phpmyadmin exists without a completion marker; inspect it before retrying." >&2
    exit 1
fi

test -f "$configuration"
mkdir -p "$destination"
staging=$(mktemp -d "$destination/.phpmyadmin-setup.XXXXXX")
# Remove temporary files when the shell exits, whether setup succeeds or fails.
trap 'rm -rf "$staging"' EXIT
# On hangup (HUP), Ctrl+C (INT), or a termination request (TERM), exit with
# failure status 1. This also triggers the EXIT cleanup above.
# Forced termination (SIGKILL) or power loss cannot be caught for cleanup.
trap 'exit 1' HUP INT TERM

wget -O "$staging/phpmyadmin.zip" https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip
unzip -q "$staging/phpmyadmin.zip" -d "$staging"
test -f "$staging/phpMyAdmin-5.2.1-all-languages/index.php"
cp "$configuration" "$staging/phpMyAdmin-5.2.1-all-languages/config.inc.php"
mv "$staging/phpMyAdmin-5.2.1-all-languages" "$destination/phpmyadmin"
touch "$destination/setup-completed"
echo "Setup complete."
