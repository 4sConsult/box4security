#!/bin/bash
echo "Starting redis ..."
redis-server /etc/redis/redis.conf

echo "Testing redis status ..."
X="$(redis-cli ping)"
while  [ "${X}" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli ping)"
done

echo "Starting openvas ..."
systemctl restart openvas-scanner
systemctl restart openvas-manager
systemctl restart greenbone-security-assistant

echo "Reloading NVTs ..."
openvasmd --rebuild
