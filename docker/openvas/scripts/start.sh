#!/bin/bash

while [ true ] ; do
  echo "testing"
  sleep 10
done

echo "Start redis"
redis-server /etc/redis/redis-openvas.conf

service openvas-manager restart
service openvas-scanner restart
service greenbone-security-assistant restart

echo "Reloading NVTs ..."
openvasmd --rebuild
