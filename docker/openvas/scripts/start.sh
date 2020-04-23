#!/bin/bash
sed -i 's/--listen=127.0.0.1/--listen=0.0.0.0/g' /etc/systemd/system/greenbone-security-assistant.service
sed -i "s/--mport=9390/--mport=9390 --allow-header-host $INT_IP/g" /etc/systemd/system/greenbone-security-assistant.service
sed -i 's/--listen=127.0.0.1/--listen=0.0.0.0/g' /lib/systemd/system/greenbone-security-assistant.service
sed -i 's/GSA_ADDRESS=127.0.0.1/GSA_ADDRESS=0.0.0.0/g' /etc/default/greenbone-security-assistant

echo "Starting Redis ..."
# Making sure the needed directory is available
mkdir -p /var/run/redis-openvas/
redis-server /etc/redis/redis-openvas.conf

echo "Starting OpenVAS Manager ..."
/usr/sbin/openvasmd --create-user amadmin
/usr/sbin/openvasmd --user=amadmin --new-password=27d55284-90c8-4cc6-9a3e-01763bdab69a
/usr/sbin/openvasmd --rebuild --progress
/usr/sbin/openvasmd --listen=127.0.0.1 --port=9390 --database=/var/lib/openvas/mgr/tasks.db

echo "Starting OpenVAS Scanner ..."
/usr/sbin/openvassd --unix-socket=/var/run/openvassd.sock

echo "Starting Greenbone Security Assistant ..."
/usr/sbin/gsad --foreground --listen=0.0.0.0 --port=9392 --mlisten=127.0.0.1 --mport=9390 --no-redirect --allow-header-host $INT_IP
