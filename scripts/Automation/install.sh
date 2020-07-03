#!/bin/bash
set -e
# Log file to use
# Create path if allowed or do NOP
mkdir -p /var/log/box4s/ || :
LOG_FILE="/var/log/box4s/install"
if [[ ! -w $LOG_FILE ]]; then
  LOG_FILE="$HOME/install"
fi

# Please no interaction
export DEBIAN_FRONTEND=noninteractive

# Little help text to display if something goes wrong
HELP="\


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

function printHelp() {
  toilet -f ivrit 'BOX4security' | boxes -d cat -a hc -p h8 | lolcat
  echo "$HELP"
}

# Lets make sure some basic tools are available
CURL=$(which curl) || echo ""
WGET=$(which wget) || echo ""
SUDO=$(which sudo) || echo ""
TOILET=$(which toilet) || echo ""
if [ "$CURL" == "" ] || [ "$WGET" == "" ] || [ "$SUDO" == "" ] || [ "$TOILET" == "" ]
  then
    waitForNet
    echo "### Installing deps for apt-fast"
    apt -y update
    apt -y install curl wget sudo toilet figlet
fi

##################################################
#                                                #
# Dependencies                                   #
#                                                #
##################################################
banner "Dependencies ..."

# Are we root?
echo -n "### Checking for root: "
if [ "$(whoami)" != "root" ];
  then
    echo "[ NOT OK ]"
    echo "### Please run as root."
    printHelp
    exit 1
  else
    echo "[ OK ]"
fi

echo "### Setting up the environment"
# Source the secrets relatively
source ../../config/secrets/secrets.conf
# Create the user 'amadmin' only if he does not exist
# The used password is known to the whole dev-team
id -u $HOST_USER &>/dev/null || sudo useradd -m -p $HOST_PASS -s /bin/bash $HOST_USER
sudo usermod -aG sudo $HOST_USER
echo "$HOST_USER ALL=NOPASSWD:/home/amadmin/restartSuricata.sh, /home/amadmin/box4s/update-patch.sh,  /home/amadmin/box4s/main/update.sh" >> /etc/sudoers

# Create the /data directory if it does not exist and make it readable
sudo mkdir -p /data
sudo chown root:root /data
sudo chmod 777 /data

# Create Box4s Log Path
sudo mkdir -p /var/log/box4s/
sudo touch /var/log/box4s/update.log

# Lets install apt-fast for quick package installation
waitForNet
echo "### Installing apt-fast"
sudo /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"

# Remove services, that might be present, but are not needed.
# But don't fail if they arent.
echo "### Removing some services"
sudo systemctl disable apache2 nginx systemd-resolved || echo ""
sudo apt-fast remove --purge -y apache2 nginx

# Lets install all dependencies
waitForNet
echo "### Installing all dependencies"
sudo apt-fast install -y curl python python-pip python3 python3-pip python3-venv git git-lfs openconnect jq docker.io apt-transport-https msmtp msmtp-mta landscape-common unzip postgresql-client resolvconf boxes lolcat
git lfs install --skip-smudge
pip3 install semver elasticsearch-curator requests
curl -sL "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

##################################################
#                                                #
# Tags                                           #
#                                                #
##################################################
banner "Tags ..."

# Fetch all TAGS as names
mapfile -t TAGS < <(curl -s https://gitlab.com/api/v4/projects/4sconsult%2Fbox4s/repository/tags --header "PRIVATE-TOKEN: $GIT_API_TOKEN" | jq -r .[].name)

# If manual isntallation, make all tags visible and choose the tag to install
if [[ "$*" == *manual* ]]
then
  # --manual supplied => ask user which to install
  echo "Available tags:"
  printf '%s\n' "${TAGS[@]}"
  echo "Choose tag to install"
  read TAG
  while [[ ! " ${TAGS[@]} " =~ " ${TAG} " ]]; do
    echo "$TAG is not in ${TAGS[@]}. Try again."
    read TAG
  done
  echo "$TAG will be installed."
else
  # not manual, install most recent and valid tag
  TAG=$(curl -s https://gitlab.com/api/v4/projects/4sconsult%2Fbox4s/repository/tags --header "PRIVATE-TOKEN: $GIT_API_TOKEN" | jq -r '[.[] | select(.name | contains("-") | not)][0] | .name')
  echo "Tag $TAG is the most recent available tag."
fi

##################################################
#                                                #
# Clone Repository                               #
#                                                #
##################################################
banner "Repository ..."

#exec 1>>$LOG_FILE && exec 2>&1
exec 2> >(tee "$LOG_FILE.err")
exec > >(tee "$LOG_FILE.log")

cd /home/amadmin
git clone https://deploy:$GIT_DEPLOY_TOKEN@gitlab.com/4sconsult/box4s.git box4s -b $TAG

# Copy certificates over
sudo mkdir -p /etc/nginx/certs
sudo chown root:root /etc/nginx/certs
sudo cp /home/amadmin/box4s/config/ssl/box4security.cert.pem /etc/nginx/certs
sudo cp /home/amadmin/box4s/config/secrets/box4security.key.pem /etc/nginx/certs
sudo chmod 744 -R /etc/nginx/certs # TODO: insecure

##################################################
#                                                #
# Docker Volumes                                 #
#                                                #
##################################################
sudo systemctl start docker
banner "Volumes ..."

# Setup data volume
sudo docker volume create --driver local --opt type=none --opt device=/data --opt o=bind data

# Setup Suricata volume
sudo mkdir -p /var/lib/suricata
sudo chown root:root /var/lib/suricata
sudo chmod -R 777 /var/lib/suricata
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/suricata/ --opt o=bind varlib_suricata

# Setup Box4s volume
sudo mkdir -p /var/lib/box4s
sudo chown root:root /var/lib/box4s
sudo chmod -R 777 /var/lib/box4s
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s/ --opt o=bind varlib_box4s

# Setup PostgreSQL volume
sudo mkdir -p /var/lib/postgresql/data
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/postgresql/data --opt o=bind varlib_postgresql

# Setup Box4s Settings volume
sudo mkdir -p /etc/box4s/logstash
sudo cp -R /home/amadmin/box4s/config/etc/logstash/* /etc/box4s/logstash/
sudo chown root:root /etc/box4s/
sudo chmod -R 777 /etc/box4s/
sudo docker volume create --driver local --opt type=none --opt device=/etc/box4s/logstash/ --opt o=bind etcbox4s_logstash

# Setup Logstash volume
sudo mkdir -p /var/lib/logstash
sudo chown root:root /var/lib/logstash
sudo chmod -R 777 /var/lib/logstash
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/logstash/ --opt o=bind varlib_logstash

# Setup OpenVAS volume
sudo mkdir -p /var/lib/openvas
sudo chown root:root /var/lib/openvas
sudo chmod -R 777 /var/lib/openvas
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/openvas/ --opt o=bind varlib_openvas

# Setup Elasticsearch volume
sudo mkdir /data/elasticsearch -p
sudo mkdir /data/elasticsearch_backup/Snapshots -p
sudo chmod 777 /data/elasticsearch*

# Setup ElastAlert volume
sudo mkdir -p /var/lib/elastalert/rules
sudo chown root:root /var/lib/elastalert/rules
sudo chmod -R 777 /var/lib/elastalert/rules
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/elastalert/rules --opt o=bind varlib_elastalert_rules

# Setup Wiki volume
sudo mkdir -p /var/lib/box4s_docs
sudo chown root:root /var/lib/box4s_docs
sudo chmod -R 777 /var/lib/box4s_docs
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s_docs --opt o=bind varlib_docs

##################################################
#                                                #
# Installing Box                                 #
#                                                #
##################################################
banner "BOX4security ..."

# Initially clone the Wiki repo
cd /var/lib/box4s_docs
sudo git clone https://deploy:$GIT_DEPLOY_TOKEN@gitlab.com/4sconsult/docs.git .

# Copy gollum config to wiki root
cp /home/amadmin/box4s/docker/wiki/config.ru /var/lib/box4s_docs/config.ru

# Copy config files
cd /home/amadmin/box4s
sudo cp config/etc/etc_files/* /etc/ -R || :
sudo cp config/secrets/msmtprc /etc/msmtprc
sudo cp config/home/* /home/amadmin -R || :
sudo cp /home/amadmin/box4s/docker/elastalert/rules/* /var/lib/elastalert/rules/ || :

echo "### Setting up interfaces"
# Find dhcp and remove everything after
sudo cp /home/amadmin/box4s/config/etc/network/interfaces /etc/network/interfaces
sudo sed -i '/.*dhcp/q' /etc/network/interfaces

IF_MGMT=$(ip addr | cut -d ' ' -f2| tr ':' '\n' | awk NF | grep -v lo | head -n 1)
awk "NR==1,/auto ens[0-9]*/{sub(/auto ens[0-9]*/, \"auto $IF_MGMT\")} 1" /etc/network/interfaces > /tmp/4s-ifaces
sudo mv /tmp/4s-ifaces /etc/network/interfaces
awk "NR==1,/iface ens[0-9]* inet dhcp/{sub(/iface ens[0-9]* inet dhcp/, \"iface $IF_MGMT inet dhcp\")} 1" /etc/network/interfaces > /tmp/4s-ifaces
echo 'dns-nameservers 127.0.0.53' >> /tmp/4s-ifaces
sudo mv /tmp/4s-ifaces /etc/network/interfaces

# Apply the new config without a restart
ip link set $IF_MGMT down
ip link set $IF_MGMT up

# Set other interfaces
for iface in $(ip addr | cut -d ' ' -f2| tr ':' '\n' | awk NF | grep -v lo | tail -n +2)
do
  # dont apply this for tun0 or docker0
  if [[ "$iface" =~ ^(tun0|docker0)$ ]]; then
    continue;
  fi
  echo "auto $iface
    iface $iface inet manual
    up ifconfig $iface promisc up
    down ifconfig $iface promisc down" | sudo tee -a /etc/network/interfaces
  ip link set $iface down
  ip link set $iface up
done

echo "### Setup system variables"
IPINFO=$(ip a | grep -E "inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "host lo")
IPINFO2=$(echo $IPINFO | awk  '{print substr($IPINFO, 6, length($IPINFO))}')
INT_IP=$(echo $IPINFO2 | sed 's/\/.*//')
echo INT_IP="$INT_IP" | sudo tee -a /etc/default/logstash /etc/environment
source /etc/environment

# Find the portmirror interface for suricata
touch /home/amadmin/box4s/docker/suricata/.env
IFACE=$(sudo ip addr | cut -d ' ' -f2 | tr ':' '\n' | awk NF | grep -v lo | sed -n 2p | cat)
echo "SURI_INTERFACE=$IFACE" > /home/amadmin/box4s/docker/suricata/.env

# DNSMasq Setup
sudo systemctl disable systemd-resolved
sudo systemctl enable resolvconf
echo "nameserver 127.0.0.1" > /etc/resolvconf/resolv.conf.d/head

# Setup the new Box4Security Service and enable it
sudo cp /home/amadmin/box4s/config/etc/systemd/box4security.service /etc/systemd/system/box4security.service
sudo systemctl daemon-reload
sudo systemctl enable box4security.service

##################################################
#                                                #
# Docker Setup                                   #
#                                                #
##################################################
banner "Docker ..."

# Login to docker registry
echo "### Download docker images"
sudo docker login registry.gitlab.com -u deploy -p mPwNxthpxvmQSaZnv3xZ

# Download IP2Location DBs for the first time
echo "### Setup geolocation database"
cd /tmp/
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBIN" -o IP2LOCATION-LITE-DB5.BIN.zip
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBINIPV6" -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo unzip -o IP2LOCATION-LITE-DB5.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.BIN
sudo unzip -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.IPV6.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.IPV6.BIN

# Download wazuh clients
sudo sh /home/amadmin/box4s/scripts/Automation/download_wazuh_clients.sh 3.12.1

# Filter Functionality
echo "### Setting up suricata filter functionality"
sudo touch /var/lib/box4s/15_logstash_suppress.conf
sudo touch /var/lib/box4s/suricata_suppress.bpf
sudo chmod -R 777 /var/lib/box4s/

echo "### Detecting available memory and distribute it to the containers"
# Detect rounded memory
MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM=$(python3 -c "print($MEM/1024.0**2)")
# Give half of that to elasticsearch
ESMEM=$(python3 -c "print(int($MEM*0.5))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${ESMEM}g -Xmx${ESMEM}g/g" /home/amadmin/box4s/docker/elasticsearch/.env.es
# and one quarter to logstash
LSMEM=$(python3 -c "print(int($MEM*0.25))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${LSMEM}g -Xmx${LSMEM}g/g" /home/amadmin/box4s/docker/logstash/.env.ls

echo "### Download Docker images"
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull
hostname box4security
echo "127.0.0.1 box4security" >> /etc/hosts
sudo systemctl stop systemd-resolved
sudo systemctl start resolvconf
sudo cp /home/amadmin/box4s/docker/dnsmasq/resolv.personal /var/lib/box4s/resolv.personal

#Make new directory for cronjobchecker
sudo mkdir /var/log/cronchecker
sudo chown amadmin:amadmin /var/log/cronchecker

echo "### Make scripts executable"
chmod +x -R /home/amadmin/box4s/scripts

#Owner der Skripte zur score Berechnung anpassen
sudo chown -R amadmin:amadmin /home/amadmin/box4s/scripts/Automation/score_calculation/

##################################################
#                                                #
# Box4s start                                    #
#                                                #
##################################################
banner "Starting ..."

sudo systemctl start box4security

echo "### Wait for elasticsearch to become available ..."
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch

echo "### Install the scores index ..."
sleep 5
# Install the scores index
cd /home/amadmin/box4s/scripts/Automation/score_calculation/
./install_index.sh
cd /home/amadmin/box4s

echo "### Install new cronjobs ..."
cd /home/amadmin/box4s/config/crontab
su - amadmin -c "crontab /home/amadmin/box4s/config/crontab/amadmin.crontab"
sudo crontab root.crontab

source /etc/environment
echo KUNDE="NEWSYSTEM" | sudo tee -a /etc/default/logstash
sudo systemctl daemon-reload

# Acquire the db secrets
source /home/amadmin/box4s/config/db.conf

#Ignore own INT_IP
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh db
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('"$INT_IP"',0,'0.0.0.0',0,'');" | PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER psql postgres://localhost/box4S_db
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('0.0.0.0',0,'"$INT_IP"',0,'');" | PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER psql postgres://localhost/box4S_db

echo "### Wait for kibana to become available ..."
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana || echo ''

# Import Dashboard
echo "### Install dashboards"
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Startseite/Startseite-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-Alarme.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-ASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-DNS.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-HTTP.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-ProtokolleUndDienste.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-SocialMedia.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/SIEM/SIEM-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Netzwerk/Netzwerk-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Netzwerk/Netzwerk-GeoIPUndASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Netzwerk/Netzwerk-Datenfluesse.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Schwachstellen/Schwachstellen-Details.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Schwachstellen/Schwachstellen-Uebersicht.ndjson

# Installiere Suricata Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Patterns/suricata.ndjson

# Erstelle initialen VulnWhisperer Index
curl -XPUT "localhost:9200/logstash-vulnwhisperer-$(date +%Y.%m)"

toilet -f ivrit 'Ready!' | boxes -d cat -a hc -p h8 | /usr/games/lolcat
if [[ "$*" == *runner* ]]; then
# If in a runner environment exit now (successfully)
  exit 0
fi

echo "### Continue cleaning up and updating the tools"
sudo apt-fast autoremove -y
# Lets update both openvas and suricata
sudo docker exec suricata /root/scripts/update.sh > /dev/null
sudo docker exec openvas /root/update.sh > /dev/null
