#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "Update-Prozess erfordert Root-Privilegien." 1>&2
  exit 1
fi
if [[ $BASEDIR == "" ]];then
        echo " Bitte Variablen in /etc/environment setzen. -> EXIT"
        exit 0;
fi

if [[ $1 == "--help" ]] || [[ $1 == "-h" ]];then
	echo "--only-elastic -> Update System and Elastic + Plugins, omit Evebox, suricata"
	echo "please REMEMBER OPENVAS is from Repositorys now"
	exit 0
fi

# ELK
if [[ $1 != "--only-elastic" ]]; then

#TODO Elasticseach not upgrade
apt-get update
apt-get upgrade -Vy
if [[ $1 == "--update-unused" ]];then
cd $BASEDIR
mkdir -p evebox
# fetch newest Evebox Version from https://evebox.org/files/release/latest/
# Regex: evebox-[0-9.]+-linux-x64\.zip
EVEBOX_URL="https://evebox.org/files/release/latest/"
EVEBOX_FILE=$(curl -s "https://evebox.org/files/release/latest/" | sed -n 's/.*href="\(evebox-[0-9.]\+-linux-x64\.zip\)".*/\1/p')
EVEBOX_FOLDER=$(echo $EVEBOX_FILE | sed -n 's/\.zip$//p')
curl -OLs "$EVEBOX_URL$EVEBOX_FILE"
unzip -u $EVEBOX_FILE
chown -R amadmin:amadmin $EVEBOX_FOLDER
echo "Please check Evebox Config Differences and update /etc/evebox/evebox.yaml accordingly (by hand)."
diff /etc/evebox/evebox.yaml $EVEBOX_FOLDER/evebox.yaml.example
cp $EVEBOX_FOLDER/evebox /usr/local/bin/evebox
echo '### Upgraded Evebox ###'

cd $BASEDIR
# Dependencies: https://suricata.readthedocs.io/en/suricata-4.1.0-rc2/install.html#dependencies
mkdir -p suricata && cd suricata
# If this does not work anymore suricata have updated their site :/
SURICATA_VER=$(curl -s "https://suricata-ids.org/download/" | awk '/<strong>Stable<\/strong><\/td>/,/<\/tr>/' |  sed -n 's/.*<a title="\([0-9.]\+\)".*/\1/p')
SURICATA_INSTALLED_VER=$(suricata -V | grep -oE "[0-9.]+")
echo "### Installed: Suricata $SURICATA_INSTALLED_VER ###"
echo "### Available: Suricata $SURICATA_VER ###"
if [[ $SURICATA_INSTALLED_VER == $(echo -e "$SURICATA_VER\n$SURICATA_INSTALLED_VER" | sort -Vr |head -n1) ]]; then
  # newest version installed
  echo "### Suricata is already up to date at version $SURICATA_INSTALLED_VER ###"


  # new version available, updating
  echo "### Downloading Suricata Stable Version $SURICATA_VER ###"
  SURICATA_URL="https://www.openinfosecfoundation.org/download/suricata-$SURICATA_VER.tar.gz"
  curl -OLs "$SURICATA_URL"
  tar xfv "suricata-$SURICATA_VER.tar.gz"
  cd suricata-$SURICATA_VER
  ./configure --prefix=/usr/ --sysconfdir=/etc  --localstatedir=/var
  make
fi
  # make install
## update-obsolete
fi

suricata-update update-sources
suricata-update list-sources
suricata-update
fi


echo "### For upgrading OpenVAS follow documented procedure in Git Wiki. ###"
echo "OpenVAS Install omited but NVTs are updated"
#cd /home/amadmin/qc_git
#git clone https://github.com/greenbone/gvm-libs.git
#cd gvm-libs
#cmake .
#make instalcd /home/amadmin/qc_git
#git clone https://github.com/greenbone/gvm-libs.git
#cd gvm-libs
#cmake .
#make installl
# cp $BASEDIR/$GITDIR/OpenVAS/openvas-scanner.service /lib/systemd/system/ 
echo "Aktualisiere Schwachstellendatenbank"
sudo openvas-feed-update --verbose --progress
sudo greenbone-nvt-sync --verbose --progress
sudo greenbone-certdata-sync --verbose --progress && sudo greenbone-scapdata-sync --verbose --progress
sudo openvasmd --update --verbose --progress

#copy configs -> Maybe for later configupdatescript
#cp $BASEDIR/$GITDIR/Logstash/*.conf /etc/logstash/conf.d/
#cp $BASEDIR/$GITDIRfilebeat/modules.d/*.yml /etc/filebeat/modules.d/
#sudo cp  /home/amadmin/qc_git/siem/etc/interfaces /etc/network/

# Restart
# in 7.0 als Modul
#/usr/share/elasticsearch/bin/elasticsearch-plugin remove ingest-geoip
#/usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-geoip
#/usr/share/elasticsearch/bin/elasticsearch-plugin remove ingest-user-agent
#/usr/share/elasticsearch/bin/elasticsearch-plugin install ingest-user-agent
#Maybe at Version 7
#filebeat modules enable suricata


systemctl restart elasticsearch
systemctl restart kibana
echo "Install Plugins - remove failures are not fatal"
/usr/share/logstash/bin/logstash-plugin remove logstash-codec-nmap
/usr/share/logstash/bin/logstash-plugin install logstash-codec-nmap
/usr/share/logstash/bin/logstash-plugin remove logstash-filter-json_encode
/usr/share/logstash/bin/logstash-plugin install logstash-filter-json_encode
/usr/share/logstash/bin/logstash-plugin remove logstash-output-jdbc
/usr/share/logstash/bin/logstash-plugin install logstash-output-jdbc
/usr/share/logstash/bin/logstash-plugin remove logstash-filter-ip2location
/usr/share/logstash/bin/logstash-plugin install logstash-filter-ip2location
#/usr/share/logstash/bin/logstash-plugin remove logstash-filter-jdbc_streaming
#/usr/share/logstash/bin/logstash-plugin install logstash-filter-jdbc_streaming
#sudo /usr/share/logstash/bin/logstash-plugin remove logstash-input-jdbc
#sudo /usr/share/logstash/bin/logstash-plugin install logstash-input-jdbc


echo "Restarting Services"
systemctl restart logstash
systemctl restart filebeat
#systemctl restart packetbeat ##commented out because we need no packetbat atm
systemctl restart nginx
systemctl restart suricata #ggfs. Interface eintragen
systemctl restart heartbeat-elastic
exit

