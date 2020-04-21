#!/bin/bash
echo "Starting Redis ..."
# Making sure the needed directory is available
mkdir -p /var/run/redis-openvas/
redis-server /etc/redis/redis-openvas.conf

echo "Starting OpenVAS ..."
openvas-start

echo "Checking setup ..."
openvas-check-setup

echo "Reloading NVTs ..."
openvasmd --rebuild
