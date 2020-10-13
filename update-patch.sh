#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

# Making sure to be logged in with the correct account
sudo docker login registry.gitlab.com -u deployment -p B-H-Sg97y3otYdRAjFkQ

sudo apt install -y unattended-upgrades

# Set the nameserver temporarily
cp /var/lib/box4s/resolv.personal /etc/resolv.conf

# Create an suricata index of the current month. score calculation will fail without an existing index.
curl -sLkX PUT localhost:9200/suricata-$(date +%Y.%m) > /dev/null

# Delete Findings of outdated, local openvas version
curl -slKX POST "localhost:9200/logstash-vulnwhisperer-*/_delete_by_query?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "nvt_oid": "1.3.6.1.4.1.25623.1.0.108560"
    }
  }
}
' > /dev/null
# Delete Findings of outdated openvas feed
curl -sLkX POST "localhost:9200/logstash-vulnwhisperer-*/_delete_by_query?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "nvt_oid": "1.3.6.1.4.1.25623.1.0.108560"
    }
  }
}
' > /dev/null

echo "Erstelle Datenbank Backup"
source /home/amadmin/box4s/config/secrets/db.conf
sudo docker exec db /bin/bash -c "PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER pg_dump -F tar box4S_db > /root/box4S_db.tar"
sudo docker cp db:/root/box4S_db.tar /var/lib/box4s/backup/box4S_db_1.8.8.tar

echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# remove stopped containers on update
sudo docker rm  $(docker ps -q -a) || :
# Remove all images, that are on the target system on every update
sudo docker rmi $(sudo docker images -a -q) || :

###################
# Changes here for standard module

#Disable TCP Timestamps
echo 'net.ipv4.tcp_timestamps = 0' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p


# Creating BOX4s openvas docker volume
sudo mkdir -p /var/lib/box4s_openvas/
sudo chown root:root /var/lib/box4s_openvas/
sudo chmod -R 777 /var/lib/box4s_openvas/
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s_openvas/ --opt o=bind gvm-data
sudo chown -R root:root /var/lib/box4s_openvas

# Remove previous openvas volume
sudo docker volume rm varlib_openvas
sudo rm -r /var/lib/openvas/

# Remove suricata volume
sudo docker volume rm varlib_suricata
sudo rm -r /var/lib/suricata/

# Create new suricata volume and folders
sudo mkdir -p /var/lib/box4s_suricata_rules/
sudo chown root:root /var/lib/box4s_suricata_rules/
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s_suricata_rules/ --opt o=bind varlib_suricata

###################

echo "### Detecting available memory and distribute it to the containers"
# Detect rounded memory
MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM=$(python3 -c "print($MEM/1024.0**2)")
# Give half of that to elasticsearch
ESMEM=$(python3 -c "print(int($MEM*0.5))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${ESMEM}g -Xmx${ESMEM}g/g" /home/amadmin/box4s/docker/elasticsearch/.env.es
# and one quarter to logstash
LSMEM=$(python3 -c "print(int($MEM*0.25))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${LSMEM}g -Xmx${LSMEM}g/g" /home/amadmin/box4s/docker/logstash/.env.ls

# Get the current images
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull
sudo docker-compose -f /home/amadmin/box4s/docker/wazuh/wazuh.yml pull

###################
# PostgreSQL 12-to-13 migration
source /home/amadmin/box4s/config/secrets/db.conf
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml up -d db
sleep 10
sudo docker cp /var/lib/box4s/backup/box4S_db_1.8.8.tar db:/root/box4S_db.tar
sudo docker exec db /bin/bash -c "PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER pg_restore -F t --clean -d box4S_db /root/box4S_db.tar"
sudo rm /var/lib/box4s/backup/box4S_db_1.8.8.tar

# Changes for Wazuh module
# Source modules configuration
source /etc/box4s/modules.conf

# Start Wazuh module and wait for it to become available
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml up -d
sudo docker-compose -f /home/amadmin/box4s/docker/wazuh/wazuh.yml up -d 
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh wazuh
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch

# Insert Wazuh template for Version 3.13.1 that allows kibana 7.9.0
curl https://raw.githubusercontent.com/wazuh/wazuh/v3.13.1/extensions/elasticsearch/7.x/wazuh-template.json | curl -X PUT "http://localhost:9200/_template/wazuh" -H 'Content-Type: application/json' -d @-

#Shutdown wazuh container if module not enabled

if [ "$BOX4s_WAZUH" == "false" ]; then
  sudo docker-compose -f /home/amadmin/box4s/docker/wazuh/wazuh.yml stop
fi

###################


# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh logstash || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana || sleep 30
sleep 20
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh nginx || sleep 30

# Copy folder that holds local copy of Stylesheets incase it was not inserted with static volume
sudo docker cp /home/amadmin/box4s/docker/web/source/static/external web:/home/app/web/source/static/external


# Import Dashboard
echo "### Install dashboards"
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Startseite/Startseite-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-Alarme.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-ASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-DNS.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-HTTP.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-ProtokolleUndDienste.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-SocialMedia.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Netzwerk/Netzwerk-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Netzwerk/Netzwerk-GeoIPUndASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Netzwerk/Netzwerk-Datenfluesse.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Schwachstellen/Schwachstellen-Details.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Schwachstellen/Schwachstellen-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/System/docker.ndjson

# Installiere Suricata Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Patterns/suricata.ndjson
# Installiere Scores Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Patterns/scores.ndjson

# Insert Suricata Rules after Update - this also updates the self inserted suricata rules
sudo docker exec suricata /root/scripts/update.sh

# Update Score Mapping
curl -s -H "Content-type: application/json" -X PUT http://localhost:9200/scores/_mapping --data-binary @$DIR/res/index_mapping.json

# Erstelle initialen VulnWhisperer Index
curl -XPUT "localhost:9200/logstash-vulnwhisperer-$(date +%Y.%m)"
