#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

#########################

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

# Stop des Services
echo "Stopping BOX4s Service. The BOX4s service will automatically restart after the update is complete. Please wait."
sleep 8
sudo systemctl stop box4security.service

sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull


# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh logstash || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh nginx || sleep 30
# Update Suricata
sudo docker exec suricata /root/scripts/update.sh || sleep 1