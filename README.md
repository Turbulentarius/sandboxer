# sandboxer

Basic sandboxing environment for all kinds of experiments. The idea is to mainly use existing images to keep it as simple as possible for new Docker users.


Currently insecure for production and only intended for educational purposes and quick testing + learning Docker, and I wanted it to be very simple to spin up without having to think about file permissions on the host. Etc. Etc.

Run the containers:
```
docker compose up
```

Stop the containers:
```
docker compose stop
```
Or hit `CTRL` + `C` inside your console window.

View your running containers after starting them:
```
docker ps
```

If you need CLI access to the database:

```
docker exec -it sandboxer-db bash
mariadb -uroot -p
```

The `root` password is `superduperroot`.

- To open phpMyAdmin, open `http://database.localhost` in a browser.
- To open the default (localhost) website host, open `http://localhost`

Published ports bind to `127.0.0.1` (IPv4 loopback) for access from the Docker host.
For a database client on the host, connect to `127.0.0.1:3306`; containers continue
to use `db:3306`. Access from another device requires an intentional change to
the port bindings and a review of the development credentials.

After changing port bindings, run `docker compose up -d` to recreate affected
containers. `docker compose restart` does not apply Compose configuration changes.
Use `docker compose ps` to confirm published ports show `127.0.0.1`.

> [!WARNING]  
> **Do NOT use this for deployment on production!**
>
> Local-only port bindings do not make the development credentials or configuration suitable for production.

## Alpine and PHP

The custom images use Alpine 3.24.2. PHP runs from Alpine's `php85` packages
(PHP 8.5; the patch version follows the Alpine 3.24 package repository).
PHP configuration lives in `config/php85/` and the image definition is
`php8.5-fpm.dockerfile`. OPcache is built into PHP 8.5.

After changing these files, rebuild and check the services:

```bash
docker compose build --pull setup php apache2
docker compose run --rm --no-deps php php -v
docker compose run --rm --no-deps php php-fpm85 -t
docker compose run --rm --no-deps apache2 httpd -t
docker compose up -d php apache2
```

Test your PHP application and phpMyAdmin in the browser after upgrading.
Package availability does not guarantee application compatibility with PHP 8.5.

## MariaDB version

The database uses the official `mariadb:11.4.13` image from the
[11.4 LTS series](https://mariadb.org/about/#maintenance-policy).
Database files persist in `dbdata/`; recreating a container does not reset them.

On first initialization, MariaDB creates the `sandbox` database and grants
`sandboxer` access using the development password `localuserpassword`. These
initialization settings do not change an existing database directory.

When moving from 11.2, test with a fresh data directory if the old data is
unneeded. Stop `db` before moving its data directory aside. If retaining data,
back it up and follow the upstream upgrade instructions before starting the new
version. Do not run an older image against files already upgraded by a newer one.

After preparing the data directory, run:

```bash
docker compose pull db
docker compose up -d --no-deps db
docker compose logs --tail=50 db
docker compose exec db mariadb -uroot -p -e "SELECT VERSION();"
```

Expect version `11.4.13` (possibly with a packaging suffix), then verify database
access through phpMyAdmin at `http://database.localhost`.

## phpMyAdmin setup

The setup service installs phpMyAdmin 5.2.3 only when `www/setup-completed` is absent.
The downloaded ZIP is verified against a pinned SHA-256 checksum before extraction.
Download, checksum, extraction, or configuration errors stop setup without writing that
marker. Temporary installation files are cleaned up on normal exit or failure.
After fixing the cause, retry with `docker compose run --rm setup`.
Rebuild script changes first with `docker compose build setup`.

An existing `www/phpmyadmin` directory without a completion marker is preserved
and setup stops for inspection. Move that directory aside before retrying if
you want a fresh installation. Existing completion markers are still honored;
this change does not repair or upgrade previous installations automatically.

For isolated script checks, `SANDBOXER_ROOT` and `PHPMYADMIN_CONFIG` can override
the destination and configuration source. Their container defaults are
`/srv/sandboxer` and `/config.inc.php`.

## Testing the phpMyAdmin installer

Run the tests after changing the installer or its tests, before committing.
They require Python 3, a POSIX shell, `sha256sum`, and `unzip` on your host. From the
repository root:

```bash
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s tests -v
```

Expect seven tests reporting `ok`, followed by `OK`. They check installation,
checksum verification, failure handling, retries, cleanup, and preservation of existing files.

The tests use temporary directories and a fake download. They are safe to run
with phpMyAdmin installed and do not touch your application or database data.
They are not needed during normal use and do not replace testing the real
installation in Docker.
