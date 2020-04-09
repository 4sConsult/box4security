#!/bin/bash
# PLATZHALTER LOG_FILE
# PLAZHALTER BRANCH
#
#
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

if [ "$BRANCH" != "" ]; then
  TAG=$BRANCH
elif [ "$1" != "" ]; then
  TAG=$1
fi
if [[ ! -w $LOG_FILE ]]; then
  LOG_FILE="/home/amadmin/installScript.log"
fi
# Redirect STDOUT to LOG_FILE
exec 1>>$LOG_FILE && exec 2>>$LOG_FILE
waitForNet
pip3 install semver
cd /home/amadmin/box4s

sudo systemctl stop irqbalance
sudo systemctl disable irqbalance

echo "Installiere Suricata Deps"
waitForNet
sudo apt -y install clang llvm libelf-dev libc6-dev-i386 --no-install-recommends
waitForNet
sudo apt -y install python3-pip python3-venv

#install suricata deps
waitForNet
sudo apt -y install libtool pkg-config libghc-bzlib-dev libghc-readline-dev ragel cmake libyaml-dev libboost-dev libjansson-dev libpcap-dev libcap-ng-dev libnspr4-dev libnss3-dev  libmagic-dev libluajit-5.1-dev libmaxminddb-dev liblz4-dev rustc cargo
waitForNet
sudo apt -y install libhyperscan5

echo "Installiere PCRE"
sudo apt -y remove libpcre16* libpcre32*
mkdir -p /home/amadmin/suricata-src
cd /home/amadmin/suricata-src
waitForNet
wget  https://ftp.pcre.org/pub/pcre/pcre-8.43.zip
unzip pcre-8.43.zip
rm pcre-8.43.zip
cd pcre-8.43
./configure --prefix=/usr                     \
            --docdir=/usr/share/doc/pcre-8.43 \
            --enable-unicode-properties       \
            --enable-pcre16                   \
            --enable-pcre32                   \
            --enable-pcregrep-libz            \
            --enable-pcregrep-libbz2          \
            --enable-pcretest-libreadline     \
            --disable-static                 &&
make -j8
make install

echo "Installiere libbpf"
cd /home/amadmin/suricata-src
waitForNet
git clone https://github.com/libbpf/libbpf.git
cd libbpf/src/
make -j8
sudo make install
sudo make install_headers
sudo ldconfig

echo "Installiere Suricata"
cd /home/amadmin/suricata-src
waitForNet
git clone https://github.com/OISF/suricata.git --branch suricata-5.0.1 suricata-git
cd suricata-git

echo "Hole libhtp"
sudo apt remove -y libhtp2
waitForNet
git clone https://github.com/OISF/libhtp.git -b 0.5.x libhtp-git
cd libhtp-git

echo "Installiere libhtp"
./autogen.sh
./configure
make -j8
sudo make install
cd ..
cd ..

echo "Installiere Hyperscan"
waitForNet
git clone https://github.com/intel/hyperscan hyperscan-git
cd hyperscan-git
mkdir build
cd build
cmake -DBUILD_STATIC_AND_SHARED=1 ../
make -j8
make install
echo "/usr/local/lib" | sudo tee --append /etc/ld.so.conf.d/usrlocal.conf
sudo ldconfig

echo "Compile suricata"
cd /home/amadmin/suricata-src/suricata-git
./autogen.sh
./configure \
--prefix=/usr/ --sysconfdir=/etc/ --localstatedir=/var/ \
--enable-nfqueue --disable-gccmarch-native  --enable-non-bundled-htp --with-libhtp-includes=/usr/local/lib/ \
--enable-geoip --enable-gccprotect  --enable-luajit --enable-pie --enable-ebpf --enable-ebpf-build
make clean
make -j8

echo "Install suricata"
sudo make install
sudo make install-conf
sudo mkdir /data/suricata -p
sudo groupadd suri
sudo useradd suri -g suri
sudo mkdir -p /var/log/suricata
sudo mkdir -p /var/run/suricata
sudo chown suri:suri /data/suricata
sudo chown suri:suri /var/log/suricata
sudo chown suri:suri /var/run/suricata
echo "#Box4S Classification" | sudo tee -a /etc/suricata/classification.config
echo "config classification: foursconsult,BOX4security Custom Alerts,3" | sudo tee -a /etc/suricata/classification.config
# Install suricata update
cd ..
waitForNet
pip3 install suricata-update
cd /home/amadmin/box4s
cd Suricata
echo "Aktualisiere Angriffspattern"
waitForNet
/usr/local/bin/suricata-update update-sources
/usr/local/bin/suricata-update
/usr/local/bin/suricata-update enable-source et/open
/usr/local/bin/suricata-update enable-source oisf/trafficid
/usr/local/bin/suricata-update enable-source ptresearch/attackdetection
/usr/local/bin/suricata-update enable-source sslbl/ssl-fp-blacklist
#/usr/local/bin/suricata-update enable-source sslbl/ja3-fingerprints #need to be checked for necessary
/usr/local/bin/suricata-update enable-source etnetera/aggressive
/usr/local/bin/suricata-update enable-source tgreen/hunting
/usr/local/bin/suricata-update


sudo systemctl daemon-reload
sudo systemctl start suricata
sudo systemctl enable suricata

# Service für automatische VPN-Verbindung einfügen
sudo pkill -f openconnect # Send CTRL+C signal to all openconnect

sudo cp /home/amadmin/box4s/main/etc/systemd/vpn.service /etc/systemd/system/vpn.service
sudo systemctl daemon-reload
sudo systemctl enable vpn.service
sudo systemctl start vpn.service

# Kopiere den neuen Service an die richtige Stelle und enable den Service
sudo cp /home/amadmin/box4s/main/etc/systemd/box4security.service /etc/systemd/system/box4security.service
sudo systemctl daemon-reload
sudo systemctl enable box4security.service

# Sleep 5s to make sure the vpn is established
sleep 5
# Login bei der Docker-Registry des GitLabs und Download der Container
waitForNet docker-registry.am-gmbh.de
sudo docker login docker-registry.am-gmbh.de -u deployment-token-box -p KPLm6mZJFzuA9QY9oCZC
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull

# Erstelle das Volume für die Daten
sudo mkdir /var/lib/box4s
sudo docker volume create --driver local --opt type=none --opt device=/data --opt o=bind data

# Erstelle Volume für BOX4s Anwendungsdaten (/var/lib/box4s)
sudo mkdir -p /var/lib/box4s
sudo chown root:root /var/lib/box4s
sudo chmod -R 777 /var/lib/box4s
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s/ --opt o=bind varlib_box4s

# Erstelle Volume für PostgreSQL
sudo mkdir -p /var/lib/postgresql/data
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/postgresql/data --opt o=bind varlib_postgresql

# Erstelle Voume für dynamische Box4s Konfigurationen
sudo mkdir -p /etc/box4s/logstash
sudo cp -R /home/amadmin/box4s/main/etc/logstash/* /etc/box4s/logstash/
sudo chown root:root /etc/box4s/
sudo chmod -R 777 /etc/box4s/
sudo docker volume create --driver local --opt type=none --opt device=/etc/box4s/logstash/ --opt o=bind etcbox4s_logstash

# Erstelle Volume für Logstash
sudo mkdir /var/lib/logstash
sudo chown root:root /var/lib/logstash
sudo chmod -R 777 /var/lib/logstash
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/logstash/ --opt o=bind varlib_logstash

# Create BOX4s Log Path
sudo mkdir -p /var/log/box4s/
sudo touch /var/log/box4s/update.log

# Download IP2Location DBs for the first time
# IP2LOCATION Token
IP2TOKEN="MyrzO6sxNLvoSEaGtpXoreC1x50bRGmDfNd3UFBIr66jKhZeGXD7cg9Jl9VdQhQ5"
cd /tmp/
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBIN" -o IP2LOCATION-LITE-DB5.BIN.zip
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBINIPV6" -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo unzip -o IP2LOCATION-LITE-DB5.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.BIN
sudo unzip -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.IPV6.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.IPV6.BIN

# Filter Functionality
# create files
sudo touch /var/lib/box4s/15_logstash_suppress.conf
sudo touch /var/lib/box4s/suricata_suppress.bpf
sudo chmod -R 777 /var/lib/box4s/
# rm old links
sudo rm -f /etc/logstash/conf.d/suricata/15_kibana_filter.conf
# Copy updated Suricata Service
sudo cp /home/amadmin/box4s/Suricata/etc/systemd/system/suricata.service /etc/systemd/system/suricata.service
echo "Setze Suricata interfaces"
IFARRAY=()
# Caveat: This assumes that the first interface is the management one and all portmirror interfaces follow!
for iface in $(ip addr | cut -d ' ' -f2| tr ':' '\n' | awk NF | grep -v lo | tail -n +2)
do
	IFARRAY+=("$iface")
	IFSTRING+="--af-packet=$iface "
done
sudo cp * / -R
sed -i "s/--af-packet=ens[^ ]*//g" /etc/systemd/system/suricata.service
sed -i "s/\/etc\/suricata\/suricata.yaml /& $IFSTRING/" /etc/systemd/system/suricata.service
sudo systemctl daemon-reload
# Restart suricata
sudo systemctl restart suricata

#Add Int IP
echo "Initialisiere Systemvariablen"
echo
echo
IPINFO=$(ip a | grep -E "inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "host lo")
IPINFO2=$(echo $IPINFO | awk  '{print substr($IPINFO, 6, length($IPINFO))}')
INT_IP=$(echo $IPINFO2 | sed 's/\/.*//')
echo INT_IP="$INT_IP" | sudo tee -a /etc/default/logstash /etc/environment
source /etc/environment

# Install postgresql client to interact with db
sudo apt-get install -y postgresql-client-common postgresql-client

# Ermittle ganzzahligen RAM in GB (abgerundet)
MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM=$(python -c "print($MEM/1024.0**2)")
# Die Häfte davon soll Elasticsearch zur Verfügung stehen, abgerundet
ESMEM=$(python -c "print(int($MEM*0.5))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${ESMEM}g -Xmx${ESMEM}g/g" /home/amadmin/box4s/docker/.env.es
# 1/4 davon für Logstash, abgerundet
LSMEM=$(python -c "print(int($MEM*0.25))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${LSMEM}g -Xmx${LSMEM}g/g" /home/amadmin/box4s/docker/.env.ls

# DNSMASQ Setup
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo systemctl stop bind9
sudo systemctl disable bind9

# How to set a dns server in ubuntu 19.10 ;)
waitForNet
sudo apt install -y resolvconf
sudo systemctl enable resolvconf
echo "nameserver 127.0.0.1" > /etc/resolvconf/resolv.conf.d/head
sudo systemctl start resolvconf
sudo cp /home/amadmin/box4s/docker/dnsmasq/resolv.personal /var/lib/box4s/resolv.personal

# Starte den Dienst
sudo systemctl start box4security

# Erlaube Scripts
chmod +x -R $BASEDIR$GITDIR/scripts

#Installation Dashboards
echo "Install Dashboards"
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana
# Kibana eine Chance geben wirklich ready zu sein - Warte 20 Sekunden
sleep 20

# Install the scores index
cd /home/amadmin/box4s/scripts/Automation/score_calculation/
./install_index.sh
cd /home/amadmin/box4s

# Import Dashboards

curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Startseite/Startseite-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-Alarme.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-ASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-DNS.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-HTTP.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-ProtokolleUndDienste.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-SocialMedia.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-GeoIPUndASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-Datenfluesse.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Details.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Uebersicht.ndjson

# Installiere Suricata Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Patterns/suricata.ndjson

sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh db
echo "Installing FetchQC"
cd /home/amadmin/box4s
cd FetchQC
pip install -r requirements.txt
alembic upgrade head # Prepare DB

# Insert Config for scan without bruteforce to openvas
cd $BASEDIR$GITDIR/scripts/Automation
./run-OpenVASinsertConf.sh

echo "Install Crontab"
cd /home/amadmin/box4s/main/crontab
su - amadmin -c "crontab /home/amadmin/box4s/main/crontab/amadmin.crontab"
sudo crontab root.crontab

source /etc/environment
echo KUNDE="NEWSYSTEM" | sudo tee -a /etc/default/logstash
# Set INT-IP as --allow-header-host
sed -ie "s/--allow-header-host [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/--allow-header-host $INT_IP/g" /etc/systemd/system/greenbone-security-assistant.service
sudo systemctl daemon-reload

#Ignore own INT_IP
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('"$INT_IP"',0,'0.0.0.0',0,'');" | PGPASSWORD=zgJnwauCAsHrR6JB PGUSER=postgres psql postgres://localhost/box4S_db
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('0.0.0.0',0,'"$INT_IP"',0,'');" | PGPASSWORD=zgJnwauCAsHrR6JB PGUSER=postgres psql postgres://localhost/box4S_db

sudo chown suri:suri /data/suricata/ -R

echo "Installiere Elastic Curator"
waitForNet
pip3 install elasticsearch-curator --user

echo "Starte übrige Dienste"
sudo systemctl enable heartbeat-elastic
sudo systemctl enable suricata
sudo systemctl enable openvas-scanner
sudo systemctl enable openvas-manager
sudo systemctl enable greenbone-security-assistant
sudo systemctl start openvas-scanner openvas-manager greenbone-security-assistant heartbeat-elastic suricata

echo "Initialisiere Schwachstellendatenbank"
sudo greenbone-scapdata-sync --verbose --progress
sudo greenbone-certdata-sync --verbose --progress
sudo openvas-feed-update --verbose --progress
sudo greenbone-nvt-sync --verbose --progress
sudo openvasmd --update --verbose --progress
sudo openvasmd --rebuild

sudo systemctl restart greenbone-security-assistant

#sudo systemctl restart networking
echo "BOX4security installiert."
