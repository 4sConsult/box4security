#!/bin/bash
echo "Starting Redis ..."
# Making sure the needed directory is available
mkdir -p /var/run/redis-openvas/
redis-server /etc/redis/redis-openvas.conf

echo "Setting VulnWhisperer Authentication"
# Add OpenVAS Authentication to vulnwhisperer
sed -i "s/username=.*/username=$OPENVAS_USER/g" /etc/vulnwhisperer/vulnwhisperer.ini
sed -i "s/password=.*/password=$OPENVAS_PASS/g" /etc/vulnwhisperer/vulnwhisperer.ini

echo "Starting OpenVAS Manager ..."
/usr/sbin/openvasmd --create-user amadmin
/usr/sbin/openvasmd --user=$OPENVAS_USER --new-password=$OPENVAS_PASS
/usr/sbin/openvasmd --rebuild --progress
/usr/sbin/openvasmd --listen=127.0.0.1 --port=9390 --database=/var/lib/openvas/mgr/tasks.db

echo "Inserting 4sConsult config ..."
chmod +x /root/insertconfig.sh
/root/insertconfig.sh

echo "Starting OpenVAS Scanner ..."
/usr/sbin/openvassd --unix-socket=/var/run/openvassd.sock

echo "Starting Greenbone Security Assistant ..."
mkdir -p /usr/share/openvas/gsa/locale
/usr/sbin/gsad --foreground --listen=0.0.0.0 --port=9392 --mlisten=127.0.0.1 --mport=9390 --no-redirect --allow-header-host $INT_IP
