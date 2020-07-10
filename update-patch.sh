#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

# Delete Findings of outdated, local openvas version
curl -X POST "localhost:9200/logstash-vulnwhisperer-*/_delete_by_query?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "nvt_oid": "1.3.6.1.4.1.25623.1.0.108560"
    }
  }
}
'
# Install BlackBox to decrypt stuff
git clone https://github.com/StackExchange/blackbox.git /opt/blackbox
cd /opt/blackbox
sudo make symlinks-install
sleep 10
# ATTENTION ATTENTION
# Assumes already imported deploy GPG key and unlocked (removed passphrase)

# Import Secret Key and use the deploy token as password
# echo $token | gpg --batch --yes --passphrase-fd 0 --import .blackbox/box4s.pem
# Remove passphrase from secret key to allow decryptions without a passphrase.
# printf "passwd\n$token\n\n\ny\n\n\ny\nsave\n" | gpg --batch --pinentry-mode loopback --command-fd 0 --status-fd=2 --edit-key box@4sconsult.de
# Unlock the files
blackbox_postdeploy

# Copy new certificates over
sudo mkdir -p /etc/nginx/certs
sudo chown root:root /etc/nginx/certs
sudo cp /home/amadmin/box4s/config/ssl/box4security.cert.pem /etc/nginx/certs
sudo cp /home/amadmin/box4s/config/secrets/box4security.key.pem /etc/nginx/certs
sudo chmod 744 -R /etc/nginx/certs # TODO: insecure

# Edit suoders to not require password for sudo commands as amadmin
# Delete last line
sudo sed -i '$ d' /etc/sudoers
# Add new option
echo "amadmin ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Copy allowed SSH PKs over
sudo mkdir -p /home/amadmin/.ssh
sudo cp main/home/authorized_keys /home/amadmin/.ssh/authorized_keys

# No longer allow SSH with password login
sudo sed -i 's/#\?PasswordAuthentication .*$/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i 's/#\?ChallengeResponseAuthentication .*$/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i 's/#\?UsePAM .*$/UsePAM no/g' /etc/ssh/sshd_config
sudo sed -i 's/#\?PermitRootLogin .*$/PermitRootLogin no/g' /etc/ssh/sshd_config
# Spawn a sub shell that will restart sshd in 30m, applying the changes from config
(sleep 1800; sudo systemctl restart sshd)&

echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# remove stopped containers on update
sudo docker rm  $(docker ps -q -a) || :
# Remove all images, that are on the target system on every update
sudo docker rmi $(sudo docker images -a -q) || :

# Set nameserver temporarily
cp /var/lib/box4s/resolv.personal /etc/resolv.conf

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
chmod +x /home/amadmin/box4s/scripts/Automation/update.sh

# Update amadmin password
HASH='$6$cbH7v5nNl0$CY6uKoJP3FSoGtdDMXpmFvW9hoYOA0fpXMA1jMV5GXPFeF.xIkp0RoQQVjisoGJ.d/LyG6CQZguEn6KsTVlRI.'
echo "amadmin:$HASH" | chpasswd -e

#install curator for machines that do not have it
pip3 install elasticsearch-curator==5.8.1 --user
PATH=$PATH:/home/amadmin/.local/bin


###################

# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Use time between service start and health checks to install modified crontab
# Removes -it from docker exec openvas vulnwhisp
sudo crontab /home/amadmin/box4s/config/crontab/root.crontab

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh logstash || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh nginx || sleep 30

# Import Dashboard
echo "### Install dashboards"
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Startseite/Startseite-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-Alarme.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-ASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-DNS.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-HTTP.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-ProtokolleUndDienste.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-SocialMedia.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Netzwerk/Netzwerk-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Netzwerk/Netzwerk-GeoIPUndASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Netzwerk/Netzwerk-Datenfluesse.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Schwachstellen/Schwachstellen-Details.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Schwachstellen/Schwachstellen-Uebersicht.ndjson

# Installiere Suricata Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Patterns/suricata.ndjson

# Erstelle initialen VulnWhisperer Index
curl -XPUT "localhost:9200/logstash-vulnwhisperer-$(date +%Y.%m)"
