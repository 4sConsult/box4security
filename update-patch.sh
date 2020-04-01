#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

cd /home/amadmin/box4s

# Stoppe den Box4Security Service
echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# Stoppe und deinstalliere Nginx und PostgreSQL
sudo systemctl stop filebeat
sudo systemctl disable filebeat.service
sudo apt remove -y filebeat
sudo apt autoremove -y

# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl start box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh kibana
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh nginx
