#!/bin/bash
set -e
# Log file to use
# Create path if allowed or do NOP
mkdir -p /var/log/box4s/1stLevelRepair || :
LOG_DIR="/var/log/box4s/1stLevelRepair"
if [[ ! -w $LOG_DIR ]]; then
  LOG_DIR="$HOME"
fi

LOG=$LOG_DIR/format_drive.log

# Do not use interactive debian frontend.
export DEBIAN_FRONTEND=noninteractive

# Forward fd2 to the console
# exec 2>&1
# Forward fd1 to $LOG
exec 2>&1 1>>${LOG}

#
#flag: empty - when used the /data structure is not recreated
#
echo -n "Starting to wipe Data.. " 1>&2
sudo srm -zr /data
echo "[ DONE ]" 1>&2


echo -n "Recreating file structure to allow new Data.. " 1>&2
sudo mkdir -p /data
sudo chown root:root /data
sudo chmod 777 /data
sudo mkdir -p /data/suricata/
sudo touch /data/suricata/eve.json

#Recreate Docker Volumes
#Recreate Data
sudo docker volume create --driver local --opt type=none --opt device=/data --opt o=bind data
sudo chown -R root:44269 /data
sudo chmod 760 -R /data


#Recreate Postgresql
sudo mkdir -p /var/lib/postgresql/data
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/postgresql/data --opt o=bind varlib_postgresql
sudo chown -R root:44269 /var/lib/postgresql/data
sudo chmod 760 -R /var/lib/postgresql/data

# Recreate Elastic Volume
sudo mkdir /data/elasticsearch -p
sudo mkdir /data/elasticsearch_backup/Snapshots -p
# Elasticsearch is somewhat special...
sudo chown -R 1000:0 /data/elasticsearch
sudo chown -R 1000:0 /data/elasticsearch_backup
sudo chmod 760 -R /data/elasticsearch
sudo chmod 760 -R /data/elasticsearch_backup
echo "[ DONE ]" 1>&2
