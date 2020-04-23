#!/bin/bash
sed -i 's/--listen=127.0.0.1/--listen=0.0.0.0/g' /etc/systemd/system/greenbone-security-assistant.service
sed -i "s/--mport=9390/--mport=9390 --allow-header-host $INT_IP/g" /etc/systemd/system/greenbone-security-assistant.service
sed -i 's/--listen=127.0.0.1/--listen=0.0.0.0/g' /lib/systemd/system/greenbone-security-assistant.service
sed -i 's/GSA_ADDRESS=127.0.0.1/GSA_ADDRESS=0.0.0.0/g' /etc/default/greenbone-security-assistant

echo "Starting Redis ..."
# Making sure the needed directory is available
mkdir -p /var/run/redis-openvas/
redis-server /etc/redis/redis-openvas.conf

# Make sure everything is set up front.
# Takes time, but its the safer way and we dont bother the image building with it.
# Probably does not take too long, when it happened alreay and the files are saved
# on the docker volume.
#openvas-start
#openvas-setup
#openvas-scaptdata-sync
#openvas-certdata-sync
#openvas-check-setup
#openvas-stop
echo "Creating user ..."
openvasmd --create-user amadmin
openvasmd --user=amadmin --new-password=27d55284-90c8-4cc6-9a3e-01763bdab69a
openvas-start

# Insert Config for scan without bruteforce to openvas
/root/run-OpenVASinsertConf.sh
