#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

#########################
# Updates hier einfügen #

# Stop des Services
echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull

#########################

# Create the new Docker Volume
sudo mkdir -p /var/lib/openvas
sudo chown root:root /var/lib/openvas
sudo chmod -R 777 /var/lib/openvas
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/openvas/ --opt o=bind varlib_openvas


########################

# Install FetchQC Dependencies as Python3
# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
# Update Suricata
sudo docker exec suricata /root/scripts/update.sh
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh logstash
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh nginx
