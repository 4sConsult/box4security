#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Stoppe die aktuelle Elasticsearch-Instanz
service elasticsearch stop

# Entferne Elasticsearch vom System
apt remove --purge elasticsearch
apt autoremove -y

# Vergib die passenden Rechte für den neuen Container auf die vorhandenen Daten
chmod 777 /data/elasticsearch -R

# Docker installieren mit docker-compose
apt install -y docker.io
sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Kopiere den neuen Service an die richtige Stelle und enable den Service
cp /home/amadmin/box4s/System/etc/systemd/box4security.service /etc/systemd/system/box4security.service
systemctl enable box4security.service

# Login bei der Docker-Registry des GitLabs und Download der Container
docker login docker-registry.am-gmbh.de -u deployment-token-box -p KPLm6mZJFzuA9QY9oCZC
docker-compose -f box4security.yml pull

# Start des Services
systemctl start box4security.service
