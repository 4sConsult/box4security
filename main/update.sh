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
#Die Sleep Anweisungen dienen nur der Demo und können entfernt werden
exec 1>/var/log/box4s/update.log && exec 2>>/var/log/box4s/update.log
# Notify API that we're starting
# Follow redirects, accept invalid certificate and dont produce output
curl -sLk -XPOST https://localhost/update/status/ -H "Content-Type: application/json" -d '{"status":"running"}' > /dev/null
sleep 2

VERSIONS=()
# Use Python Script to create array of versions that have to be installed
# versions between current and the latest
cd $BASEDIR$GITDIR/main
waitForNet gitlab.am-gmbh.de
mapfile -t VERSIONS < <(python3 /home/amadmin/box4s/scripts/Automation/versions.py)
TAG=${VERSIONS[-1]}
echo "Aktualisierung auf $TAG über alle zwischenliegenden Versionen gestartet."
for v in "${VERSIONS[@]}"
do
   echo "Installiere Version $v"
   cd $BASEDIR$GITDIR
   waitForNet gitlab.am-gmbh.de
   git fetch
   git checkout -f $v >/dev/null 2>&1
   echo "Führe Updateanweisungen aus Version $v aus"
   sleep 3
   sed -i "3s/.*/TAG=$v/g" $BASEDIR$GITDIR/update-patch.sh
   sudo chmod +x $BASEDIR$GITDIR/update-patch.sh
   sudo $BASEDIR$GITDIR/update-patch.sh
   if  [[ ! $? -eq 0 ]]; then
     echo "Update auf $v fehlgeschlagen"
     # Notify API that we've failed
     curl -sLk -XPOST https://localhost/update/status/ -H "Content-Type: application/json" -d '{"status":"failed"}' > /dev/null
     exit 1
   fi
   # successfully updated version
done
echo "Update auf $TAG abgeschlossen."
# set version in file
echo "VERSION=$TAG" > /home/amadmin/box4s/VERSION
# Notify API that we're finished
curl -sLk -XPOST https://localhost/update/status/ -H "Content-Type: application/json" -d '{"status":"successful"}' > /dev/null
# Prepare new update.sh for next update
sudo chown amadmin:amadmin $BASEDIR$GITDIR/main/update.sh
sudo chmod +x $BASEDIR$GITDIR/main/update.sh
exit $?
