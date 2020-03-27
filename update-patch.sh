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
# Uninstall old versions
sudo apt remove -y docker docker-engine docker.io containerd runc
sudo apt update
# Install Docker Dependencies
sudo apt install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
# Install GPG Key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
# Add repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
# Install
sudo apt-get install docker-ce docker-ce-cli containerd.io


sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Kopiere den neuen Service an die richtige Stelle und enable den Service
sudo cp /home/amadmin/box4s/System/etc/systemd/box4security.service /etc/systemd/system/box4security.service
sudo systemctl daemon-reload
sudo systemctl enable box4security.service

# Login bei der Docker-Registry des GitLabs und Download der Container
sudo docker login docker-registry.am-gmbh.de -u deployment-token-box -p KPLm6mZJFzuA9QY9oCZC
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull

# Erstelle das Volume für die Daten
sudo docker volume create --driver local --opt type=none --opt device=/data --opt o=bind data

# Apply new sudoers (change path for restart suricata)
sudo cp /home/amadmin/box4s/System/etc/sudoers /etc/sudoers
sudo cp /home/amadmin/box4s/System/home/amadmin/restartSuricata.sh /home/amadmin/restartSuricata.sh
sudo chmod +x /home/amadmin/restartSuricata.sh
sudo chown amadmin:amadmin /home/amadmin/restartSuricata.sh

# Install new Dependency for updatescript
sudo pip3 install semver

# Create BOX4s Log Path
sudo mkdir -p /var/log/box4s/
sudo touch /var/log/box4s/update.log

# Create BOX4s lib Path
sudo mkdir -p /var/lib/box4s/
sudo touch /var/lib/box4s/.update.state
sudo chmod 766 /var/lib/box4s/.update.state

# Openconnect nachträgliche installieren
sudo apt install -y openconnect

# Hosts Datei aktualisieren
sudo cp System/etc/hosts /etc/hosts


# Service für automatische VPN-Verbindung einfügen

sudo cp /home/amadmin/box4s/System/etc/systemd/vpn.service /etc/systemd/system/vpn.service
sudo systemctl daemon-reload
sudo systemctl enable vpn.service
sudo systemctl start vpn.service

# Installation der neuen Schwachstellendashboards
curl -X POST "localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Nginx/var/www/kibana/res/SchwachstellenDashboards.ndjson

# Scores Index in vorheriger Version fehlerhaft gewesen
cd /home/amadmin/box4s/Scripts/Automation/score_calculation/
./install_index.sh

# Installation der SIEM Dashboards
curl -X POST "localhost:5601/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Nginx/var/www/kibana/res/SIEMDashboards.ndjson

# Start des Services
echo "Restarting BOX4s Service. Please wait."
sleep 8 # Sleep can be replaced later with uptime or health check..
sudo systemctl restart box4security.service
