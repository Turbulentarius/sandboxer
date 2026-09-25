#!/bin/sh
set -eu

# Ask an FPM worker to respond; this does not execute an application file.
# Use the same address as the pool listener, which binds to php:9000.
response=$(env -i SCRIPT_NAME=/fpm-ping SCRIPT_FILENAME=/fpm-ping \
    REQUEST_METHOD=GET /usr/bin/cgi-fcgi -bind -connect php:9000)
# FastCGI output includes headers; require the exact ping response body line.
printf '%s\n' "$response" | grep -qx 'pong'
