#!/bin/bash
#
# Placeholder for TAG=
# The Tag will be the highest version, so the goal of the update

#Die Sleep Anweisungen dienen nur der Demo und können entfernt werden
exec 1>/var/www/kibana/html/update/updateStatus.log && exec 2>/var/www/kibana/html/update/updateStatus.log
trap 'echo "ABBRUCH"'  1 2 3 15
echo "Dieses Script aktualisiert das System"
sleep 2
cd /home/amadmin/box4s/
if [ $TAG == "" ]
then
if [ $1 != ""]
then
        $TAG=$1
        else
                echo "Tag wurde nicht gesetzt"
                echo "ABBRUCH"
                exit 1
fi
fi
echo "Hole neue GIT Daten von Version $TAG"
git fetch
# Force checkout to Tag, discards local changes!
git checkout -f $TAG
git pull
sleep 5;
echo "Starte Systemaktualisierung"
sed -i '3s/.*$/$TAG=\"'$TAG'\"/g' /home/amadmin/box4s/update-patch.sh
sudo chmod +x /home/amadmin/box4s/update-patch.sh
sudo ./update-patch.sh
#Diese letzte Meldung MUSS ausgegeben werden, damit das Frontend weiß, dass das Update abgeschlossen ist.
#Das sleep sollte hier dirn bleiben
sleep 2
sudo chown www-data:www-data $BASEDIR$GITDIR/BOX4s-main/update.sh
sudo chmod +x $BASEDIR$GITDIR/BOX4s-main/update.sh
echo " "
echo "<br>Update abgeschlossen<br>"
