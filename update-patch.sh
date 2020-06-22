#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# Remove all images, that are on the target system on every update
sudo docker rmi $(sudo docker images -a -q)

# If exists, remove the elastalert example rule
rm -f /var/lib/elastalert/rules/testrule.yaml
# Making sure to be logged in with the correct account
sudo docker login registry.gitlab.com -u deployment -p B-H-Sg97y3otYdRAjFkQ

# Get the current images
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull

# Make sure elasticsearch can write
sudo chmod 777 -R /data/elasticsearch
sudo chmod 777 -R /var/lib/logstash
sudo chmod 777 -R /var/lib/openvas
sudo chmod 777 -R /data/suricata/eve.json

###################
# Changes here
pip install requests

#Download wazuh clients
sudo sh /home/amadmin/box4s/scripts/Automation/download_wazuh_clients.sh 3.12.1

# Remove VPN connection
sudo systemctl stop vpn.service
sudo systemctl disable vpn.service
sudo rm /etc/systemd/system/vpn.service
sudo apt remove --purge openconnect

# Change Box4s repo
# Backup the current environment files ...
sudo mv /home/amadmin/box4s/docker/.env.es /tmp/.env.es
sudo mv /home/amadmin/box4s/docker/.env.ls /tmp/.env.ls

cd /home/amadmin/box4s
VERSION=$(cat VERSION)
VERSION=${VERSION##*=}
sudo git remote -v # show the current configuration
sudo git remote set-url origin https://deploy:mPwNxthpxvmQSaZnv3xZ@gitlab.com/4sconsult/box4s.git
sudo git fetch
sudo git pull
sudo git checkout $VERSION

# ... and put the environment files back where they belong
sudo mv /tmp/.env.es /home/amadmin/box4s/docker/elasticsearch/.env.es
sudo mv /tmp/.env.ls /home/amadmin/box4s/docker/logstash/.env.ls

# Clone the new wiki repo
sudo rm -R /var/lib/box4s_docs/*
sudo rm -R /var/lib/box4s_docs/.git
cd /var/lib/box4s_docs
sudo git clone https://deploy:mPwNxthpxvmQSaZnv3xZ@gitlab.com/4sconsult/docs.git .

###################

# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Use time between service start and health checks to install modified crontab
# Removes -it from docker exec openvas vulnwhisp
sudo crontab /home/amadmin/box4s/main/crontab/root.crontab

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh logstash || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh nginx || sleep 30

curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
