#!/bin/bash
set -e

# Initial information

echo -e " ____   _____  ___  _                            _ _
| __ ) / _ \ \/ / || |  ___  ___  ___ _   _ _ __(_) |_ _   _
|  _ \| | | \  /| || |_/ __|/ _ \/ __| | | | '__| | __| | | |
| |_) | |_| /  \|__   _\__ \  __/ (__| |_| | |  | | |_| |_| |
|____/ \___/_/\_\  |_| |___/\___|\___|\__,_|_|  |_|\__|\__, |
                                                       |___/

Disclaimer:
This script will install the BOX4security on this system.
By running the script you confirm to know what you are doing:
1. New packages will be installed.
2. A new folder called '/data' will be created in your root directory.
3. A new sudo user called 'amadmin' will be created on this system.
4. The BOX4s service will be enabled.

#############################################
Usage:
sudo $0
Options:
sudo $0 --manual - All available tags will be available for install - All of them.\n"
# Check for root

if [ "$(whoami)" != "root" ];
  then
    echo "#####################################################
### Installation Requires Root. Please use 'sudo' ###
#####################################################"
    exit 1
  else
    echo "#####################################################
###    Starting BOX4security installation...      ###
#####################################################"
fi

# Log file to use
# Create path if allowed or do NOP
mkdir -p /var/log/box4s/ || :

# Determine log dir, if writable use /var/log else user's home.
LOG_DIR="/var/log/box4s"
if [[ ! -w $LOG_DIR ]]; then
  LOG_DIR="$HOME"
fi

sudo chown -R root:44269 $LOG_DIR
sudo chmod 760 -R $LOG_DIR

FULL_LOG=$LOG_DIR/install.log
ERROR_LOG=$LOG_DIR/install.err.log

# Do not use interactive debian frontend.
export DEBIAN_FRONTEND=noninteractive

# Get the actual dir of the installation script.
SCRIPTDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
INSTALL_DIR="/opt/box4s/"
CONFIG_DIR="/etc/box4s/"
# Forward fd3 to the console
# exec 3>&1
# Forward stderr to $ERROR_LOG
# exec 2> >(tee "$ERROR_LOG")
# Forward stdout to $FULL_LOG
# exec > >(tee "$FULL_LOG")
exec 3>&1 1>>${FULL_LOG} 2>>$ERROR_LOG
##################################################
#                                                #
# Functions                                      #
#                                                #
##################################################

# This needs toilet to be installed
function banner {
  toilet -f ivrit "$1" 1>&3
}

function testNet() {
  # Returns 0 for successful internet connection and dns resolution, 1 else
  ping -q -c 1 -W 1 $1 >/dev/null;
  return $?
}
function delete_If_Exists(){
  # Helper to delete files and directories if they exist
  if [ -d $1 ]; then
    # Directory to remove
    sudo rm $1 -r
  fi
  if [ -f $1 ]; then
    # File to remove
    sudo rm $1
  fi
}
function waitForNet() {
  # use argument or default value of google.com
  HOST=${1:-"google.com"}
  while ! testNet $HOST; do
    # while testNet returns non zero value
    echo "No internet connectivity or dns resolution of $HOST, sleeping for 15s" 1>&2
    sleep 15s
    echo /etc/resolv.conf | grep 'nameserver' || echo "nameserver 8.8.8.8" > /etc/resolv.conf && echo "Empty /etc/resolv.conf/ -> inserting 8.8.8.8" 1>&2
  done
}

# Helper to check if a service exists on the system
function service_exists() {
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}
function create_and_changePermission() {
  sudo touch $1
  sudo chown -R root:44269 $1
  sudo chmod 760 -R $1
}
function genSecret() {
    echo `tr -dc A-Za-z0-9 </dev/urandom | head -c 24`
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

echo -n "Creating the /data directory.. " 1>&3
# Create the /data directory if it does not exist and make it readable
sudo mkdir -p /data
sudo chown root:root /data
sudo chmod 777 /data
sudo mkdir -p /data/suricata/
sudo touch /data/suricata/eve.json
echo "[ OK ]" 1>&3

# Create update log
sudo touch /var/log/box4s/update.log

# Lets install apt-fast for quick package installation
waitForNet
echo -n "Installing apt-fast.. " 1>&3
sudo /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"
echo "[ OK ]" 1>&3
# Remove services, that might be present, but are not needed.
echo -n "Removing standard services.. " 1>&3

# Disable and remove Apache2
if service_exists apache2; then
    sudo service apache2 disable
    sudo apt-fast remove --purge -y apache2
fi

# Disable and remove Nginx
if service_exists nginx; then
    sudo service nginx disable
    sudo apt-fast remove --purge -y nginx
fi

# Disable systemd-resolved
if service_exists systemd-resolved; then
    sudo service systemd-resolved disable || :
fi
echo "[ OK ]" 1>&3

echo -n "Checking for an old version of BOX4security and stopping.. " 1>&3
# Remove old box4security service
if service_exists box4security; then
    sudo systemctl stop box4security.service
fi
echo "[ OK ]" 1>&3
# Lets install all dependencies
waitForNet
echo -n "Downloading and installing dependencies. This may take some time.. " 1>&3
sudo apt-fast install -y unattended-upgrades curl python python3 python3-pip python3-venv git git-lfs jq docker.io apt-transport-https msmtp msmtp-mta landscape-common unzip postgresql-client resolvconf boxes lolcat secure-delete
echo "[ OK ]" 1>&3

echo -n "Enabling git lfs.. " 1>&3
# Check if .git exists in /tmp/box4s - if it doesn't then not initial install and skip
git lfs install --skip-smudge
echo "[ OK ]" 1>&3

echo -n "Installing Python3 modules from PyPi.. " 1>&3
pip3 install semver requests
echo "[ OK ]" 1>&3

echo -n "Installing Docker-Compose.. " 1>&3
# Remove old docker-compose if found
delete_If_Exists /usr/local/bin/docker-compose
curl -sL "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo "[ OK ]" 1>&3

# Change to repo root path
cd $SCRIPTDIR/../../
echo -n "Sourcing secret files.. " 1>&3
source config/secrets/secrets.conf
source config/secrets/db.conf
echo "[ OK ]" 1>&3

echo -n "Checking and replacing default secrets.." 1>&3
if [[ -z $POSTGRES_PASSWORD || "$POSTGRES_PASSWORD" == "CHANGEME" ]]; then
    POSTGRES_PASSWORD=`genSecret`
fi
if [[ -z $IP2TOKEN || "$IP2TOKEN" == "GET_ME_FROM_IP2LOCATION.COM" ]]; then
    echo "[ FAIL ]" 1>&3
    echo "Installation requires a token for IP2Location. Go to https://lite.ip2location.com now and enter an API token below." 1>&3 
    echo "Tokens are not validated on this end. Make sure the entered token is correct, otherwise the installation WILL fail." 1>&3 
    read -p "IP2Location API Token:" $IP2TOKEN 1>&3 
fi
source config/secrets/web.conf
if [[ -z $SECRET_KEY || "$SECRET_KEY" == "CHANGEME" ]]; then
    SECRET_KEY=`genSecret`
fi
echo "[ OK ]" 1>&3

# Create the user $HOST_USER only if he does not exist
# The used password is known to the whole dev-team
echo -n "Creating BOX4security user on the host.. " 1>&3
id -u $HOST_USER &>/dev/null || sudo useradd -m -p $HOST_PASS -s /bin/bash $HOST_USER
sudo usermod -aG sudo $HOST_USER
grep -qxF "$HOST_USER ALL=(ALL) NOPASSWD: ALL" /etc/sudoers || echo "$HOST_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
cat /etc/group | grep boxforsecurity &>/dev/null || sudo addgroup --gid 44269 boxforsecurity # Create group if it does not exist
id -G $HOST_USER | grep 44229 &>/dev/null || sudo usermod -a -G boxforsecurity $HOST_USER # Add HOST_USER to created group if not in it
echo "[ OK ]" 1>&3

echo -n "Creating the installation directory ($INSTALL_DIR).. " 1>&3
delete_If_Exists $INSTALL_DIR
sudo mkdir -p $INSTALL_DIR
sudo chown amadmin:amadmin $INSTALL_DIR
echo "[ OK ]" 1>&3

echo -n "Creating the configuration directory ($CONFIG_DIR).. " 1>&3
delete_If_Exists $CONFIG_DIR
sudo mkdir -p $CONFIG_DIR
sudo chown amadmin:amadmin $CONFIG_DIR
echo "[ OK ]" 1>&3

##################################################
#                                                #
# Tags                                           #
#                                                #
##################################################
banner "Tags ..."

# If manual isntallation, make all tags visible and choose the tag to install
if [[ "$*" == *manual* ]]
then
  # --manual supplied => ask user which to install
  # Fetch all TAGS as names
  mapfile -t TAGS < <(curl -s -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/4sConsult/box4security/releases | jq -r .[].tag_name)

  echo "Available tags:" 1>&3
  printf '%s\n' "${TAGS[@]}" 1>&3
  echo "Type tag to install:" 1>&3
  read TAG
  while [[ ! " ${TAGS[@]} " =~ " ${TAG} " ]]; do
    echo "$TAG is not in ${TAGS[@]}. Try again." 1>&3
    read TAG
  done
  echo "$TAG will be installed.. [ OK ]" 1>&3
else
  # not manual, install most recent and valid tag
  TAG=$(curl -s -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/repos/4sConsult/box4security/releases/latest | jq -r '.tag_name')
  echo "Installing the most recent tag $TAG.. [ OK ]" 1>&3
fi
echo "Installing $TAG."
##################################################
#                                                #
# Clone Repository                               #
#                                                #
##################################################
banner "Repository ..."

echo -n "Downloading the repository @ $TAG" 1>&3
git clone --depth 1 --branch $TAG https://github.com/4sConsult/BOX4security $INSTALL_DIR
echo "[ OK ]" 1>&3

# Copy certificates over
echo -n "Creating selfsigned SSL certificate.. " 1>&3
sudo mkdir -p $CONFIG_DIR/certs
sudo openssl req -new -x509 -config $SCRIPTDIR/../../config/ssl/box4security-ssl.conf \
    -subj "/C=DE/ST=NRW/L=Dortmund/O=4sConsult GmbH/OU=IT Security/CN=BOX4security/emailAddress=box@4sconsult.de" \
    -newkey rsa:4096 -days 365 -nodes \
    -keyout $CONFIG_DIR/certs/box4security.key.pem  -out $CONFIG_DIR/certs/box4security.cert.pem
sudo chown -R root:44269 $CONFIG_DIR/certs
sudo chmod 770 -R $CONFIG_DIR/certs
echo "[ OK ]" 1>&3

# Copy the smtp.conf to the config directory
echo -n "Enabling SMTP config.. " 1>&3
sudo cp $SCRIPTDIR/../../config/secrets/smtp.conf $CONFIG_DIR/smtp.conf
echo "[ OK ]" 1>&3

##################################################
#                                                #
# Docker Volumes                                 #
#                                                #
##################################################
sudo systemctl start docker
banner "Volumes ..."

echo -n "Creating volumes and setting permissions.. " 1>&3

echo -n "data:" 1>&1
# Check if each volume exists before creating them; Skip if already created
# Setup data volume
sudo docker volume create --driver local --opt type=none --opt device=/data --opt o=bind data
sudo chown -R root:44269 /data
sudo chmod 760 -R /data
echo " [ DONE ] " 1>&1

# Setup Box4s volume
echo -n "varlib_box4s:" 1>&1
delete_If_Exists /var/lib/box4s_openvas/
sudo mkdir -p /var/lib/box4s
sudo chown root:root /var/lib/box4s
sudo chmod -R 777 /var/lib/box4s
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s/ --opt o=bind varlib_box4s
sudo chown -R root:44269 /var/lib/box4s
sudo chmod 760 -R /var/lib/box4s
echo " [ DONE ] " 1>&1

# Setup PostgreSQL volume
echo -n "varlib_postgresql:" 1>&1
delete_If_Exists /var/lib/postgresql
sudo mkdir -p /var/lib/postgresql/data
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/postgresql/data --opt o=bind varlib_postgresql
sudo chown -R root:44269 /var/lib/postgresql/data
sudo chmod 760 -R /var/lib/postgresql/data
echo " [ DONE ] " 1>&1

# Setup Suricata Rule volume
echo -n "varlib_suricata:" 1>&1
sudo mkdir -p /var/lib/box4s_suricata_rules/
sudo chown root:root /var/lib/box4s_suricata_rules/
sudo chmod -R 777 /var/lib/box4s_suricata_rules/
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s_suricata_rules/ --opt o=bind varlib_suricata
echo " [ DONE ] " 1>&1

# Setup Box4s Settings volume
echo -n "etcbox4s_logstash:" 1>&1
sudo mkdir -p $CONFIG_DIR/logstash
sudo cp -R $SCRIPTDIR/../../config/etc/logstash/* $CONFIG_DIR/logstash/
sudo chown root:root $CONFIG_DIR/logstash
sudo chmod -R 777 $CONFIG_DIR/logstash
sudo docker volume create --driver local --opt type=none --opt device=$CONFIG_DIR/logstash/ --opt o=bind etcbox4s_logstash
sudo chown -R root:44269 $CONFIG_DIR/logstash
sudo chmod 760 -R $CONFIG_DIR/logstash
echo " [ DONE ] " 1>&1

# Setup Logstash volume
echo -n "varlib_logstash:" 1>&1
delete_If_Exists /var/lib/logstash
sudo mkdir -p /var/lib/logstash
sudo mkdir -p /var/lib/logstash/openvas/
sudo chown root:root /var/lib/logstash
sudo chmod -R 777 /var/lib/logstash
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/logstash/ --opt o=bind varlib_logstash
sudo chown -R root:44269 /var/lib/logstash
sudo chmod 760 -R /var/lib/logstash
echo " [ DONE ] " 1>&1

# Setup OpenVAS volume
echo -n "varlib_postgresql:" 1>&1
sudo mkdir -p /var/lib/box4s_openvas/
sudo chown root:root /var/lib/box4s_openvas/
sudo chmod -R 777 /var/lib/box4s_openvas/
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s_openvas/ --opt o=bind gvm-data
sudo chown -R root:root /var/lib/box4s_openvas
echo " [ DONE ] " 1>&1

# Setup Elasticsearch volume
sudo mkdir /data/elasticsearch -p
sudo mkdir /data/elasticsearch_backup/Snapshots -p
# Elasticsearch is somewhat special...
sudo chown -R 1000:0 /data/elasticsearch
sudo chown -R 1000:0 /data/elasticsearch_backup
sudo chmod 760 -R /data/elasticsearch
sudo chmod 760 -R /data/elasticsearch_backup

# Setup ElastAlert volume
echo -n "varlib_postgresql:" 1>&1
sudo mkdir -p /var/lib/elastalert/rules
sudo chown root:root /var/lib/elastalert/rules
sudo chmod -R 777 /var/lib/elastalert/rules
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/elastalert/rules --opt o=bind varlib_elastalert_rules
sudo chown -R root:44269 /var/lib/elastalert/rules
sudo chmod 760 -R /var/lib/elastalert/rules
echo " [ DONE ] " 1>&1

# Setup Wiki volume
echo -n "varlib_docs:" 1>&1
sudo mkdir -p /var/lib/box4s_docs
sudo chown root:root /var/lib/box4s_docs
sudo chmod -R 777 /var/lib/box4s_docs
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s_docs --opt o=bind varlib_docs
sudo chown -R root:44269 /var/lib/box4s_docs/
sudo chmod 760 -R /var/lib/box4s_docs/
echo " [ DONE ] " 1>&1

#Done with volumes
echo "[ OK ]" 1>&3

echo -n "Initializing important files and setting permissions.. " 1>&3
create_and_changePermission /var/lib/box4s/elastalert_smtp.yaml
create_and_changePermission $CONFIG_DIR/smtp.conf
create_and_changePermission /etc/ssl/certs/ca-certificates.crt
create_and_changePermission /var/lib/box4s/elastalert_smtp.yaml
create_and_changePermission $CONFIG_DIR/modules.conf
create_and_changePermission /etc/ssl/certs/BOX4s-SMTP.pem

echo "[ OK ]" 1>&3
##################################################
#                                                #
# Installing Box                                 #
#                                                #
##################################################
banner "BOX4security ..."

echo -n "Setting environmental permissions.. " 1>&3
sudo mkdir -p /etc/netplan || :
sudo touch /etc/default/logstash || :
sudo touch /etc/environment || :
sudo chown -R root:44269 /etc/environment
sudo chmod 770 -R /etc/environment
sudo chown -R root:44269 /etc/default/logstash
sudo chmod 770 -R /etc/default/logstash
sudo chown -R root:44269 /etc/netplan
sudo chmod 770 -R /etc/netplan
echo " [ OK ]" 1>&3

echo -n "Setting hostname.. " 1>&3
hostname box4security
grep -qxF "127.0.0.1 box4security" /etc/hosts || echo "127.0.0.1 box4security" >> /etc/hosts
echo " [ OK ]" 1>&3

# Initially clone the Wiki repo
echo -n "Downloading documentation.. " 1>&3
# Delete already existing repository
delete_If_Exists /var/lib/box4s_docs
mkdir -p /var/lib/box4s_docs
cd /var/lib/box4s_docs
sudo git clone https://github.com/4sconsult/box4s-docs.git .
echo " [ OK ]" 1>&3

echo -n "Configuring BOX4s.. " 1>&3
# Copy gollum config to wiki root
cp $SCRIPTDIR/../../docker/wiki/config.ru /var/lib/box4s_docs/config.ru

# Copy version file
cp $SCRIPTDIR/../../VERSION /var/lib/box4s/VERSION

# Copy config files
cd $SCRIPTDIR/../../
sudo cp config/secrets/* $CONFIG_DIR
sed -i "s/SECRET_KEY=.*$/SECRET_KEY=$SECRET_KEY/g" $CONFIG_DIR/web.conf
sed -i "s/DATABASE_URL=.*$/DATABASE_URL=postgresql:\/\/$POSTGRES_USER:$POSTGRES_PASSWORD@db:$POSTGRES_PORT\/$POSTGRES_DB/g" $CONFIG_DIR/web.conf
sed -i "s/POSTGRES_PASSWORD=.*$/POSTGRES_PASSWORD=$POSTGRES_PASSWORD/g" $CONFIG_DIR/db.conf
sed .i "s/IP2TOKEN=.*$/IP2TOKEN=$IP2TOKEN/g" $CONFIG_DIR/secrets.conf
sudo cp config/etc/etc_files/* /etc/ -R || :
sudo cp config/secrets/msmtprc /etc/msmtprc
sudo chown root:44269 /etc/msmtprc
sudo chmod 770 /etc/msmtprc

# Create a folder for the alerting rules
sudo mkdir -p /var/lib/elastalert/rules

# Copy default elastalert smtp auth file
sudo cp $SCRIPTDIR/../../docker/elastalert/etc/elastalert/smtp_auth_file.yaml /var/lib/box4s/elastalert_smtp.yaml
echo " [ OK ]" 1>&3

echo -n "Setting system environment variables.. " 1>&3
set +e
IPINFO=$(ip a | grep -E "inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "host lo")
IPINFO2=$(echo $IPINFO | grep -o -P '(?<=inet)((?!inet).)*(?=ens|eth|eno|enp)')
INT_IP=$(echo $IPINFO2 | sed 's/\/.*//')
grep -qxF  INT_IP=$INT_IP /etc/environment || echo INT_IP=$INT_IP >> /etc/environment
grep -qxF BOX4s_CONFIG_DIR="$CONFIG_DIR" /etc/environment || echo BOX4s_CONFIG_DIR="$CONFIG_DIR" | sudo tee -a /etc/environment
grep -qxF BOX4s_INSTALL_DIR="$INSTALL_DIR" /etc/environment || echo BOX4s_INSTALL_DIR="$INSTALL_DIR" | sudo tee -a /etc/environment
source /etc/environment
grep -qxF  INT_IP="$INT_IP" /etc/default/logstash || echo INT_IP="$INT_IP" >> /etc/default/logstash
grep -qxF KUNDE="NEWSYSTEM" /etc/default/logstash || echo KUNDE="NEWSYSTEM" | sudo tee -a /etc/default/logstash
set -e
echo " [ OK ] " 1>&3

echo -n "Setting network configuration and restarting network.. " 1>&3
# Find dhcp and remove everything after
sudo cp $SCRIPTDIR/../../config/etc/network/interfaces /etc/network/interfaces
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

#Disable TCP Timestamps
grep -qxF "net.ipv4.tcp_timestamps = 0" /etc/sysctl.conf || echo "net.ipv4.tcp_timestamps = 0" >> /etc/sysctl.conf
sudo sysctl -p


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
echo " [ OK ] " 1>&3

echo -n "Setting the portmirror interface.. " 1>&3
# Find the portmirror interface for suricata
touch $CONFIG_DIR/.env.suri
IFACE=$(sudo ip addr | cut -d ' ' -f2 | tr ':' '\n' | awk NF | grep -v lo | sed -n 2p | cat)
echo "SURI_INTERFACE=$IFACE" > $CONFIG_DIR/.env.suri
echo " [ OK ] " 1>&3

echo -n "Enabling/Disabling Modules.. " 1>&3
# Remove old folder to avoid conflicts
sudo cp $SCRIPTDIR/../../config/etc/modules.conf $CONFIG_DIR/modules.conf
sudo chmod 444 $CONFIG_DIR/modules.conf
echo " [ OK ] " 1>&3

echo -n "Generating Wazuh Agent-Password.. " 1>&3
delete_If_Exists /var/lib/box4s/wazuh-authd.pass
strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 14 | tr -d '\n' > /var/lib/box4s/wazuh-authd.pass
sudo chmod 755 /var/lib/box4s/wazuh-authd.pass
echo " [ OK ] " 1>&3

echo -n "BOX4security service setup and enabling.. " 1>&3
# Setup the new Box4Security Service and enable it
sudo mkdir -p /usr/bin/box4s/
sudo cp $SCRIPTDIR/../../scripts/System_Scripts/box4s_service.sh /usr/bin/box4s/box4s_service.sh
sudo chmod +x /usr/bin/box4s/box4s_service.sh
sudo cp $SCRIPTDIR/../../config/etc/systemd/box4security.service /etc/systemd/system/box4security.service
sudo systemctl daemon-reload
sudo systemctl enable box4security.service
echo " [ OK ] " 1>&3

##################################################
#                                                #
# Docker Setup                                   #
#                                                #
##################################################
banner "Docker ..."

echo -n "Downloading BOX4security software images. This may take a long time.. " 1>&3
# Login to docker registry
sudo docker-compose -f $SCRIPTDIR/../../docker/box4security.yml pull
sudo docker-compose -f $SCRIPTDIR/../../docker/wazuh/wazuh.yml pull
echo " [ OK ] " 1>&3

# Download IP2Location DBs for the first time
echo -n "Downloading and unpacking geolocation database. This may take some time.. " 1>&3
cd /tmp/
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBIN" -o IP2LOCATION-LITE-DB5.BIN.zip
curl -sL "https://www.ip2location.com/download/?token=$IP2TOKEN&file=DB5LITEBINIPV6" -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo unzip -o IP2LOCATION-LITE-DB5.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.BIN
sudo unzip -o IP2LOCATION-LITE-DB5.IPV6.BIN.zip
sudo mv IP2LOCATION-LITE-DB5.IPV6.BIN /var/lib/box4s/IP2LOCATION-LITE-DB5.IPV6.BIN
echo " [ OK ] " 1>&3


# Filter Functionality
echo -n "Setting up BOX4security Filters.. " 1>&3
sudo touch /var/lib/box4s/15_logstash_suppress.conf
sudo touch /var/lib/box4s/suricata_suppress.bpf
sudo chmod -R 777 /var/lib/box4s/
echo " [ OK ] " 1>&3

echo -n "Detecting available memory and distributing it to the containers.. " 1>&3
# Detect rounded memory
MEM=$(grep MemTotal /proc/meminfo | awk '{print $2}')
MEM=$(python3 -c "print($MEM/1024.0**2)")
# Give half of that to elasticsearch
ESMEM=$(python3 -c "print(int($MEM*0.5))")
sed "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${ESMEM}g -Xmx${ESMEM}g/g" $SCRIPTDIR/../../docker/elasticsearch/.env.es > $CONFIG_DIR/.env.es
# and one quarter to logstash
LSMEM=$(python3 -c "print(int($MEM*0.25))")
sed "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${LSMEM}g -Xmx${LSMEM}g/g" $SCRIPTDIR/../../docker/logstash/.env.ls > $CONFIG_DIR/.env.ls
echo " [ OK ] " 1>&3

echo -n "Making scripts executable.. " 1>&3
chmod +x -R $INSTALL_DIR/scripts
echo " [ OK ] " 1>&3

echo -n "Enabling BOX4s internal DNS server.. " 1>&3
# DNSMasq Setup
sudo systemctl enable resolvconf.service
echo "nameserver 127.0.0.1" > /etc/resolvconf/resolv.conf.d/head
sudo cp $SCRIPTDIR/../../docker/dnsmasq/resolv.personal /var/lib/box4s/resolv.personal
# Fix DNS resolv permission
sudo chown root:44269 /var/lib/box4s/resolv.personal
sudo chmod 770 /var/lib/box4s/resolv.personal
sudo systemctl stop systemd-resolved
sudo systemctl start resolvconf.service
sudo resolvconf --enable-updates
sudo resolvconf -u
echo " [ OK ] " 1>&3

##################################################
#                                                #
# Box4s start                                    #
#                                                #
##################################################
banner "Starting BOX4security..."

sudo systemctl start box4security

echo -n "Waiting for Elasticsearch to become available.. " 1>&3
sudo $SCRIPTDIR/../../scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
echo " [ OK ] " 1>&3

echo -n "Installing the scores index.. " 1>&3
sleep 5
# Install the scores index

sudo docker exec core4s /bin/bash /core4s/scripts/Automation/score_calculation/install_index.sh
echo " [ OK ] " 1>&3

echo -n "Installing new cronjobs.. " 1>&3
cd $SCRIPTDIR/../../config/crontab
su - amadmin -c "crontab $SCRIPTDIR/../../config/crontab/amadmin.crontab"
echo " [ OK ] " 1>&3

sudo systemctl daemon-reload

#Ignore own INT_IP
echo -n "Enabling filter to ignore own IP.. " 1>&3
sudo $SCRIPTDIR/../../scripts/System_Scripts/wait-for-healthy-container.sh db
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('"$INT_IP"',0,'0.0.0.0',0,'');" | PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER psql postgres://localhost/box4S_db
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('0.0.0.0',0,'"$INT_IP"',0,'');" | PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER psql postgres://localhost/box4S_db
echo " [ OK ] " 1>&3

echo -n "Waiting for Kibana to become available.. " 1>&3
sleep 300
sudo $SCRIPTDIR/../../scripts/System_Scripts/wait-for-healthy-container.sh kibana 600 && echo -n " [ OK  " 1>&3 || echo -n " [ NOT OK " 1>&3
sleep 30
sudo $SCRIPTDIR/../../scripts/System_Scripts/wait-for-healthy-container.sh kibana 600 && echo "  OK ] " 1>&3 || echo "  NOT OK ] " 1>&3

# Import Dashboard
echo -n "Installing Dashboards und Patterns.. " 1>&3
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/Startseite/Startseite-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/SIEM/SIEM-Alarme.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/SIEM/SIEM-ASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/SIEM/SIEM-DNS.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/SIEM/SIEM-HTTP.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/SIEM/SIEM-ProtokolleUndDienste.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/SIEM/SIEM-SocialMedia.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/SIEM/SIEM-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/Netzwerk/Netzwerk-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/Netzwerk/Netzwerk-GeoIPUndASN.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/Netzwerk/Netzwerk-Datenfluesse.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/Schwachstellen/Schwachstellen-Details.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/Schwachstellen/Schwachstellen-Verlauf.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/Schwachstellen/Schwachstellen-Uebersicht.ndjson
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/System/docker.ndjson

# Installiere Suricata Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/Patterns/suricata.ndjson

# Installiere Scores Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@$SCRIPTDIR/../../config/dashboards/Patterns/scores.ndjson

# Erstelle initialen VulnWhisperer Index
curl -XPUT "localhost:9200/logstash-vulnwhisperer-$(date +%Y.%m)"
echo " [ OK ] " 1>&3

toilet -f ivrit 'Ready!' | boxes -d cat -a hc -p h8 | /usr/games/lolcat
if [[ "$*" == *runner* ]]; then
# If in a runner environment exit now (successfully)
  exit 0
fi

echo -n "Activating unattended (automatic) Ubuntu upgrades.. " 1>&3
printf 'APT::Periodic::Update-Package-Lists "1";\nAPT::Periodic::Unattended-Upgrade "1";' > /etc/apt/apt.conf.d/20auto-upgrades
echo " [ OK ] " 1>&3

echo -n "Downloading Wazuh clients.. " 1>&3
# Download wazuh clients
sudo docker exec core4s /bin/bash /core4s/scripts/Automation/download_wazuh_clients.sh 3.12.1
echo " [ OK ] " 1>&3

echo -n "Updating tools. This may take a very long time.. " 1>&3
sudo docker container restart suricata
sleep 30
sudo docker exec suricata /root/scripts/update.sh
echo "[ suricata ] " 1>&3

echo -n "Cleaning up.. " 1>&3
sudo apt-fast autoremove -y
echo " [ OK ] " 1>&3

echo "The following secrets were used:" 1>&3
echo "Flask SECRET_KEY: $SECRET_KEY" 1>&3
echo "Postgres: $POSTGRES_USER:$POSTGRES_PASSWORD" 1>&3
echo "IP2Location API Key: $IP2TOKEN" 1>&3

echo "BOX4security.. [ READY ]" | /usr/games/lolcat 1>&3
