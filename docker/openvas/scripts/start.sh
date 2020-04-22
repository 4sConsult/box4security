#!/bin/bash
echo "Making sure the environment fits ..."
sed -i 's/--listen=127.0.0.1/--listen=0.0.0.0/g' /lib/systemd/system/openvas-manager.service
sed -i 's/--listen=127.0.0.1/--listen=0.0.0.0/g' /lib/systemd/system/greenbone-security-assistant.service

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
