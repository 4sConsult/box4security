#!/bin/bash
echo "Starting openvas ..."
service openvas-scanner start
service openvas-manager start
service greenbone-security-assistant start

echo "Reloading NVTs ..."
openvasmd --rebuild
