#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Stoppe und deinstalliere Nginx und PostgreSQL
sudo systemctl stop logstash filebeat metricbeat
sudo systemctl disable logstash filebeat metricbeat
sudo apt remove -y logstash filebeat metricbeat
sudo apt autoremove -y

curl -XDELETE localhost:9200/.kibana
curl -X POST "localhost:9200/_aliases" -H 'Content-Type: application/json' -d'
{
    "actions" : [
        { "add" : { "index" : ".kibana_index_v3nighly_2", "alias" : ".kibana" } }
    ]
}
'

# Install updated Dashboard and Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-Alarme.ndjson

# Stop des Services
echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# Setting memory values
# the new environment files come from updating the repo
# Ermittle ganzzahligen RAM in GB (abgerundet)
MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM=$(python -c "print($MEM/1024.0**2)")
# Die Häfte davon soll Elasticsearch zur Verfügung stehen, abgerundet
ESMEM=$(python -c "print(int($MEM*0.5))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${ESMEM}g -Xmx${ESMEM}g/g" /home/amadmin/box4s/docker/.env.es
# 1/4 davon für Logstash, abgerundet
LSMEM=$(python -c "print(int($MEM*0.25))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${LSMEM}g -Xmx${LSMEM}g/g" /home/amadmin/box4s/docker/.env.ls

# Download IP2Location DBs for the first time
# IP2LOCATION Token
IP2TOKEN="MyrzO6sxNLvoSEaGtpXoreC1x50bRGmDfNd3UFBIr66jKhZeGXD7cg9Jl9VdQhQ5"
cd /tmp/
curl "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBIN" -o IP2LOCATION-LITE-DB5.BIN
curl "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB9LITEBINIPV6" -o IP2LOCATION-LITE-DB5.IPV6.BIN
sudo mv IP2LOCATION-LITE-DB5.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.BIN
sudo mv IP2LOCATION-LITE-DB5.IPV6.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.IPV6.BIN

# Neue Volumes anlegen
sudo chown root:root /var/lib/logstash
sudo chmod -R 777 /var/lib/logstash

sudo mkdir -p /etc/box4s/logstash
sudo chown root:root /etc/box4s/
sudo chmod -R 777 /etc/box4s/

# Volumes in Docker anlegen
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/logstash/ --opt o=bind varlib_logstash
sudo docker volume create --driver local --opt type=none --opt device=/etc/box4s/logstash/ --opt o=bind etcbox4s_logstash

# Kopiere die Logstash-Konfigurationsdateien an den neuen Ort
sudo cp /home/amadmin/box4s/main/etc/logstash/* /etc/box4s/logstash/

# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl start box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh logstash
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh nginx
