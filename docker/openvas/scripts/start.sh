#!/bin/bash
echo "Starting redis ..."
redis-server /etc/openvas/redis-b4s.conf

echo "Testing redis status ..."
X="$(redis-cli ping)"
while  [ "${X}" != "PONG" ]; do
        echo "Redis not yet ready..."
        sleep 1
        X="$(redis-cli ping)"
done

echo "Starting openvas ..."
service openvas-scanner start
service openvas-manager start
service greenbone-security-assistant start

echo "Reloading NVTs ..."
openvasmd --rebuild
