#!/bin/bash
#
# Placeholder for TAG=
# The Tag will be the highest version, so the goal of the update
function testNet() {
  # Returns 0 for successful internet connection and dns resolution, 1 else
  ping -q -c 1 -W 1 $1 >/dev/null;
  return $?
}

function waitForNet() {
  # use argument or default value of google.com
  HOST=${1:-"google.com"}
  while ! testNet $HOST; do
    # while testNet returns non zero value
    echo "No internet connectivity or dns resolution of $HOST, sleeping for 15s"
    sleep 15s
  done
}
function rollback() {
  echo "Starte Rollback auf $1"
  echo "Reinstalliere deinstallierte Pakete"
  # reinstalliere heute deinstallierte Pakete.
  apt install -y $(grep Remove /var/log/apt/history.log -B3 | grep $(date "+%Y-%m-%d") -A3 | grep "Remove: " | sed -e 's|Remove: ||g' -e 's|([^)]*)||g' -e 's|:[^ ]* ||g' -e 's|,||g')

  echo "Stelle Datenbank Backup wieder her"
  docker cp /var/lib/box4s/backup/box4S_db_$1.tar db:/root/box4S_db.tar
  docker exec db /bin/bash -c "PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER pg_restore -F t --clean -d box4S_db /root/box4S_db.tar"

  echo "Stelle Kundenkonfiguration wieder her"
  tar -C /var/lib/box4s/backup/ -vxf /var/lib/box4s/backup/etc_box4s_$1.tar
  # Restore /etc/box4s to state of box4s/ folder we got from unpacking the tar ball
  cd /var/lib/box4s/backup
  rsync -Iavz --delete box4s/ /etc/box4s
  rm -r box4s/
  cp /var/lib/box4s/backup/resolv.personal /var/lib/box4s/resolv.personal
  rm -f /var/lib/box4s/backup/resolv.personal
  cp /var/lib/box4s/backup/15_logstash_suppress.conf /var/lib/box4s/15_logstash_suppress.conf
  cp /var/lib/box4s/backup/suricata_suppress.bpf /var/lib/box4s/suricata_suppress.bpf
  cp /var/lib/box4s/backup/alert_mail.conf /var/lib/box4s/alert_mail.conf || : # dont fail if this file didn't exist
  rm -f /var/lib/box4s/backup/15_logstash_suppress.conf
  rm -f /var/lib/box4s/backup/suricata_suppress.bpf
  rm -f /var/lib/box4s/backup/alert_mail.conf
  cp /var/lib/box4s/backup/suricata.env $BOX4s_CONFIG_DIR/.env.suri
  rm -f /var/lib/box4s/backup/suricata.env

  echo "Stelle Systemkonfiguration wieder her"
  cp /var/lib/box4s/backup/hosts /etc/hosts
  rm -f /var/lib/box4s/backup/hosts
  cp /var/lib/box4s/backup/environment /etc/environment
  rm -f /var/lib/box4s/backup/environment
  cp /var/lib/box4s/backup/msmtprc /etc/msmtprc
  rm -f /var/lib/box4s/backup/msmtprc
  cp /var/lib/box4s/backup/sudoers /etc/sudoers
  rm -f /var/lib/box4s/backup/sudoers
  cp /var/lib/box4s/backup/interfaces /etc/network/interfaces
  rm -f /var/lib/box4s/backup/interfaces
  cp -R /var/lib/box4s/backup/ssl/* /etc/nginx/certs/
  rm -rf /var/lib/box4s/backup/ssl

  echo "Stelle Dokumentation wieder her"
  rm -rf /var/lib/box4s_docs/*
  cp -R /var/lib/box4s/backup/wiki/* /var/lib/box4s_docs/
  rm -rf /var/lib/box4s/backup/wiki

  echo "Stelle die konfiguierten Alarme wieder her"
  rm -rf /var/lib/elastalert/rules/*
  cp -R /var/lib/box4s/backup/alerts/* /var/lib/elastalert/rules/
  rm -rf /var/lib/box4s/backup/alerts

  cd $BOX4s_INSTALL_DIR
  git fetch
  git checkout -f $1 >/dev/null 2>&1

  # Rolling back jvm settings
  cp /var/lib/box4s/backup/.env.es $BOX4s_CONFIG_DIR/.env.es
  cp /var/lib/box4s/backup/.env.ls $BOX4s_CONFIG_DIR/.env.ls
  rm -f /var/lib/box4s/backup/.env.es /var/lib/box4s/backup/.env.ls

  echo "Setze Dienst auf Version $1 zurück"
  cp $BOX4s_INSTALL_DIR/config/etc/systemd/box4security.service /etc/systemd/system/box4security.service

  # sleep to wait for established connection
  sleep 8

  echo "Setze BOX4security Software auf Version $1 zurück"
  docker-compose -f $BOX4s_INSTALL_DIR/docker/box4security.yml pull -q
  docker-compose -f $BOX4s_INSTALL_DIR/docker/wazuh/wazuh.yml pull -q

  echo "Starte BOX4security Software neu."
  # set version in file
  echo "VERSION=$1" > /var/lib/box4s/VERSION
  echo "BOX4s_ENV=$ENV" >> /var/lib/box4s/VERSION
  # restart box, causes start of the images of Version $1
  systemctl restart box4security

  # Lösche fehlerhaften Tag lokal
  cd $BOX4s_INSTALL_DIR
  git tag -d $2

  $BOX4s_INSTALL_DIR/scripts/System_Scripts/wait-for-healthy-container.sh web
  # Notify API that we're finished rolling back
  echo "rollback-successful" > /var/lib/box4s/.update.state
  echo "Wiederherstellung auf $1 abgeschlossen."

  # Prepare new update.sh for next update
  chown amadmin:amadmin $BOX4s_INSTALL_DIR/scripts/Automation/update.sh
  chmod +x $BOX4s_INSTALL_DIR/scripts/Automation/update.sh
  curl -sLk -XDELETE https://localhost/api/update/status/ > /dev/null
  sleep 5
  # Exit update with error code
  exit 1
}
function backup() {
  mkdir -p /var/lib/box4s/backup/

  echo "Erstelle Backup vom aktuellen Stand: $1"
  echo "Erstelle Datenbank Backup"
  docker exec db /bin/bash -c "PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER pg_dump -F tar box4S_db > /root/box4S_db.tar"
  docker cp db:/root/box4S_db.tar /var/lib/box4s/backup/box4S_db_$PRIOR.tar

  echo "Erstelle Backup der Kundenkonfiguration"
  # Backing up /etc/box4s
  tar -C /etc -cvpf /var/lib/box4s/backup/etc_box4s_$PRIOR.tar box4s/
  cp /var/lib/box4s/resolv.personal /var/lib/box4s/backup/resolv.personal
  cp /var/lib/box4s/15_logstash_suppress.conf /var/lib/box4s/backup/15_logstash_suppress.conf
  cp /var/lib/box4s/suricata_suppress.bpf /var/lib/box4s/backup/suricata_suppress.bpf
  cp /var/lib/box4s/alert_mail.conf /var/lib/box4s/backup/alert_mail.conf || : # dont fail if this file doesnt exist (yet)
  cp $BOX4s_CONFIG_DIR/.env.suri /var/lib/box4s/backup/suricata.env

  echo "Erstelle Backup der Systemkonfiguration"
  cp /etc/hosts /var/lib/box4s/backup/hosts
  cp /etc/environment /var/lib/box4s/backup/environment
  cp /etc/msmtprc /var/lib/box4s/backup/msmtprc
  cp /etc/sudoers /var/lib/box4s/backup/sudoers
  cp /etc/network/interfaces /var/lib/box4s/backup/
  mkdir -p /var/lib/box4s/backup/ssl
  cp -R /etc/nginx/certs/* /var/lib/box4s/backup/ssl/

  echo "Erstelle Backup der Dokumentation"
  mkdir -p /var/lib/box4s/backup/wiki
  cp -R /var/lib/box4s_docs/* /var/lib/box4s/backup/wiki/

  echo "Erstelle Backup der konfigurierten Alarme"
  mkdir -p /var/lib/box4s/backup/alerts
  cp -R /var/lib/elastalert/rules/* /var/lib/box4s/backup/alerts
}

#Die Sleep Anweisungen dienen nur der Demo und können entfernt werden
exec 1>/var/log/box4s/update.log && exec 2>&1
# Notify API that we're starting
# Follow redirects, accept invalid certificate and dont produce output
curl -sLk -XPOST https://localhost/api/update/status/ -H "Content-Type: application/json" -d '{"status":"running"}' > /dev/null
sleep 2

# Current version is the first "prior" version - get it from endpoint
PRIOR=$(curl -sLk -XGET https://localhost/api/ver/ | jq -r .version)
VERSIONS=()
# Use Python Script to create array of versions that have to be installed
# versions between current and the latest
mapfile -t VERSIONS < <(python3 $BOX4s_INSTALL_DIR/scripts/Automation/versions.py)
# GET env from local endpoint and extract it so we can keep it
ENV=$(curl -sLk localhost/api/ver/ | jq -r '.env')
TAG=${VERSIONS[-1]}
echo "Aktualisierung auf $TAG über alle zwischenliegenden Versionen gestartet."
source $BOX4s_CONFIG_DIR/db.conf
for v in "${VERSIONS[@]}"
do
   backup $PRIOR
   echo "Installiere Version $v"
   cd $BOX4s_INSTALL_DIR
   git fetch
   cp $BOX4s_CONFIG_DIR/.env.ls /var/lib/box4s/backup/.env.ls
   cp $BOX4s_CONFIG_DIR/.env.es /var/lib/box4s/backup/.env.es
   git checkout -f $v >/dev/null 2>&1
   blackbox_postdeploy
   # Restore Memory Settings for JVM
   cp /var/lib/box4s/backup/.env.ls $BOX4s_CONFIG_DIR/.env.ls
   cp /var/lib/box4s/backup/.env.es $BOX4s_CONFIG_DIR/.env.es
   echo "Führe Updateanweisungen aus Version $v aus"
   sed -i "3s/.*/TAG=$v/g" $BOX4s_INSTALL_DIR/update-patch.sh
   chmod +x $BOX4s_INSTALL_DIR/update-patch.sh
   $BOX4s_INSTALL_DIR/update-patch.sh
   if  [[ ! $? -eq 0 ]]; then
     echo "Update auf $v fehlgeschlagen"
     # Notify API that we're starting to roll back
     curl -sLk -XPOST https://localhost/api/update/status/ -H "Content-Type: application/json" -d '{"status":"rollback-running"}' > /dev/null
     rollback $PRIOR $v
   fi
   # successfully updated version
   # pack and store backup
   tar -C /var/lib/box4s -cvpzf /var/lib/box4s/update_backup_$PRIOR.tar.gz backup/
   # clear backup folder
   rm -rf /var/lib/box4s/backup/*
   # delete backups older than 3 months
   find /var/lib/box4s/ -type f -name "update_backup_*.tar.gz" -mtime +90 -delete
   # the PRIOR is now the successfully installed version
   PRIOR=$v
done
echo "Update auf $TAG abgeschlossen."
# set version in file
echo "VERSION=$TAG" > /var/lib/box4s/VERSION
echo "BOX4s_ENV=$ENV" >> /var/lib/box4s/VERSION
# Notify API that we're finished
curl -sLk -XPOST https://localhost/api/update/status/ -H "Content-Type: application/json" -d '{"status":"successful"}' > /dev/null
# Prepare new update.sh for next update
chown amadmin:amadmin $BOX4s_INSTALL_DIR/scripts/Automation/update.sh
chmod +x $BOX4s_INSTALL_DIR/scripts/Automation/update.sh
sleep 15 # sleep for API <-> Webbrowser communication
curl -sLk -XDELETE https://localhost/api/update/status/ > /dev/null
exit 0
