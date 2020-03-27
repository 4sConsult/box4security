#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Stoppe die aktuelle Elasticsearch- und Kibana-Instanz
sudo service elasticsearch stop
sudo service kibana stop
sudo systemctl disable elasticsearch.service
sudo systemctl disable kibana.service

# Entferne Elasticsearch vom System
sudo apt remove -y --purge elasticsearch kibana
sudo apt autoremove -y

# Vergib die passenden Rechte für den neuen Container auf die vorhandenen Daten
sudo chmod 777 /data/elasticsearch -R

# Docker installieren mit docker-compose
sudo apt install -y docker.io
sudo curl -s -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Kopiere den neuen Service an die richtige Stelle und enable den Service
sudo cp /home/amadmin/box4s/System/etc/systemd/box4security.service /etc/systemd/system/box4security.service
sudo systemctl enable box4security.service

# Login bei der Docker-Registry des GitLabs und Download der Container
sudo docker login docker-registry.am-gmbh.de -u deployment-token-box -p KPLm6mZJFzuA9QY9oCZC
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull

# Erstelle das Volume für die Daten
sudo docker volume create --driver local --opt type=none --opt device=/data --opt o=bind data

# Start des Services
sudo systemctl start box4security.service

# Openconnect nachträglichen installieren
sudo apt install -y openconnect

# Hosts Datei aktualisieren
sudo cp System/etc/hosts /etc/hosts

# Service für automatische VPN-Verbindung einfügen
sudo cp /home/amadmin/box4s/System/etc/systemd/vpn.service /etc/systemd/system/vpn.service
sudo systemctl daemon-reload
sudo systemctl enable vpn.service
sudo systemctl start

# Installation der neuen Schwachstellendashboards
# Zunächst prüfen, ob Kibana bereits vollständig hochgefahren ist
sudo Scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo Scripts/System_Scripts/wait-for-healthy-container.sh kibana

curl -s -X POST "localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Nginx/var/www/kibana/res/SchwachstellenDashboards.ndjson

# Scores Index in vorheriger Version fehlerhaft gewesen
cd /home/amadmin/box4s/Scripts/Automation/score_calculation/
./install_index.sh
