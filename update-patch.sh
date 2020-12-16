#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

# Set the nameserver temporarily
cp /var/lib/box4s/resolv.personal /etc/resolv.conf

# Create an suricata index of the current month. score calculation will fail without an existing index.
curl -sLkX PUT localhost:9200/suricata-$(date +%Y.%m) > /dev/null

# Erstelle initialen VulnWhisperer Index
curl -XPUT "localhost:9200/logstash-vulnwhisperer-$(date +%Y.%m)"

echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# remove stopped containers on update
sudo docker rm  $(sudo docker ps -q -a) || :
# Remove all images, that are on the target system on every update
sudo docker rmi $(sudo docker images -a -q) || :

###################
# CHANGES FOR STANDARD
# Fix miss setting of $INT_IP in logstash with quotes
source /etc/environment
sed -i "s/INT_IP=\"$INT_IP\"/INT_IP=$INT_IP/g" /etc/environment
sed -i "s/INT_IP=\"$INT_IP\"/INT_IP=$INT_IP/g" /etc/default/logstash
sudo chmod 770 -R /etc/nginx/certs
sudo chown root:44269 -R /etc/nginx/certs

# Fix SMTP permission
sudo chown root:44269 /etc/msmtprc
sudo chmod 770 /etc/msmtprc

# Fix DNS resolv permission
sudo chown root:44269 /var/lib/box4s/resolv.personal
sudo chmod 770 /var/lib/box4s/resolv.personal

#install program for deleting data
sudo apt update
sudo apt install -y secure-delete
###################
# CHANGES FOR MODULES


###################
echo "### Detecting available memory and distribute it to the containers"
# Detect rounded memory
MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM=$(python3 -c "print($MEM/1024.0**2)")
# Give half of that to elasticsearch
ESMEM=$(python3 -c "print(int($MEM*0.5))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${ESMEM}g -Xmx${ESMEM}g/g" /home/amadmin/box4security/docker/elasticsearch/.env.es
# and one quarter to logstash
LSMEM=$(python3 -c "print(int($MEM*0.25))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${LSMEM}g -Xmx${LSMEM}g/g" /home/amadmin/box4security/docker/logstash/.env.ls

# Get the current images
sudo docker-compose -f /home/amadmin/box4security/docker/box4security.yml pull
sudo docker-compose -f /home/amadmin/box4security/docker/wazuh/wazuh.yml pull

# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4security/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4security/scripts/System_Scripts/wait-for-healthy-container.sh logstash || sleep 30
sudo /home/amadmin/box4security/scripts/System_Scripts/wait-for-healthy-container.sh kibana || sleep 30
sleep 20
sudo /home/amadmin/box4security/scripts/System_Scripts/wait-for-healthy-container.sh kibana || sleep 30
sudo /home/amadmin/box4security/scripts/System_Scripts/wait-for-healthy-container.sh nginx || sleep 30

# Copy folder that holds local copy of Stylesheets incase it was not inserted with static volume
sudo docker cp /home/amadmin/box4security/docker/web/source/static/external web:/home/app/web/source/static/external

# Import Dashboard
echo "### Install dashboards"
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/Startseite/Startseite-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/SIEM/SIEM-Alarme.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/SIEM/SIEM-ASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/SIEM/SIEM-DNS.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/SIEM/SIEM-HTTP.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/SIEM/SIEM-ProtokolleUndDienste.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/SIEM/SIEM-SocialMedia.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/SIEM/SIEM-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/Netzwerk/Netzwerk-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/Netzwerk/Netzwerk-GeoIPUndASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/Netzwerk/Netzwerk-Datenfluesse.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/Schwachstellen/Schwachstellen-Details.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/Schwachstellen/Schwachstellen-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/System/docker.ndjson

# Installiere Suricata Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/Patterns/suricata.ndjson
# Installiere Scores Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4security/config/dashboards/Patterns/scores.ndjson
# Update Score Mapping
curl -s -H "Content-type: application/json" -X PUT http://localhost:9200/scores/_mapping --data-binary @$DIR/res/index_mapping.json

# Set the BOX4security nameserver
echo "nameserver 127.0.0.1" > /etc/resolv.conf

# Insert Suricata Rules after Update - this also updates the self inserted suricata rules
sudo docker exec suricata /root/scripts/update.sh || sleep 1
