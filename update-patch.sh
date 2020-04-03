#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Stoppe und deinstalliere Nginx und PostgreSQL
sudo systemctl stop logstash
sudo systemctl disable logstash
sudo apt remove -y logstash
sudo apt autoremove -y

# Start des Services
echo "Stop BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# Neue Volumes anlegen
sudo mkdir /var/lib/logstash
sudo chown root:root /var/lib/logstash
sudo chmod -R 777 /var/lib/logstash

sudo mkdir -p /etc/box4s/logstash
sudo chown root:root /etc/box4s/
sudo chmod -R 777 /etc/box4s/

# Volumes in Docker anlegen
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/logstash/ --opt o=bind varlib_logstash
sudo docker volume create --driver local --opt type=none --opt device=/etc/box4s/logstash/ --opt o=bind etcbox4s_logstash

# Kopiere die Logstash-Konfigurationsdateien an den neuen Ort
sudo cp /home/amadmin/box4s/System/etc/box4s/logstash/* /etc/box4s/logstash/

# Start des Services
echo "Start BOX4s Service. Please wait."
sudo systemctl start box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh logstash
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh kibana
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh nginx
