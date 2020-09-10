#!/bin/bash
##
TAG=""
##
# Exit on every error
set -e

# Making sure to be logged in with the correct account
sudo docker login registry.gitlab.com -u deployment -p B-H-Sg97y3otYdRAjFkQ

sudo apt install -y unattended-upgrades

# Set the nameserver temporarily
cp /var/lib/box4s/resolv.personal /etc/resolv.conf

# Create an suricata index of the current month. score calculation will fail without an existing index.
curl -sLkX PUT localhost:9200/suricata-$(date +%Y.%m) > /dev/null

# Delete Findings of outdated, local openvas version
curl -slKX POST "localhost:9200/logstash-vulnwhisperer-*/_delete_by_query?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "nvt_oid": "1.3.6.1.4.1.25623.1.0.108560"
    }
  }
}
' > /dev/null
# Delete Findings of outdated openvas feed
curl -sLkX POST "localhost:9200/logstash-vulnwhisperer-*/_delete_by_query?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "nvt_oid": "1.3.6.1.4.1.25623.1.0.108560"
    }
  }
}
' > /dev/null


echo "Stopping BOX4s Service. Please wait."
sudo systemctl stop box4security.service

# remove stopped containers on update
sudo docker rm  $(docker ps -q -a) || :
# Remove all images, that are on the target system on every update
sudo docker rmi $(sudo docker images -a -q) || :

###################
# Changes here
sudo addgroup --gid 44269 boxforsecurity # Create group
sudo usermod -a -G boxforsecurity amadmin # Add amadmin to created group

# Set root:group as owner
# Let group read and write.
sudo chown -R root:44269 /var/lib/openvas
sudo chmod 760 -R /var/lib/openvas

sudo chown -R root:44269 /var/lib/logstash
sudo chmod 760 -R /var/lib/logstash

sudo chown -R root:44269 /data
sudo chmod 760 -R /data

sudo chown -R root:44269 /var/lib/box4s
sudo chmod 760 -R /var/lib/openvas

sudo chown -R root:44269 /etc/box4s/logstash
sudo chmod 760 -R /etc/box4s/logstash

sudo chown -R root:44269 /var/log/box4s
sudo chmod 760 -R /var/log/box4s

sudo chown -R root:44269 /var/lib/elastalert/rules
sudo chmod 760 -R /var/lib/elastalert/rules

sudo chown -R root:44269 /etc/box4s/smtp.conf
sudo chmod 760 -R /etc/box4s/smtp.conf

sudo chown -R root:44269 /etc/box4s/modules.conf
sudo chmod 760 -R /etc/box4s/modules.conf

sudo chown -R root:44269 /etc/msmtprc
sudo chmod 760 -R /etc/msmtprc

sudo chown -R root:44269 /etc/ssl/certs/BOX4s-SMTP.pem
sudo chmod 760 -R /etc/ssl/certs/BOX4s-SMTP.pem

sudo chown -R root:44269 /etc/ssl/certs/ca-certificates.crt
sudo chmod 760 -R /etc/ssl/certs/ca-certificates.crt

sudo chown -R root:44269 /var/lib/postgresql/data
sudo chmod 760 -R /var/lib/postgresql/data

sudo chown -R root:44269 /etc/nginx/certs
sudo chmod 760 -R /etc/nginx/certs

sudo touch /var/lib/box4s/elastalert_smtp.yaml
sudo chown -R root:44269 /var/lib/box4s/elastalert_smtp.yaml
sudo chmod 760 -R /var/lib/box4s/elastalert_smtp.yaml

sudo chown -R root:44269 /etc/ssl/certs/ca-certificates.crt
sudo chmod 760 -R /etc/ssl/certs/ca-certificates.crt

sudo chown -R root:44269 /var/lib/box4s_docs/
sudo chmod 760 -R /var/lib/box4s_docs/

# Elasticsearch is somewhat special...
sudo chown -R 1000:0 /data/elasticsearch
sudo chown -R 1000:0 /data/elasticsearch_backup
sudo chmod 760 -R /data/elasticsearch
sudo chmod 760 -R /data/elasticsearch_backup

#remove all crontabs but dont fail if doesnt exist!
crontab -r || :
sudo crontab -r || :
#insert new crontab that is used for now
cd /home/amadmin/box4s/config/crontab
su - amadmin -c "crontab /home/amadmin/box4s/config/crontab/amadmin.crontab"

#remove curator because it is moved to core4s; also remove curator config files
sudo pip3 uninstall -y elasticsearch-curator
sudo rm /home/amadmin/curator.yml
sudo rm /home/amadmin/actions.yml

# Copy default elastalert smtp auth file
sudo cp /home/amadmin/box4s/docker/elastalert/etc/elastalert/smtp_auth_file.yaml /var/lib/box4s/elastalert_smtp.yaml
# Remove unused folder and script
sudo rm /home/amadmin/box4s/scripts/Elastic_Scripts/ -R || :

# Copy new suricata rule file
sudo cp /home/amadmin/box4s/docker/suricata/var_lib/social_media.rules /var/lib/suricata/rules/social_media.rules

###################

echo "### Detecting available memory and distribute it to the containers"
# Detect rounded memory
MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM=$(python3 -c "print($MEM/1024.0**2)")
# Give half of that to elasticsearch
ESMEM=$(python3 -c "print(int($MEM*0.5))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${ESMEM}g -Xmx${ESMEM}g/g" /home/amadmin/box4s/docker/elasticsearch/.env.es
# and one quarter to logstash
LSMEM=$(python3 -c "print(int($MEM*0.25))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${LSMEM}g -Xmx${LSMEM}g/g" /home/amadmin/box4s/docker/logstash/.env.ls

# Get the current images
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull
sudo docker-compose -f /home/amadmin/box4s/docker/wazuh/wazuh.yml pull

# Start des Services
echo "Starting BOX4s Service. Please wait."
sudo systemctl restart box4security.service

# Waiting for healthy containers before continuation
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh logstash || sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana || sleep 30
sleep 20
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
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/System/docker.ndjson

# Installiere Suricata Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Patterns/suricata.ndjson

# Update Score Mapping
curl -s -H "Content-type: application/json" -X PUT http://localhost:9200/scores/_mapping --data-binary @$DIR/res/index_mapping.json

# Erstelle initialen VulnWhisperer Index
curl -XPUT "localhost:9200/logstash-vulnwhisperer-$(date +%Y.%m)"
