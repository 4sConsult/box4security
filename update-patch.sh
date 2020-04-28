#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

#########################
# Updates hier einfügen #

# Force remove FetchQC alembic in favor of Web App alembic
PGPASSWORD=zgJnwauCAsHrR6JB psql -h localhost -U postgres box4S_db -c "DROP TABLE alembic_version;"

# Delete old index with possibly wrong data. Lets start clean!
cd /home/amadmin/box4s/scripts/Automation/score_calculation/
./install_index.sh
cd ~/box4s/

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

# Update Cronjobs
cd /home/amadmin/box4s/main/crontab
su - amadmin -c "crontab -r"
su - amadmin -c "crontab /home/amadmin/box4s/main/crontab/amadmin.crontab"
sudo crontab -r
sudo crontab root.crontab
cd ~/box4s/

# Remove old Services
sudo systemctl stop openvas-scanner openvas-manager greenbone-security-assistant redis-server
sudo systemctl disable openvas-scanner openvas-manager greenbone-security-assistant redis-server
sudo apt remove -y --purge openvas


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
