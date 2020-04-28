#!/bin/bash

# Es muss eine Disk im Installer auf /data angelegt werden
# Der User amadmin muss eingerichtet und verwendet werden.
LOG_FILE="/var/log/installScript.log"
if [[ ! -w $LOG_FILE ]]; then
  LOG_FILE="/home/amadmin/installScript.log"
fi

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

waitForNet
sudo apt install -y curl python python3 python3-pip git git-lfs openconnect jq
git lfs install
if [[ "$*" == *skip-reboot* ]]
then
  REBOOT=false
else
  REBOOT=true
fi
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

waitForNet
sudo apt update

# Docker installieren mit docker-compose
sudo apt install -y docker.io
sudo curl -sL "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Setup for Elasticsearch
sudo mkdir /data/elasticsearch -p
sudo mkdir /data/elasticsearch_backup/Snapshots -p
sudo chmod 777 /data/elasticsearch*

waitForNet
sudo apt -y install openjdk-8-jre apt-transport-https # at least logstash needs it
# Add Elastic signing KEY
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
# Add Elastic Repo
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
sudo apt-get update

# Remove apache2 and nginx if exists
sudo systemctl stop apache2 nginx
sudo apt purge -y apache2 nginx

# Copy certificates over
sudo mkdir -p /etc/nginx/certs
sudo chown root:root /etc/nginx/certs
sudo cp /home/amadmin/box4s/main/ssl/*.pem /etc/nginx/certs
sudo chmod 744 -R /etc/nginx/certs # TODO: insecure

waitForNet
sudo apt install -y msmtp msmtp-mta landscape-common jq

cd /home/amadmin/box4s
sudo cp main/etc/etc_files/* /etc/ -R
sudo cp main/home/* /home/amadmin -R

waitForNet

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

if [[ $REBOOT = true ]]; then
  sudo reboot
else
  echo "Installscript 1 abgeschlossen. Jetzt Änderungen vornehmen und manuell neustarten."
fi
