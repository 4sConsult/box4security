#!/bin/bash
echo "Starting Redis ..."
# Making sure the needed directory is available
mkdir -p /var/run/redis-openvas/
redis-server /etc/redis/redis-openvas.conf

echo "Starting OpenVAS ..."
service greenbone-security-assistant start
service openvas-scanner start
service openvas-manager start

echo "Checking setup ..."
openvas-check-setup

echo "Reloading NVTs ..."
openvasmd --rebuild
