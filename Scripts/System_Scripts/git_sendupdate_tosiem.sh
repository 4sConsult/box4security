
if [ $# -ne 1 ];then
	echo "Bitte Parameter 1 Branch angeben"
	exit 1;
fi

#elasticsearch  filebeat   kibana    metricbeat  openvas     scripts   system
#fetch-qc       heartbeat  logstash  nginx       packetbeat  suricata
MESSAGE="Initialer Commit für v2. OS Update auf 19.04, Suricata Updata auf 1.4.2. und ein paar andere Änderungen"


cd $BASEDIR/$GITDIR

for i in $(find $PWD -maxdepth 1 -type d);
do
cd $i
git pull 
git add .
git commit 
git push 
cd ..

done

