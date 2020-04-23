#!/bin/bash
# PLATZHALTER LOG_FILE
# PLAZHALTER BRANCH
#
#
function testNet() {
  # Returns 0 for successful internet connection and dns resolution, 1 else
  ping -q -c 1 -W 1 $1 >/dev/null;
  return $?
}

function waitForNet() {
  # use argument or default value of google.com
  HOST=${1:-"google.com"}
  while ! testNet $HOST; do
    # while testNet returns non zero value
    echo "No internet connectivity or dns resolution of $HOST, sleeping for 15s"
    sleep 15s
  done
}

if [ "$BRANCH" != "" ]; then
  TAG=$BRANCH
elif [ "$1" != "" ]; then
  TAG=$1
fi
if [[ ! -w $LOG_FILE ]]; then
  LOG_FILE="/home/amadmin/installScript.log"
fi
# Redirect STDOUT to LOG_FILE
exec 1>>$LOG_FILE && exec 2>&1
waitForNet
pip3 install semver
apt install -y python3-venv unzip

sudo systemctl stop irqbalance
sudo systemctl disable irqbalance

# Portmirror Interface für Suricata auslesen
touch /home/amadmin/box4s/docker/suricata/.env
#Add Int IP
echo "Initialisiere Systemvariablen"
echo
echo
IPINFO=$(ip a | grep -E "inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "host lo")
IPINFO2=$(echo $IPINFO | awk  '{print substr($IPINFO, 6, length($IPINFO))}')
INT_IP=$(echo $IPINFO2 | sed 's/\/.*//')
echo INT_IP="$INT_IP" | sudo tee -a /etc/default/logstash /etc/environment
source /etc/environment

IFACE=$(sudo ip addr | cut -d ' ' -f2 | tr ':' '\n' | awk NF | grep -v lo | sed -n 2p | cat)
echo "SURI_INTERFACE=$IFACE" > /home/amadmin/box4s/docker/suricata/.env

# Service für automatische VPN-Verbindung einfügen
sudo pkill -f openconnect # Send CTRL+C signal to all openconnect

waitForNet
sudo apt install -y resolvconf

# DNSMASQ Setup
sudo systemctl disable systemd-resolved

# How to set a dns server in ubuntu 19.10 ;)
sudo systemctl enable resolvconf
echo "nameserver 127.0.0.1" > /etc/resolvconf/resolv.conf.d/head

sudo cp /home/amadmin/box4s/main/etc/systemd/vpn.service /etc/systemd/system/vpn.service
sudo systemctl daemon-reload
sudo systemctl enable vpn.service
sudo systemctl start vpn.service

# Kopiere den neuen Service an die richtige Stelle und enable den Service
sudo cp /home/amadmin/box4s/main/etc/systemd/box4security.service /etc/systemd/system/box4security.service
sudo systemctl daemon-reload
sudo systemctl enable box4security.service

# Sleep 5s to make sure the vpn is established
sleep 5

waitForNet "gitlab.am-gmbh.de"
# Login bei der Docker-Registry des GitLabs und Download der Container
waitForNet docker-registry.am-gmbh.de
sudo docker login docker-registry.am-gmbh.de -u deployment-token-box -p KPLm6mZJFzuA9QY9oCZC

# Erstelle das Volume für die Daten
sudo docker volume create --driver local --opt type=none --opt device=/data --opt o=bind data

# Erstelle Volumes für Suricata
sudo mkdir -p /var/lib/suricata
sudo chown root:root /var/lib/suricata
sudo chmod -R 777 /var/lib/suricata
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/suricata/ --opt o=bind varlib_suricata

# Erstelle Volume für BOX4s Anwendungsdaten (/var/lib/box4s)
sudo mkdir -p /var/lib/box4s
sudo chown root:root /var/lib/box4s
sudo chmod -R 777 /var/lib/box4s
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s/ --opt o=bind varlib_box4s

# Erstelle Volume für PostgreSQL
sudo mkdir -p /var/lib/postgresql/data
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/postgresql/data --opt o=bind varlib_postgresql

# Erstelle Voume für dynamische Box4s Konfigurationen
sudo mkdir -p /etc/box4s/logstash
sudo cp -R /home/amadmin/box4s/main/etc/logstash/* /etc/box4s/logstash/
sudo chown root:root /etc/box4s/
sudo chmod -R 777 /etc/box4s/
sudo docker volume create --driver local --opt type=none --opt device=/etc/box4s/logstash/ --opt o=bind etcbox4s_logstash

# Erstelle Volume für Logstash
sudo mkdir /var/lib/logstash
sudo chown root:root /var/lib/logstash
sudo chmod -R 777 /var/lib/logstash
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/logstash/ --opt o=bind varlib_logstash

# Create BOX4s Log Path
sudo mkdir -p /var/log/box4s/
sudo touch /var/log/box4s/update.log

# Download IP2Location DBs for the first time
# IP2LOCATION Token
IP2TOKEN="MyrzO6sxNLvoSEaGtpXoreC1x50bRGmDfNd3UFBIr66jKhZeGXD7cg9Jl9VdQhQ5"
cd /tmp/
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBIN" -o IP2LOCATION-LITE-DB5.BIN.zip
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBINIPV6" -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo unzip -o IP2LOCATION-LITE-DB5.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.BIN
sudo unzip -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.IPV6.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.IPV6.BIN

# Filter Functionality
# create files
sudo touch /var/lib/box4s/15_logstash_suppress.conf
sudo touch /var/lib/box4s/suricata_suppress.bpf
sudo chmod -R 777 /var/lib/box4s/
# rm old links
sudo rm -f /etc/logstash/conf.d/suricata/15_kibana_filter.conf

# Install postgresql client to interact with db
sudo apt-get install -y postgresql-client

# Ermittle ganzzahligen RAM in GB (abgerundet)
MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM=$(python -c "print($MEM/1024.0**2)")
# Die Häfte davon soll Elasticsearch zur Verfügung stehen, abgerundet
ESMEM=$(python -c "print(int($MEM*0.5))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${ESMEM}g -Xmx${ESMEM}g/g" /home/amadmin/box4s/docker/.env.es
# 1/4 davon für Logstash, abgerundet
LSMEM=$(python -c "print(int($MEM*0.25))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${LSMEM}g -Xmx${LSMEM}g/g" /home/amadmin/box4s/docker/.env.ls

# Pull die Images
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull
sudo systemctl stop systemd-resolved
sudo systemctl start resolvconf
sudo cp /home/amadmin/box4s/docker/dnsmasq/resolv.personal /var/lib/box4s/resolv.personal

# Starte den Dienst
sudo systemctl start box4security

# Erlaube Scripts
chmod +x -R $BASEDIR$GITDIR/scripts

#Installation Dashboards
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sleep 20
# Install the scores index
cd /home/amadmin/box4s/scripts/Automation/score_calculation/
./install_index.sh
cd /home/amadmin/box4s

# Update Suricata
sudo docker exec suricata /root/scripts/update.sh

# Update OpenVAS
sudo docker exec openvas /root/update.sh

sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh db
echo "Installing FetchQC"
cd /home/amadmin/box4s
cd FetchQC
pip install -r requirements.txt
alembic upgrade head # Prepare DB

echo "Install Crontab"
cd /home/amadmin/box4s/main/crontab
su - amadmin -c "crontab /home/amadmin/box4s/main/crontab/amadmin.crontab"
sudo crontab root.crontab

source /etc/environment
echo KUNDE="NEWSYSTEM" | sudo tee -a /etc/default/logstash
# Set INT-IP as --allow-header-host
sed -ie "s/--allow-header-host [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/--allow-header-host $INT_IP/g" /etc/systemd/system/greenbone-security-assistant.service
sudo systemctl daemon-reload

#Ignore own INT_IP
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('"$INT_IP"',0,'0.0.0.0',0,'');" | PGPASSWORD=zgJnwauCAsHrR6JB PGUSER=postgres psql postgres://localhost/box4S_db
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('0.0.0.0',0,'"$INT_IP"',0,'');" | PGPASSWORD=zgJnwauCAsHrR6JB PGUSER=postgres psql postgres://localhost/box4S_db

echo "Installiere Elastic Curator"
waitForNet
pip3 install elasticsearch-curator --user

sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana
#wait for 6 minutes and 40 seconds until kibana and wazuh have started to insert patterns
sleep 400
# Import Dashboard
echo "Installiere Dashboards"
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Startseite/Startseite-Uebersicht.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-Alarme.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-ASN.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-DNS.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-HTTP.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-ProtokolleUndDienste.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-SocialMedia.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-Uebersicht.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-Uebersicht.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-GeoIPUndASN.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-Datenfluesse.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Details.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Uebersicht.ndjson

# Installiere Suricata Index Pattern
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Patterns/suricata.ndjson

#sudo systemctl restart networking
echo "BOX4security installiert."

# Lets update both openvas and suricata
sudo docker exec suricata /root/scripts/update.sh > /dev/null
sudo docker exec openvas /root/update.sh > /dev/null
