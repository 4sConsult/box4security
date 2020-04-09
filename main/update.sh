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

  echo "Stelle Datenbank Backup wieder her"
  sudo docker cp /var/lib/box4s/box4S_db_$1.tar db:/root/box4S_db.tar
  sudo docker exec db /bin/bash -c "PGPASSWORD=zgJnwauCAsHrR6JB PGUSER=postgres pg_restore -F t --clean -d box4S_db /root/box4S_db.tar"

  echo "Stelle Kundenkonfiguration wieder her"
  tar -C /var/lib/box4s/ -vxf /var/lib/box4s/conf_backup_$1.tar
  # Restore /etc/box4s to state of box4s/ folder we got from unpacking the tar ball
  cd /var/lib/box4s
  rsync -avz --delete box4s/ /etc/box4s
  rm -r box4s/

  echo "Setze BOX4security Software auf Version $1 zurück"
  cd /home/amadmin/box4s/
  waitForNet gitlab.am-gmbh.de
  git fetch
  git checkout -f $1 >/dev/null 2>&1

  echo "Starte BOX4security Software neu."
  # restart box, causes download of the images of Version $1
  sudo systemctl restart box4security

  # Notify API that we're finished rolling back
  curl -sLk -XPOST https://localhost/update/status/ -H "Content-Type: application/json" -d '{"status":"rollback-successful"}' > /dev/null
  echo "VERSION=$PRIOR" > /home/amadmin/box4s/VERSION

  # Prepare new update.sh for next update
  sudo chown amadmin:amadmin $BASEDIR$GITDIR/BOX4s-main/update.sh
  sudo chmod +x $BASEDIR$GITDIR/BOX4s-main/update.sh

  # Exit update with error code
  exit 1
}

#Die Sleep Anweisungen dienen nur der Demo und können entfernt werden
exec 1>/var/log/box4s/update.log && exec 2>>/var/log/box4s/update.log
# Notify API that we're starting
# Follow redirects, accept invalid certificate and dont produce output
curl -sLk -XPOST https://localhost/update/status/ -H "Content-Type: application/json" -d '{"status":"running"}' > /dev/null
sleep 2

# Current version is the first "prior" version - get it from endpoint
PRIOR=$(curl -sLk -XGET https://localhost/ver/ | jq -r .version)
VERSIONS=()
# Use Python Script to create array of versions that have to be installed
# versions between current and the latest
cd $BASEDIR$GITDIR/main
waitForNet gitlab.am-gmbh.de
mapfile -t VERSIONS < <(python3 /home/amadmin/box4s/scripts/Automation/versions.py)
# GET env from local endpoint and extract it so we can keep it
ENV=$(curl -sLk localhost/ver/ | jq -r '.env')
TAG=${VERSIONS[-1]}
echo "Aktualisierung auf $TAG über alle zwischenliegenden Versionen gestartet."
for v in "${VERSIONS[@]}"
do
   echo "Erstelle Datenbank Backup"
   sudo docker exec db /bin/bash -c "PGPASSWORD=zgJnwauCAsHrR6JB PGUSER=postgres pg_dump -F tar box4S_db > /root/box4S_db.tar"
   sudo docker cp db:/root/box4S_db.tar /var/lib/box4s/box4S_db_$PRIOR.tar
   echo "Erstelle Backup der Kundenkonfiguration"
   tar -C /etc -cvpf /var/lib/box4s/conf_backup_$PRIOR.tar box4s/
   echo "Installiere Version $v"
   cd $BASEDIR$GITDIR
   waitForNet gitlab.am-gmbh.de
   git fetch
   git checkout -f $v >/dev/null 2>&1
   echo "Führe Updateanweisungen aus Version $v aus"
   sed -i "3s/.*/TAG=$v/g" $BASEDIR$GITDIR/update-patch.sh
   sudo chmod +x $BASEDIR$GITDIR/update-patch.sh
   sudo $BASEDIR$GITDIR/update-patch.sh
   if  [[ ! $? -eq 0 ]]; then
     echo "Update auf $v fehlgeschlagen"
     # Notify API that we're starting to roll back
     curl -sLk -XPOST https://localhost/update/status/ -H "Content-Type: application/json" -d '{"status":"rollback-running"}' > /dev/null
     rollback $PRIOR
   fi
   # successfully updated version, the PRIOR is now this version
   PRIOR=$v
done
echo "Update auf $TAG abgeschlossen."
# set version in file
echo "VERSION=$TAG" > /home/amadmin/box4s/VERSION
echo "BOX4s_ENV=$ENV" >> /home/amadmin/box4s/VERSION
# Notify API that we're finished
curl -sLk -XPOST https://localhost/update/status/ -H "Content-Type: application/json" -d '{"status":"successful"}' > /dev/null
# Prepare new update.sh for next update
sudo chown amadmin:amadmin $BASEDIR$GITDIR/main/update.sh
sudo chmod +x $BASEDIR$GITDIR/main/update.sh
exit $?
