#!/bin/bash
#
# Placeholder for TAG=
# The Tag will be the highest version, so the goal of the update
CURVER=$(head -n1 /home/amadmin/VERSION)
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
    echo "No internet connectivity or dns resolution, sleeping for 15s"
    sleep 15s
  done
}
#Die Sleep Anweisungen dienen nur der Demo und können entfernt werden
exec 1>/var/www/kibana/html/update/updateStatus.log && exec 2>/var/www/kibana/html/update/updateStatus.log
sleep 2

VERSIONS=()
# Use Python Script to create array of versions that have to be installed
# versions between current and the latest
cd $BASEDIR$GITDIR/BOX4s-main
waitForNet gitlab.am-gmbh.de
mapfile -t VERSIONS < <(curl -s https://gitlab.am-gmbh.de/api/v4/projects/it-security%2Fb4s/repository/tags --header "PRIVATE-TOKEN: p3a72xCJnChRkMCdUCD6" | python3 update.py)
TAG=${VERSIONS[-1]}
echo "Aktualisierung auf $TAG über alle zwischenliegenden Versionen gestartet."
for v in "${VERSIONS[@]}"
do
   echo "Installiere Version v$v"
   cd $BASEDIR$GITDIR
   waitForNet gitlab.am-gmbh.de
   git fetch
   git checkout -f $TAG
   git pull
   sleep 3
   echo "Führe Updateanweisungen aus Version v$v aus"
   sed -i "3s/.*/TAG=$TAG/g" $BASEDIR$GITDIR/update-patch.sh
   sudo chmod +x $BASEDIR$GITDIR/update-patch.sh
   sudo $BASEDIR$GITDIR/update-patch.sh
   if  [[ ! $? -eq 0 ]]; then
     echo "Update auf $v fehlgeschlagen"
     break
   fi
done
sleep 2
echo "Update auf $TAG abgeschlossen."
# Prepare new update.sh for next update
sudo chown www-data:www-data $BASEDIR$GITDIR/BOX4s-main/update.sh
sudo chmod +x $BASEDIR$GITDIR/BOX4s-main/update.sh
echo $TAG > /home/amadmin/VERSION
exit $?
