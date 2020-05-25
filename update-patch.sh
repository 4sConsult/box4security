#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

#########################

# Download and correctly extract GeoIP DB
IP2TOKEN="MyrzO6sxNLvoSEaGtpXoreC1x50bRGmDfNd3UFBIr66jKhZeGXD7cg9Jl9VdQhQ5"
cd /tmp/
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBIN" -o IP2LOCATION-LITE-DB5.BIN.zip
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBINIPV6" -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo unzip -o IP2LOCATION-LITE-DB5.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.BIN
sudo unzip -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.IPV6.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.IPV6.BIN

# Setup Wiki volume
sudo mkdir -p /var/lib/box4s_docs
sudo chown root:root /var/lib/box4s_docs
sudo chmod -R 777 /var/lib/box4s_docs
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s_docs --opt o=bind varlib_docs

# Initially clone the Wiki repo
cd /var/lib/box4s_docs
sudo git clone https://cMeyer:QVXq8i5FxSNEH_YEmze3@gitlab.am-gmbh.de/cmeyer/b4s-docs.git .

# Copy gollum config to wiki root
cp /home/amadmin/box4s/docker/wiki/config.ru /var/lib/box4s_docs/config.ru

#Owner der Skripte zur score Berechnung anpassen
sudo chown -R amadmin:amadmin /home/amadmin/box4s/scripts/Automation/score_calculation/

# Remove old cronjob logfiles
sudo rm -R /var/log/cronchecker
#Make new directory for cronjobchecker
sudo mkdir /var/log/cronchecker
sudo chown amadmin:amadmin /var/log/cronchecker
#Get new root crontabs
cd /home/amadmin/box4s/main/crontab
sudo crontab root.crontab

# Stop des Services
echo "Stopping BOX4s Service. The BOX4s service will automatically restart after the update is complete. Please wait."
sleep 8
sudo systemctl stop box4security.service

# Delete Auditbeat images
# Allow failing
set +e
docker images -a | grep "auditbeat" | awk '{print $3}' | xargs docker rmi
set -e

sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull


# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh logstash || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh nginx || sleep 30

# Apply new vuln-progress dashboard
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson

# Update Suricata
sudo docker exec suricata /root/scripts/update.sh || sleep 1