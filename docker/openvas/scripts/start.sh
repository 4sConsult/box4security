#!/bin/bash
echo "Starting redis ..."
redis-server /etc/redis/redis-openvas.conf

echo "Testing redis status ..."
while [ ! -f /var/run/redis-openvas/redis-server.sock ]
do
  sleep 1
done

echo "Starting openvas ..."
service openvas-scanner start
service openvas-manager start
service greenbone-security-assistant start

echo "Reloading NVTs ..."
openvasmd --rebuild
