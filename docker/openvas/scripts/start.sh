#!/bin/bash
systemctl daemon-reload

echo "Starting Redis ..."
# Making sure the needed directory is available
mkdir -p /var/run/redis-openvas/
redis-server /etc/redis/redis-openvas.conf

echo "Starting OpenVAS ..."
systemctl start greenbone-security-assistant
systemctl start openvas-scanner
systemctl start openvas-manager

echo "Checking setup ..."
openvas-check-setup

echo "Reloading NVTs ..."
openvasmd --rebuild
