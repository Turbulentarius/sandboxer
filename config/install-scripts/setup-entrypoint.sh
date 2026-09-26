#!/bin/sh
set -eu

root=${SANDBOXER_ROOT:-/srv/sandboxer}
if [ ! -d "$root" ]; then
    echo "Setup application directory is missing or not a directory: $root" >&2
    exit 1
fi

# Use the ownership visible in this container's user namespace, including UID 0.
owner=$(stat -Lc '%u:%g' "$root")
current="$(id -u):$(id -g)"
if [ "$current" != "$owner" ]; then
    if [ "$(id -u)" != 0 ]; then
        echo "Setup runs as $current but needs mount owner $owner; start setup as root." >&2
        exit 1
    fi
    exec su-exec "$owner" /bin/sh "$0" "$@"
fi

# A real write detects read-only mounts and sharing restrictions, even for UID 0.
if ! probe=$(mktemp -d "$root/.setup-write-check.XXXXXX"); then
    echo "Setup cannot write to $root as $owner; check bind-mount access." >&2
    exit 1
fi
rmdir "$probe"

echo "Running application setup as mount owner $owner."
exec "$@"
