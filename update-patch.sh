#!/bin/bash
##
TAG=""
##
# Tag kann durch die update.sh gesetzt werden, sollte der Tag hier benötigt werden.

# Copy new E-Mail data
cd /home/amadmin/box4s
sudo cp System/home/amadmin/.msmtprc /home/amadmin/.msmtprc
chown amadmin:amadmin /home/amadmin/.msmtprc
sudo cp System/etc/msmtprc /etc/msmtprc

# Stoppe und deinstalliere Nginx und PostgreSQL
sudo systemctl stop nginx postgresql
sudo systemctl disable nginx postgresql
sudo apt remove -y --purge nginx postgresql
sudo apt autoremove -y

# Reinstall VulnWhisperer, but to /opt/
cd /opt/
sudo git clone https://github.com/box4s/VulnWhisperer.git
cd VulnWhisperer/
sudo virtualenv venv
source venv/bin/activate
sudo pip install -r requirements.txt
sudo python setup.py install --prefix /usr/local
deactivate

echo "Install new Crontab"
cd /home/amadmin/box4s/BOX4s-main/crontab
sudo crontab root.crontab


# Stoppe die aktuelle Elasticsearch- und Kibana-Instanz
sudo service elasticsearch stop
sudo service kibana stop
sudo service nginx stop
sudo service postgresql stop
sudo systemctl disable elasticsearch.service
sudo systemctl disable kibana.service
sudo systemctl disable nginx.service
sudo systemctl disable postgresql.service

# Entferne Elasticsearch vom System
sudo apt remove -y --purge elasticsearch kibana nginx postgresql
sudo apt autoremove -y

# Vergib die passenden Rechte für den neuen Container auf die vorhandenen Daten
sudo chmod 777 /data/elasticsearch -R

# Docker installieren mit docker-compose
sudo apt install -y docker.io
sudo curl -sL "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Kopiere den neuen Service an die richtige Stelle und enable den Service
sudo cp /home/amadmin/box4s/System/etc/systemd/box4security.service /etc/systemd/system/box4security.service
sudo systemctl daemon-reload
sudo systemctl enable box4security.service

# Login bei der Docker-Registry des GitLabs und Download der Container
sudo docker login docker-registry.am-gmbh.de -u deployment-token-box -p KPLm6mZJFzuA9QY9oCZC
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull

# Erstelle das Volume für die Daten
sudo mkdir /var/lib/box4s
sudo mkdir /var/lib/postgresql/data

sudo docker volume create --driver local --opt type=none --opt device=/data --opt o=bind data
# Erstelle Volume für BOX4s Anwendungsdaten (/var/lib/box4s)
sudo mkdir -p /var/lib/box4s
sudo chown root:root /var/lib/box4s
sudo chmod -R 777 /var/lib/box4s
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s/ --opt o=bind varlib_box4s
# Erstelle Volume für PostgreSQL
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/postgresql/data --opt o=bind varlib_postgresql


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

# create
sudo touch /var/lib/box4s/15_logstash_suppress.conf
sudo touch /var/lib/box4s/suricata_suppress.bpf
sudo chmod -R 777 /var/lib/box4s/
# rm old links
sudo rm /etc/logstash/conf.d/suricata/15_kibana_filter.conf
# create links
sudo ln -s /var/lib/box4s/15_logstash_suppress.conf /etc/logstash/conf.d/suricata/15_logstash_suppress.conf
# Copy updated Suricata Service
sudo cp /home/amadmin/box4s/Suricata/etc/systemd/system/suricata.service /etc/systemd/system/suricata.service
sudo systemctl daemon-reload
# Restart suricata
sudo systemctl restart suricata

# Copy suricata filter conf (creates updated link_surpress_bpf links)
sudo cp /home/amadmin/box4s/Logstash/etc/logstash/conf.d/suricata/20_4s_suricata_filter.conf /etc/logstash/conf.d/suricata/20_4s_suricata_filter.conf

# Openconnect nachträgliche installieren
sudo apt install -y openconnect

# Hosts Datei aktualisieren
sudo cp System/etc/hosts /etc/hosts


# Service für automatische VPN-Verbindung einfügen

sudo cp /home/amadmin/box4s/System/etc/systemd/vpn.service /etc/systemd/system/vpn.service
sudo systemctl daemon-reload
sudo systemctl enable vpn.service
sudo systemctl start vpn.service

# Start des Services
echo "Restarting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Installation der neuen Dashboards
# Zunächst prüfen, ob Kibana bereits vollständig hochgefahren ist

sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh kibana


curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/Startseite/Startseite-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/SIEM/SIEM-Alarme.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/SIEM/SIEM-ASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/SIEM/SIEM-DNS.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/SIEM/SIEM-HTTP.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/SIEM/SIEM-ProtokolleUnDienste.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/SIEM/SIEM-SocialMedia.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/SIEM/SIEM-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/Netzwerk/Netzwerk-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/Netzwerk/Netzwerk-GeoIPUndASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/Netzwerk/Netzwerk-Datenfluesse.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/Schwachstellen/Schwachstellen-Details.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Dashboards/Schwachstellen/Schwachstellen-Uebersicht.ndjson

# Scores Index in vorheriger Version fehlerhaft gewesen
cd /home/amadmin/box4s/Scripts/Automation/score_calculation/
./install_index.sh

# Entferne /var/www (nach Deinstallation nginx unnötig)
sudo rm -rf /var/www/

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh kibana
sudo /home/amadmin/box4s/Scripts/System_Scripts/wait-for-healthy-container.sh nginx
