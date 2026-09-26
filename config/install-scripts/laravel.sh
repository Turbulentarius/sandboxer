#!/bin/sh
set -eu

root=${SANDBOXER_ROOT:-/srv/sandboxer}
template=${LARAVEL_TEMPLATE:-/opt/laravel}
target="$root/laravel"

# An existing app belongs to the developer: never reinstall or migrate it.
if [ -e "$target" ] || [ -L "$target" ]; then
    echo "Laravel destination already exists; leaving it unchanged."
    exit 0
fi

test -f "$template/artisan"
test -f "$template/vendor/autoload.php"
mkdir -p "$root"
staging=$(mktemp -d "$root/.laravel-setup.XXXXXX")
trap 'rm -rf "$staging"' EXIT
trap 'exit 1' HUP INT TERM

mkdir "$staging/app"
cp -R "$template/." "$staging/app/"
cd "$staging/app"
cp .env.example .env
sed -i 's|^APP_URL=.*|APP_URL=http://laravel.localhost|' .env
php85 artisan package:discover --no-interaction
php85 artisan key:generate --force --no-interaction
touch database/database.sqlite
php85 artisan migrate --force --no-interaction

# Publish only a fully initialized app, never merge into an existing directory.
if [ -e "$target" ] || [ -L "$target" ]; then
    echo "Laravel destination appeared during setup; refusing to replace it." >&2
    exit 1
fi
mv -T "$staging/app" "$target"
echo "Laravel example installed at http://laravel.localhost."
