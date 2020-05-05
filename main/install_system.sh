#!/bin/bash

# Es muss eine Disk im Installer auf /data angelegt werden
# Der User amadmin muss eingerichtet und verwendet werden.

# Log file to use
LOG_FILE="/var/log/installScript.log"
if [[ ! -w $LOG_FILE ]]; then
  LOG_FILE="/home/amadmin/installScript.log"
fi

# Please no interaction
export DEBIAN_FRONTEND=noninteractive

# Little help text to display if something goes wrong
myINFO="\
###########################################
### Box4s Installer                     ###
###########################################
Disclaimer:
This script will install the Box4Security on this system.
By running the script you know what you are doing:
1. Your box will get new packages
2. A new folder called '/data' will be created in your root directory
3. A new sudo user called 'amadmin' will be created on this system
########################################
Usage:
        sudo $0
Options:
        sudo $0 --manual - All available tags will be available for install - All of them."

##################################################
#                                                #
# Functions                                      #
#                                                #
##################################################

# This needs toilet to be installed
function banner {
  toilet -f ivrit "$1"
}

# Do we have root?
function gotRoot {
  echo
  echo -n "### Checking for root: "
  if [ "$(whoami)" != "root" ];
    then
      echo "[ NOT OK ]"
      echo "### Please run as root."
      echo "### Example: sudo $0"
      exit
    else
      echo "[ OK ]"
  fi
}

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

##################################################
#                                                #
# Dependencies                                   #
#                                                #
##################################################

# Remove services, that might be present, but are not needed
systemctl stop apache2 nginx
apt-fast purge -y apache2 nginx

# Lets make sure some basic tools are available
CURL=$(which curl)
WGET=$(which wget)
SUDO=$(which sudo)
TOILET=$(which toilet)
if [ "$CURL" == "" ] || [ "$WGET" == "" ] || [ "$SUDO" == "" ] || [ "$TOILET" == "" ]
  then
    waitForNet
    echo "### Installing deps for apt-fast"
    apt -y update
    apt -y install curl wget sudo toilet
fi

# Lets install apt-fast for quick package installation
waitForNet
echo "### Installing apt-fast"
/bin/bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"

# Lets install all dependencies
waitForNet
echo "### Installing all dependencies"
sudo apt-fast install -y curl python python-pip python3 python3-pip git git-lfs openconnect jq docker.io apt-transport-https msmtp msmtp-mta landscape-common
git lfs install

# Fetch all TAGS as names
waitForNet gitlab.am-gmbh.de
mapfile -t TAGS < <(curl -s https://gitlab.am-gmbh.de/api/v4/projects/it-security%2Fb4s/repository/tags --header "PRIVATE-TOKEN: p3a72xCJnChRkMCdUCD6" | jq -r .[].name)

if [[ "$*" == *manual* ]]
then
  # --manual supplied => ask user which to install
  echo "Verfügbare Tags:"
  printf '%s\n' "${TAGS[@]}"
  echo "Welcher soll installiert werden?"
  read TAG
  while [[ ! " ${TAGS[@]} " =~ " ${TAG} " ]]; do
    echo "$TAG ist nicht in ${TAGS[@]}. Erneut probieren."
    read TAG
  done
  echo "$TAG wird installiert."
else
  # not manual, install most recent and valid tag
  TAG=$(curl -s https://gitlab.am-gmbh.de/api/v4/projects/it-security%2Fb4s/repository/tags --header "PRIVATE-TOKEN: p3a72xCJnChRkMCdUCD6" | jq -r '[.[] | select(.name | contains("-") | not)][0] | .name')
  echo "Tag $TAG als aktuellsten, freigegebenen Tag gefunden."
fi

# Redirect STDOUT to LOG_FILE
exec 1>>$LOG_FILE && exec 2>&1


cd /home/amadmin
waitForNet gitlab.am-gmbh.de
git clone https://cMeyer:p3a72xCJnChRkMCdUCD6@gitlab.am-gmbh.de/it-security/b4s.git box4s -b $TAG

# Docker installieren mit docker-compose
sudo curl -sL "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Setup for Elasticsearch
sudo mkdir /data/elasticsearch -p
sudo mkdir /data/elasticsearch_backup/Snapshots -p
sudo chmod 777 /data/elasticsearch*

# Copy certificates over
sudo mkdir -p /etc/nginx/certs
sudo chown root:root /etc/nginx/certs
sudo cp /home/amadmin/box4s/main/ssl/*.pem /etc/nginx/certs
sudo chmod 744 -R /etc/nginx/certs # TODO: insecure

cd /home/amadmin/box4s
sudo cp main/etc/etc_files/* /etc/ -R
sudo cp main/home/* /home/amadmin -R

# Prepare launch of script after reboot
sudo bash -c 'crontab -l > /tmp/crontab.root'
sudo bash -c 'echo SHELL=/bin/bash >> /tmp/crontab.root'
ESCAPED_LOG_FILE=$(echo $LOG_FILE | sed 's/\//\\\//g')
cp /home/amadmin/box4s/main/install_system_after_reboot.sh /home/amadmin/
sudo chmod +x /home/amadmin/install_system_after_reboot.sh
sed -i '2s/.*$/LOG_FILE="'$ESCAPED_LOG_FILE'"/g' /home/amadmin/install_system_after_reboot.sh
sed -i '3s/.*$/BRANCH="'$TAG'"/g' /home/amadmin/install_system_after_reboot.sh
LOADER="@reboot /home/amadmin/install_system_after_reboot.sh"
echo $LOADER | sudo tee -a /tmp/crontab.root
sudo crontab /tmp/crontab.root
sudo rm /tmp/crontab.root
echo "Setze Interfaces"
# Find dhcp and remove everything after
sudo cp /home/amadmin/box4s/main/etc/network/interfaces /etc/network/interfaces
sudo sed -i '/.*dhcp/q' /etc/network/interfaces
# Set MGMT interface for dhcp section
# [DF] TODO: Commando ip wrorg. Use: cat /proc/net/dev -> dhcp is set by ubuntu setup. Not necessary
# [DF] TODO: Use: cat /proc/net/dev
IF_MGMT=$(ip addr | cut -d ' ' -f2| tr ':' '\n' | awk NF | grep -v lo | head -n 1)
awk "NR==1,/auto ens[0-9]*/{sub(/auto ens[0-9]*/, \"auto $IF_MGMT\")} 1" /etc/network/interfaces > /tmp/4s-ifaces
sudo mv /tmp/4s-ifaces /etc/network/interfaces
awk "NR==1,/iface ens[0-9]* inet dhcp/{sub(/iface ens[0-9]* inet dhcp/, \"iface $IF_MGMT inet dhcp\")} 1" /etc/network/interfaces > /tmp/4s-ifaces
echo 'dns-nameservers 127.0.0.53' >> /tmp/4s-ifaces
sudo mv /tmp/4s-ifaces /etc/network/interfaces

# Set other interfaces
for iface in $(ip addr | cut -d ' ' -f2| tr ':' '\n' | awk NF | grep -v lo | tail -n +2)
do
  echo "auto $iface
iface $iface inet manual
    up ifconfig $iface promisc up
    down ifconfig $iface promisc down" | sudo tee -a /etc/network/interfaces
done

waitForNet
pip3 install semver
apt install -y python3-venv unzip

sudo systemctl stop irqbalance
sudo systemctl disable irqbalance

# Portmirror Interface für Suricata auslesen
touch /home/amadmin/box4s/docker/suricata/.env
#Add Int IP
echo "Initialisiere Systemvariablen"
echo
echo
IPINFO=$(ip a | grep -E "inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "host lo")
IPINFO2=$(echo $IPINFO | awk  '{print substr($IPINFO, 6, length($IPINFO))}')
INT_IP=$(echo $IPINFO2 | sed 's/\/.*//')
echo INT_IP="$INT_IP" | sudo tee -a /etc/default/logstash /etc/environment
source /etc/environment

IFACE=$(sudo ip addr | cut -d ' ' -f2 | tr ':' '\n' | awk NF | grep -v lo | sed -n 2p | cat)
echo "SURI_INTERFACE=$IFACE" > /home/amadmin/box4s/docker/suricata/.env

# Service für automatische VPN-Verbindung einfügen
sudo pkill -f openconnect # Send CTRL+C signal to all openconnect

waitForNet
sudo apt install -y resolvconf

# DNSMASQ Setup
sudo systemctl disable systemd-resolved

# How to set a dns server in ubuntu 19.10 ;)
sudo systemctl enable resolvconf
echo "nameserver 127.0.0.1" > /etc/resolvconf/resolv.conf.d/head

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

waitForNet "gitlab.am-gmbh.de"
# Login bei der Docker-Registry des GitLabs und Download der Container
waitForNet docker-registry.am-gmbh.de
sudo docker login docker-registry.am-gmbh.de -u deployment-token-box -p KPLm6mZJFzuA9QY9oCZC

# Erstelle das Volume für die Daten
sudo docker volume create --driver local --opt type=none --opt device=/data --opt o=bind data

# Erstelle Volumes für Suricata
sudo mkdir -p /var/lib/suricata
sudo chown root:root /var/lib/suricata
sudo chmod -R 777 /var/lib/suricata
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/suricata/ --opt o=bind varlib_suricata

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

# Erstelle Volume für Openvas
sudo mkdir -p /var/lib/openvas
sudo chown root:root /var/lib/openvas
sudo chmod -R 777 /var/lib/openvas
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/openvas/ --opt o=bind varlib_openvas

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

# Install postgresql client to interact with db
sudo apt-get install -y postgresql-client

# Ermittle ganzzahligen RAM in GB (abgerundet)
MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM=$(python3 -c "print($MEM/1024.0**2)")
# Die Häfte davon soll Elasticsearch zur Verfügung stehen, abgerundet
ESMEM=$(python3 -c "print(int($MEM*0.5))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${ESMEM}g -Xmx${ESMEM}g/g" /home/amadmin/box4s/docker/.env.es
# 1/4 davon für Logstash, abgerundet
LSMEM=$(python3 -c "print(int($MEM*0.25))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${LSMEM}g -Xmx${LSMEM}g/g" /home/amadmin/box4s/docker/.env.ls

# Pull die Images
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull
sudo systemctl stop systemd-resolved
sudo systemctl start resolvconf
sudo cp /home/amadmin/box4s/docker/dnsmasq/resolv.personal /var/lib/box4s/resolv.personal

# Starte den Dienst
sudo systemctl start box4security

# Erlaube Scripts
chmod +x -R $BASEDIR$GITDIR/scripts

#Installation Dashboards
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
sleep 20
# Install the scores index
cd /home/amadmin/box4s/scripts/Automation/score_calculation/
./install_index.sh
cd /home/amadmin/box4s

# sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh db
# echo "Installing FetchQC"
# cd /home/amadmin/box4s
# cd FetchQC
# pip install -r requirements.txt
# alembic upgrade head # Prepare DB

echo "Install Crontab"
cd /home/amadmin/box4s/main/crontab
su - amadmin -c "crontab /home/amadmin/box4s/main/crontab/amadmin.crontab"
sudo crontab root.crontab

source /etc/environment
echo KUNDE="NEWSYSTEM" | sudo tee -a /etc/default/logstash
sudo systemctl daemon-reload

#Ignore own INT_IP
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh db
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('"$INT_IP"',0,'0.0.0.0',0,'');" | PGPASSWORD=zgJnwauCAsHrR6JB PGUSER=postgres psql postgres://localhost/box4S_db
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('0.0.0.0',0,'"$INT_IP"',0,'');" | PGPASSWORD=zgJnwauCAsHrR6JB PGUSER=postgres psql postgres://localhost/box4S_db

echo "Installiere Elastic Curator"
waitForNet
pip3 install elasticsearch-curator --user

sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana
#wait for 6 minutes and 40 seconds until kibana and wazuh have started to insert patterns
sleep 400
# Import Dashboard
echo "Installiere Dashboards"
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Startseite/Startseite-Uebersicht.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-Alarme.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-ASN.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-DNS.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-HTTP.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-ProtokolleUndDienste.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-SocialMedia.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/SIEM/SIEM-Uebersicht.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-Uebersicht.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-GeoIPUndASN.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Netzwerk/Netzwerk-Datenfluesse.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Details.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Schwachstellen/Schwachstellen-Uebersicht.ndjson

# Installiere Suricata Index Pattern
curl  -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/main/dashboards/Patterns/suricata.ndjson

#sudo systemctl restart networking
echo "BOX4security installiert."

# Lets update both openvas and suricata
sudo docker exec suricata /root/scripts/update.sh > /dev/null
sudo docker exec openvas /root/update.sh > /dev/null
