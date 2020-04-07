#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Stoppe und deinstalliere Nginx und PostgreSQL
sudo systemctl stop logstash filebeat metricbeat auditbeat auditd suricata
sudo systemctl disable logstash filebeat metricbeat auditbeat auditd suricata
sudo apt remove -y logstash filebeat metricbeat auditbeat
sudo apt autoremove -y

# Stop des Services
echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# Download IP2Location DBs for the first time
# IP2LOCATION Token
IP2TOKEN="MyrzO6sxNLvoSEaGtpXoreC1x50bRGmDfNd3UFBIr66jKhZeGXD7cg9Jl9VdQhQ5"
cd /tmp/
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBIN" -o IP2LOCATION-LITE-DB5.BIN.zip
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBINIPV6" -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo unzip -o IP2LOCATION-LITE-DB5.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.BIN
sudo unzip -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.IPV6.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.IPV6.BIN

# Neue Volumes anlegen
sudo mkdir -p /etc/box4s/suricata
sudo mkdir -p /etc/box4s/logstash
sudo mkdir -p /var/lib/suricata

sudo chown root:root /var/lib/logstash
sudo chmod -R 777 /var/lib/logstash

sudo chown root:root /var/lib/suricata
sudo chmod -R 777 /var/lib/suricata

sudo chown root:root /etc/box4s/
sudo chmod -R 777 /etc/box4s/

# Volumes in Docker anlegen
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/logstash/ --opt o=bind varlib_logstash
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/suricata/ --opt o=bind varlib_suricata
sudo docker volume create --driver local --opt type=none --opt device=/etc/box4s/logstash/ --opt o=bind etcbox4s_logstash
sudo docker volume create --driver local --opt type=none --opt device=/etc/box4s/suricata/ --opt o=bind etcbox4s_suricata

# Kopiere die Logstash-Konfigurationsdateien an den neuen Ort
sudo cp /home/amadmin/box4s/System/etc/box4s/logstash/* /etc/box4s/logstash/

# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl start box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh logstash
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh kibana
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh nginx
