#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

#########################
# Updates hier einfügen #

# Stop des Services
echo "Stopping BOX4s Service. The BOX4s service will automatically retart after the update is complete. Please wait."
sudo systemctl stop box4security.service

sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull


# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
# Update Suricata
sudo docker exec suricata /root/scripts/update.sh
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh logstash || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh nginx || sleep 30
