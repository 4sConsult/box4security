#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

#########################

# Download and correctly extract GeoIP DB

# Stop des Services
echo "Stopping BOX4s Service. The BOX4s service will automatically restart after the update is complete. Please wait."
sleep 8
sudo systemctl stop box4security.service

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