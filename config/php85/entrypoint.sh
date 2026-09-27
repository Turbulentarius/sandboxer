#!/bin/sh
set -eu

# Preserve ordinary CLI commands and explicit entrypoint overrides.
if [ "${1:-}" != php-fpm85 ]; then
    exec "$@"
fi

root=/srv/sandboxer
if [ ! -d "$root" ]; then
    echo "PHP application directory is missing or not a directory: $root" >&2
    exit 1
fi
if [ "$(id -u)" != 0 ]; then
    echo "Start the FPM master as root; it drops worker privileges itself." >&2
    exit 1
fi

owner=$(stat -Lc '%u:%g' "$root")
worker=$owner
if [ "${owner%%:*}" = 0 ]; then
    worker="$(id -u nobody):$(id -g nobody)"
fi

# Check access as the worker, without chowning or relaxing mount permissions.
if ! su-exec "$worker" /bin/sh -c '
    set -eu
    cd "$1"
    probe=$(mktemp -d .fpm-write-check.XXXXXX)
    rmdir "$probe"
' sh "$root"; then
    echo "Non-root PHP workers ($worker) cannot write to $root (owner $owner)." >&2
    echo "Check mount access and ownership; no application permissions were changed." >&2
    echo "UID 0 may represent an unprivileged host user under user namespaces, but this configuration requires non-root container workers." >&2
    exit 1
fi

printf '[www]\nuser = %s\ngroup = %s\n' "${worker%%:*}" "${worker#*:}" \
    > /etc/php85/php-fpm.d/zz-sandboxer-user.conf

echo "Starting PHP-FPM with non-root workers $worker (mount owner $owner)."
exec "$@"
