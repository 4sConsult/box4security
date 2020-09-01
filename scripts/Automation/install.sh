#!/bin/bash
set -e
# Log file to use
# Create path if allowed or do NOP
mkdir -p /var/log/box4s/ || :

# Determine log dir, if writable use /var/log else user's home.
LOG_DIR="/var/log/box4s"
if [[ ! -w $LOG_DIR ]]; then
  LOG_DIR="$HOME"
fi

FULL_LOG=$LOG_DIR/install.log
ERROR_LOG=$LOG_DIR/install.err.log

# Do not use interactive debian frontend.
export DEBIAN_FRONTEND=noninteractive

# Forward fd3 to the console
# exec 3>&1 
# Forward stderr to $ERROR_LOG
# exec 2> >(tee "$ERROR_LOG")
# Forward stdout to $FULL_LOG
# exec > >(tee "$FULL_LOG")
exec 3>&1 1>>${FULL_LOG} 2>>$ERROR_LOG
# HELP text
HELP="\


###########################################
### BOX4s Installer                     ###
###########################################

Disclaimer:
This script will install the BOX4security on this system.
By running the script you confirm to know what you are doing:
1. New packages will be installed.
2. A new folder called '/data' will be created in your root directory.
3. A new sudo user called 'amadmin' will be created on this system.
4. The BOX4s service will be enabled.

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
  toilet -f ivrit "$1" 1>&3
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
    echo "No internet connectivity or dns resolution of $HOST, sleeping for 15s" 1>&3
    sleep 15s
  done
}

function printHelp() {
  toilet -f ivrit 'BOX4security' | boxes -d cat -a hc -p h8 1>&3
  echo "$HELP" 1>&3
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
echo -n "Checking for root: " 1>&3
if [ "$(whoami)" != "root" ];
  then
    echo "[ NOT OK ]" 1>&3
    echo -e "Script must be run as root."
    printHelp
    exit 1
  else
    echo "[ OK ]" 1>&3
fi

echo -n "Creating the /data directory.. " 1>&3
# Create the /data directory if it does not exist and make it readable
sudo mkdir -p /data
sudo chown root:root /data
sudo chmod 777 /data
echo "[ OK ]" 1>&3

# Create update log
sudo touch /var/log/box4s/update.log

# Lets install apt-fast for quick package installation
waitForNet
echo -n "Installing apt-fast.. " 1>&3
sudo /bin/bash -c "$(curl -sL https://raw.githubusercontent.com/ilikenwf/apt-fast/master/quick-install.sh)"
echo "[ OK ]" 1>&3
# Remove services, that might be present, but are not needed.
# But don't fail if they arent.
echo -n "Removing standard services.. " 1>&3
sudo systemctl disable apache2 nginx systemd-resolved || :
sudo apt-fast remove --purge -y apache2 nginx
echo "[ OK ]" 1>&3

# Lets install all dependencies
waitForNet
echo -n "Downloading and installing dependencies. This may take some time.. " 1>&3
sudo apt-fast install -y unattended-upgrades curl python python3 python3-pip python3-venv git git-lfs openconnect jq docker.io apt-transport-https msmtp msmtp-mta landscape-common unzip postgresql-client resolvconf boxes lolcat

sudo add-apt-repository -y ppa:oisf/suricata-stable
sudo apt-get update
sudo apt-fast install -y software-properties-common suricata # TODO: remove in #375
sudo systemctl disable suricata || :
echo "[ OK ]" 1>&3

echo -n "Enabling git lfs.. " 1>&3
git lfs install --skip-smudge
echo "[ OK ]" 1>&3

echo -n "Installing Python3 modules from PyPi.. " 1>&3
pip3 install semver elasticsearch-curator requests
echo "[ OK ]" 1>&3

echo -n "Installing Docker-Compose.. " 1>&3
curl -sL "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
echo "[ OK ]" 1>&3

# Install BlackBox to decrypt stuff
echo -n "Installing BlackBox for secret encryption/decryption.. " 1>&3
git clone https://github.com/StackExchange/blackbox.git /opt/blackbox
cd /opt/blackbox
sudo make symlinks-install
echo "[ OK ]" 1>&3

# Change to path from snippet
cd /tmp/box4s

# Import Secret Key and use the deploy token as password
echo -n "Import BOX4security secret key and decrypting secrets.. " 1>&3
echo $token | gpg --batch --yes --passphrase-fd 0 --import .blackbox/box4s.pem
# Remove passphrase from secret key to allow decryptions without a passphrase.
printf "passwd\n$token\n\n\ny\n\n\ny\nsave\n" | gpg --batch --pinentry-mode loopback --command-fd 0 --status-fd=2 --edit-key box@4sconsult.de
# Decrypt secrets
blackbox_decrypt_file config/secrets/secrets.conf
blackbox_decrypt_file config/secrets/db.conf
# Source the secrets relatively
source config/secrets/secrets.conf
source config/secrets/db.conf
# For security reasons, remove decrypted versions
blackbox_shred_all_files
echo "[ OK ]" 1>&3

# Create the user $HOST_USER only if he does not exist
# The used password is known to the whole dev-team
echo -n "Creating BOX4security user on the host.. " 1>&3
id -u $HOST_USER &>/dev/null || sudo useradd -m -p $HOST_PASS -s /bin/bash $HOST_USER
sudo usermod -aG sudo $HOST_USER
echo "$HOST_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
echo "[ OK ]" 1>&3

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
  TAG=$(curl -s https://gitlab.com/api/v4/projects/4sconsult%2Fbox4s/repository/tags --header "PRIVATE-TOKEN: $GIT_API_TOKEN" | jq -r '[.[] | select(.name | contains("-") | not)][0] | .name')
  echo "Installing the most recent tag $TAG.. [ OK ]" 1>&3
fi
echo "Installing $TAG."
##################################################
#                                                #
# Clone Repository                               #
#                                                #
##################################################
banner "Repository ..."

echo -n "Cloning the repository.. " 1>&3
cd /home/amadmin
git clone https://deploy:$GIT_DEPLOY_TOKEN@gitlab.com/4sconsult/box4s.git box4s -b $TAG
echo "[ OK ]" 1>&3

# Decrypt all secrets via postdeploy
echo -n "Decrypting secrets.. " 1>&3
cd box4s
blackbox_postdeploy
echo "[ OK ]" 1>&3

# Set SSH allowed keys
echo -n "Enabling allowed SSH keys.. " 1>&3
sudo mkdir -p /home/amadmin/.ssh
sudo cp config/home/authorized_keys /home/amadmin/.ssh/authorized_keys
echo "[ OK ]" 1>&3

# Copy certificates over
echo -n "Copying SSL certificates.. " 1>&3
sudo mkdir -p /etc/nginx/certs
sudo chown root:root /etc/nginx/certs
sudo cp /home/amadmin/box4s/config/ssl/box4security.cert.pem /etc/nginx/certs
sudo cp /home/amadmin/box4s/config/secrets/box4security.key.pem /etc/nginx/certs
sudo chmod 744 -R /etc/nginx/certs # TODO: insecure
echo "[ OK ]" 1>&3

# Copy the smtp.conf to /etc/box4s
echo -n "Enabling default SMTP config.. " 1>&3
sudo mkdir -p /etc/box4s/
sudo cp /home/amadmin/box4s/config/secrets/smtp.conf /etc/box4s/smtp.conf
echo "[ OK ]" 1>&3

##################################################
#                                                #
# Docker Volumes                                 #
#                                                #
##################################################
sudo systemctl start docker
banner "Volumes ..."

echo -n "Creating volumes.. " 1>&3
# Setup data volume
sudo docker volume create --driver local --opt type=none --opt device=/data --opt o=bind data
echo -n "[ data " 1>&3

# Setup Suricata volume
sudo mkdir -p /var/lib/suricata
sudo chown root:root /var/lib/suricata
sudo chmod -R 777 /var/lib/suricata
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/suricata/ --opt o=bind varlib_suricata
echo -n " varlib_suricata " 1>&3

# Setup Box4s volume
sudo mkdir -p /var/lib/box4s
sudo chown root:root /var/lib/box4s
sudo chmod -R 777 /var/lib/box4s
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s/ --opt o=bind varlib_box4s
echo -n " varlib_box4s " 1>&3

# Setup PostgreSQL volume
sudo mkdir -p /var/lib/postgresql/data
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/postgresql/data --opt o=bind varlib_postgresql
echo -n " varlib_postgresql " 1>&3


# Setup Box4s Settings volume
sudo mkdir -p /etc/box4s/logstash
sudo cp -R /home/amadmin/box4s/config/etc/logstash/* /etc/box4s/logstash/
sudo chown root:root /etc/box4s/
sudo chmod -R 777 /etc/box4s/
sudo docker volume create --driver local --opt type=none --opt device=/etc/box4s/logstash/ --opt o=bind etcbox4s_logstash
echo -n " etcbox4s_logstash " 1>&3

# Setup Logstash volume
sudo mkdir -p /var/lib/logstash
sudo chown root:root /var/lib/logstash
sudo chmod -R 777 /var/lib/logstash
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/logstash/ --opt o=bind varlib_logstash
echo -n " varlib_logstash " 1>&3

# Setup OpenVAS volume
sudo mkdir -p /var/lib/openvas
sudo chown root:root /var/lib/openvas
sudo chmod -R 777 /var/lib/openvas
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/openvas/ --opt o=bind varlib_openvas
echo -n " varlib_openvas " 1>&3

# Setup Elasticsearch volume
sudo mkdir /data/elasticsearch -p
sudo mkdir /data/elasticsearch_backup/Snapshots -p
sudo chmod 777 /data/elasticsearch*

# Setup ElastAlert volume
sudo mkdir -p /var/lib/elastalert/rules
sudo chown root:root /var/lib/elastalert/rules
sudo chmod -R 777 /var/lib/elastalert/rules
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/elastalert/rules --opt o=bind varlib_elastalert_rules
echo -n " varlib_elastalert_rules " 1>&3

# Setup Wiki volume
sudo mkdir -p /var/lib/box4s_docs
sudo chown root:root /var/lib/box4s_docs
sudo chmod -R 777 /var/lib/box4s_docs
sudo docker volume create --driver local --opt type=none --opt device=/var/lib/box4s_docs --opt o=bind varlib_docs
echo " varlib_docs ]" 1>&3

##################################################
#                                                #
# Installing Box                                 #
#                                                #
##################################################
banner "BOX4security ..."

echo -n "Setting hostname.. " 1>&3
hostname box4security
echo "127.0.0.1 box4security" >> /etc/hosts
echo " [ OK ]" 1>&3

# No longer allow SSH with password login
echo -n "Configuring SSH server.. " 1>&3
sudo sed -i 's/#\?PasswordAuthentication .*$/PasswordAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i 's/#\?ChallengeResponseAuthentication .*$/ChallengeResponseAuthentication no/g' /etc/ssh/sshd_config
sudo sed -i 's/#\?UsePAM .*$/UsePAM no/g' /etc/ssh/sshd_config
sudo sed -i 's/#\?PermitRootLogin .*$/PermitRootLogin no/g' /etc/ssh/sshd_config
sudo systemctl restart sshd
echo " [ OK ]" 1>&3

# Initially clone the Wiki repo
echo -n "Downloading documentation.. " 1>&3
cd /var/lib/box4s_docs
sudo git clone https://deploy:$GIT_DEPLOY_TOKEN@gitlab.com/4sconsult/docs.git .
echo " [ OK ]" 1>&3

echo -n "Configuring BOX4s.. " 1>&3
# Copy gollum config to wiki root
cp /home/amadmin/box4s/docker/wiki/config.ru /var/lib/box4s_docs/config.ru


# Copy config files
cd /home/amadmin/box4s
sudo cp config/etc/etc_files/* /etc/ -R || :
sudo cp config/secrets/msmtprc /etc/msmtprc
sudo cp config/home/* /home/amadmin -R || :

# TODO: remove in #375
sudo mkdir -p /var/lib/suricata/rules
sudo cp /home/amadmin/box4s/docker/suricata/var_lib/quickcheck.rules /var/lib/suricata/rules/quickcheck.rules

# Create a folder for the alerting rules
sudo mkdir -p /var/lib/elastalert/rules

# Copy default elastalert smtp auth file
sudo cp /home/amadmin/box4s/docker/elastalert/etc/elastalert/smtp_auth_file.yaml /var/lib/box4s/elastalert_smtp.yaml
echo " [ OK ]" 1>&3

echo -n "Setting system environment variables.. " 1>&3
set +e
echo "### Setup system variables"
IPINFO=$(ip a | grep -E "inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "host lo")
IPINFO2=$(echo $IPINFO | grep -o -P '(?<=inet)((?!inet).)*(?=ens|eth|eno|enp)')
INT_IP=$(echo $IPINFO2 | sed 's/\/.*//')
echo INT_IP="$INT_IP" | sudo tee -a /etc/default/logstash /etc/environment
source /etc/environment
set -e
echo " [ OK ] " 1>&3

echo -n "Setting network configuration and restarting network.. " 1>&3
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
echo " [ OK ] " 1>&3

echo -n "Setting the portmirror interface.. " 1>&3
# Find the portmirror interface for suricata
touch /home/amadmin/box4s/docker/suricata/.env
IFACE=$(sudo ip addr | cut -d ' ' -f2 | tr ':' '\n' | awk NF | grep -v lo | sed -n 2p | cat)
echo "SURI_INTERFACE=$IFACE" > /home/amadmin/box4s/docker/suricata/.env
echo " [ OK ] " 1>&3

echo -n "Enabling BOX4s internal DNS server.. " 1>&3
# DNSMasq Setup
sudo systemctl disable systemd-resolved
sudo systemctl enable resolvconf
echo "nameserver 127.0.0.1" > /etc/resolvconf/resolv.conf.d/head
echo " [ OK ] " 1>&3

echo -n "Enabling/Disabling Modules.. " 1>&3
sudo mkdir -p /etc/box4s/
sudo cp /home/amadmin/box4s/config/etc/modules.conf /etc/box4s/modules.conf
sudo chmod 444 /etc/box4s/modules.conf
echo " [ OK ] " 1>&3

echo -n "Generating Wazuh Agent-Password.. " 1>&3
strings /dev/urandom | grep -o '[[:alnum:]]' | head -n 14 | tr -d '\n' > /var/lib/box4s/wazuh-authd.pass
sudo chmod 755 /var/lib/box4s/wazuh-authd.pass
echo " [ OK ] " 1>&3

echo -n "BOX4security service setup and enabling.. " 1>&3
# Setup the new Box4Security Service and enable it
sudo mkdir -p /usr/bin/box4s/
sudo cp /home/amadmin/box4s/scripts/System_Scripts/box4s_service.sh /usr/bin/box4s/box4s_service.sh
sudo chmod +x /usr/bin/box4s/box4s_service.sh
sudo cp /home/amadmin/box4s/config/etc/systemd/box4security.service /etc/systemd/system/box4security.service
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
sudo docker login registry.gitlab.com -u deploy -p mPwNxthpxvmQSaZnv3xZ
sudo docker-compose -f /home/amadmin/box4s/docker/box4security.yml pull
sudo docker-compose -f /home/amadmin/box4s/docker/wazuh/wazuh.yml pull
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

echo -n "Downloading Wazuh clients.. " 1>&3
# Download wazuh clients
sudo sh /home/amadmin/box4s/scripts/Automation/download_wazuh_clients.sh 3.12.1
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
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${ESMEM}g -Xmx${ESMEM}g/g" /home/amadmin/box4s/docker/elasticsearch/.env.es
# and one quarter to logstash
LSMEM=$(python3 -c "print(int($MEM*0.25))")
sed -i "s/-Xms[[:digit:]]\+g -Xmx[[:digit:]]\+g/-Xms${LSMEM}g -Xmx${LSMEM}g/g" /home/amadmin/box4s/docker/logstash/.env.ls
echo " [ OK ] " 1>&3

echo -n "Making scripts executable.. " 1>&3
#Make new directory for cronjobchecker
sudo mkdir /var/log/cronchecker
sudo chown amadmin:amadmin /var/log/cronchecker
chmod +x -R /home/amadmin/box4s/scripts
#Owner der Skripte zur score Berechnung anpassen
sudo chown -R amadmin:amadmin /home/amadmin/box4s/scripts/Automation/score_calculation/
echo " [ OK ] " 1>&3

echo -n "Enabling BOX4security internal DNS.. " 1>&3
sudo systemctl stop systemd-resolved
sudo systemctl start resolvconf
sudo cp /home/amadmin/box4s/docker/dnsmasq/resolv.personal /var/lib/box4s/resolv.personal
echo " [ OK ] " 1>&3
##################################################
#                                                #
# Box4s start                                    #
#                                                #
##################################################
banner "Starting BOX4security..."

sudo systemctl start box4security

echo -n "Waiting for Elasticsearch to become available.. " 1>&3
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh elasticsearch
echo " [ OK ] " 1>&3

echo -n "Installing the scores index.. " 1>&3
sleep 5
# Install the scores index
cd /home/amadmin/box4s/scripts/Automation/score_calculation/
./install_index.sh
echo " [ OK ] " 1>&3

echo -n "Installing new cronjobs.. " 1>&3
cd /home/amadmin/box4s/config/crontab
su - amadmin -c "crontab /home/amadmin/box4s/config/crontab/amadmin.crontab"
sudo crontab root.crontab
echo " [ OK ] " 1>&3

source /etc/environment
echo KUNDE="NEWSYSTEM" | sudo tee -a /etc/default/logstash
sudo systemctl daemon-reload

#Ignore own INT_IP
echo -n "Enabling filter to ignore own IP.. " 1>&3
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh db
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('"$INT_IP"',0,'0.0.0.0',0,'');" | PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER psql postgres://localhost/box4S_db
echo "INSERT INTO blocks_by_bpffilter(src_ip, src_port, dst_ip, dst_port, proto) VALUES ('0.0.0.0',0,'"$INT_IP"',0,'');" | PGPASSWORD=$POSTGRES_PASSWORD PGUSER=$POSTGRES_USER psql postgres://localhost/box4S_db
echo " [ OK ] " 1>&3

echo -n "Waiting for Kibana to become available.. " 1>&3
sleep 300
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana 600 && echo " [ OK ] " 1>&3 || echo " [ NOT OK ] " 1>&3
sleep 30
sudo /home/amadmin/box4s/scripts/System_Scripts/wait-for-healthy-container.sh kibana 600 && echo " [ OK ] " 1>&3 || echo " [ NOT OK ] " 1>&3

# Import Dashboard
echo -n "Installing Dashboards und Patterns.. " 1>&3
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
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/System/docker.ndjson

# Installiere Suricata Index Pattern
curl -s -X POST "localhost:5601/kibana/api/saved_objects/_import?overwrite=true" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/config/dashboards/Patterns/suricata.ndjson

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

echo -n "Cleaning up and updating tools.. " 1>&3
sudo apt-fast autoremove -y
# Lets update both openvas and suricata
sudo docker exec suricata /root/scripts/update.sh > /dev/null
sudo docker exec openvas /root/update.sh > /dev/null

# Make sure the permissions for filebeat are correct
# This line may be put into the correct position within this script once we figured out where it has to be.
# For now, so the update works, we stick with this.
sudo chmod 777 /data/suricata/ -R
echo " [ OK ] " 1>&3
echo -n "BOX4security.. [ READY ]" | /usr/games/lolcat 1>&3