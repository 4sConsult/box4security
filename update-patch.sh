#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Install FetchQC Dependencies as Python3
cd /home/amadmin/box4s/FetchQC
pip3 install -r requirements.txt

# Install Postgres Client
sudo apt install -y postgresql-client

# Start des Services
echo "Restarting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh kibana
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh nginx
