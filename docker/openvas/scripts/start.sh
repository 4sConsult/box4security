#!/bin/bash

while [ true ] ; do
  echo "testing"
  sleep 10
done

service openvas-manager restart
service openvas-scanner restart
service greenbone-security-assistant restart

echo "Reloading NVTs ..."
openvasmd --rebuild
