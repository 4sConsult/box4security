#!/bin/bash
cd $BASEDIR/$GITDIR
for i in $(find $PWD -maxdepth 1 -type d);
do
cd $i
#echo $i
FOLDER=$(echo $i | awk  '{print substr($i, 27, length($i))}' )
if [[ $FOLDER != "" ]];
then

echo "Im Project: $FOLDER"

for sf in $(find $PD -maxdepth 1 -type d);
do
	SUBFOLDER=$(echo $sf | awk  '{print substr($i, 3, length($i))}')
	if [[ $SUBFOLDER != ".git" ]] && [[ $SUBFOLDER != "." ]] && [[ $SUBFOLDER != "" ]]; 
	then
			
#		echo "Im Projekt: $FOLDER"
		#echo $SUBFOLDER
		colordiff -ry /$SUBFOLDER/$FOLDER /home/amadmin/qc_git/siem/$FOLDER/$SUBFOLDER/ --suppress-common-lines | more
		echo "[S]ystemdaten ins GIT, [G]it ins System"
		read answer
		case $answer in
#HIER SOLLTE EIGENTLICH NUR DIE DATEI KOPIERT WERDEN DIE IM DIFF RAUSKAM 

			S*|s*) sudo cp -r /$SUBFOLDER/$FOLDER /home/amadmin/qc_git/siem/$FOLDER/$SUBFOLDER/ ;;
			G*|g*) echo "Anders herum lassen wir ersteinmal bitte erst ausgibig testen: sudo cp /home/amadmin/qc_git/siem/$FOLDER/$SUBFOLDER/ /$SUBFOLDER/$FOLDER" ;;
			*) echo "Mache gar nüscht"
		esac
	fi
done
#colordiff -ry /etc/logstash/ /home/amadmin/qc_git/siem/logstash/etc/logstash/ --suppress-common-lines | more
fi
done

