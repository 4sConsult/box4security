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

echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# remove stopped containers on update
sudo docker rm  $(docker ps -q -a) || :
# Remove all images, that are on the target system on every update
sudo docker rmi $(sudo docker images -a -q) || :

# If exists, remove the elastalert example rule
rm -f /var/lib/elastalert/rules/testrule.yaml

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

# Import Dashboard
echo "### Install dashboards"
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Startseite/Startseite-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-Alarme.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-ASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-DNS.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-HTTP.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-ProtokolleUndDienste.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-SocialMedia.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-GeoIPUndASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-Datenfluesse.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Details.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Uebersicht.ndjson

# Installiere Suricata Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Patterns/suricata.ndjson

# Erstelle initialen VulnWhisperer Index
curl -XPUT "localhost:9200/logstash-vulnwhisperer-$(date +%Y.%m)"
