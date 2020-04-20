#!/bin/bash
echo "Starting redis ..."
redis-server /etc/redis/redis-openvas.conf

echo "Starting openvas ..."
service openvas-scanner start
service openvas-manager start
service greenbone-security-assistant start

echo "Reloading NVTs ..."
openvasmd --rebuild
