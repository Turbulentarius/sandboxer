#!/usr/bin/env bash

# This script is needed to run things after creating the container
# and to install applications into the shared /srv/sandboxer directory, because it is only mounted after creating the container.
# E.g. We cannot do it in the Dockerfile, because it will just be overwritten when the directory is mounted.

# Install phpMyAdmin if needed
bash /phpmyadmin.sh