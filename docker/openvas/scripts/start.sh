#!/bin/bash
sed -i 's/--listen=127.0.0.1/--listen=0.0.0.0/g' /etc/systemd/system/greenbone-security-assistant.service
sed -i "s/--mport=9390/--mport=9390 --allow-header-host $INT_IP/g" /etc/systemd/system/greenbone-security-assistant.service
sed -i 's/--listen=127.0.0.1/--listen=0.0.0.0/g' /lib/systemd/system/greenbone-security-assistant.service
sed -i 's/GSA_ADDRESS=127.0.0.1/GSA_ADDRESS=0.0.0.0/g' /etc/default/greenbone-security-assistant

echo "Starting Redis ..."
# Making sure the needed directory is available
mkdir -p /var/run/redis-openvas/
redis-server /etc/redis/redis-openvas.conf

service openvas-manager start
service openvas-scanner start
service greenbone-security-assistant start

# Insert Config for scan without bruteforce to openvas
/root/run-OpenVASinsertConf.sh
