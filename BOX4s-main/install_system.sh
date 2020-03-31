#!/bin/bash

# Installation Grundsystem. Dauer ca: 30min
# Es muss eine Disk im Insteller auf /data angelegt werden
# Der User amadmin muss eingerichtet und verwendet werden.
# Installationspakete Basic Ubuntu Server, Postgresqsl
LOG_FILE="/var/log/installScript.log"
if [[ ! -w $LOG_FILE ]]; then
  LOG_FILE="/home/amadmin/installScript.log"
fi

function testNet() {
  # Returns 0 for successful internet connection and dns resolution, 1 else
  ping -q -c 1 -W 1 google.com >/dev/null;
  return $?
}

function waitForNet() {
  while ! testNet; do
    # while testNet returns non zero value
    echo "No internet connectivity or dns resolution, sleeping for 15s"
    sleep 15s
  done
}


waitForNet
sudo apt install -y curl python3 git git-lfs openconnect
git lfs install
if [[ "$*" == *skip-reboot* ]]
then
  REBOOT=false
else
  REBOOT=true
fi
#SEARCH FOR BRANCHES THIS IS A DEVELOPMENT FUNCTION SO LET THE BRANCHES HERE!!!!!!!!!
#
#
waitForNet
if [ "$1" != "" ]; then
TAG_COUNT=$(curl -s https://gitlab.am-gmbh.de/api/v4/projects/it-security%2Fb4s/repository/branches --header "PRIVATE-TOKEN: p3a72xCJnChRkMCdUCD6" | python3 -c "import sys, json; print(len(json.load(sys.stdin)))")
for((i=0; i<$TAG_COUNT; i++))
do
waitForNet
TAG=$(curl -s https://gitlab.am-gmbh.de/api/v4/projects/it-security%2Fb4s/repository/branches --header "PRIVATE-TOKEN: p3a72xCJnChRkMCdUCD6" | python3 -c "import sys, json; print(json.load(sys.stdin)[$i]['name'])")
if [[ $TAG == $1 ]];then
        echo "Tag $TAG gefunden"
        break;
fi
done

if [[ $TAG != $1 ]];then
echo "Tag $1 nicht gefunden"
exit 1
fi

else
  # Ermittle aktuellsten Tag
  #
  # Normal behavior search for tags.!!!!!!!!
  #
  #
  waitForNet
  TAG=$(curl -s https://gitlab.am-gmbh.de/api/v4/projects/it-security%2Fb4s/repository/tags --header "PRIVATE-TOKEN: p3a72xCJnChRkMCdUCD6" | python3 -c "import sys, json; print(json.load(sys.stdin)[0]['name'])")
fi
echo "Tag $TAG gefunden"
# Redirect STDOUT to LOG_FILE
# DO NOT PUT THIS higher in source code because no error messages are thrown than
exec 1>$LOG_FILE && exec 2>$LOG_FILE


cd /home/amadmin
waitForNet
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

# Install OpenVAS
waitForNet
sudo apt install -y rpm nsis alien openvas=9.0.3
sudo openvasmd --create-user amadmin
sudo openvasmd --user=amadmin --new-password=27d55284-90c8-4cc6-9a3e-01763bdab69a
sudo openvasmd --rebuild --progress

cd /home/amadmin/box4s
cd OpenVAS
sudo cp * / -R

sudo apt install -y zlib1g-dev libxml2-dev libxslt1-dev # TODO: even necessary?

# Install VulnWhisperer
waitForNet
virtualenv python-pip python3-pip
cd /opt/
waitForNet
git clone https://github.com/box4s/VulnWhisperer.git
cd VulnWhisperer/
virtualenv venv
source venv/bin/activate
waitForNet
pip install -r requirements.txt
sudo python setup.py install --prefix /usr/local
deactivate

waitForNet
sudo apt -y install openjdk-8-jre # at least logstash needs it

# Remove apache2 and nginx if exists
sudo systemctl stop apache2 nginx
sudo apt purge -y apache2 nginx

# Copy certificates over
sudo mkdir -p /etc/nginx/certs
sudo chown root:root /etc/nginx/certs
sudo cp /home/amadmin/box4s/BOX4s-main/ssl/*.pem /etc/nginx/certs
sudo chmod 744 -R /etc/nginx/certs # TODO: insecure

#Install Auditbeat
waitForNet
sudo apt install -y auditd auditbeat=7.5.0
cd /home/amadmin/box4s/
cd Auditbeat/
sudo cp * / -R

#Install Metricbeat
waitForNet
sudo apt install -y metricbeat=7.5.0
cd /home/amadmin/box4s
cd Metricbeat
sudo cp * / -R

#Install Filebeat
waitForNet
sudo apt install -y filebeat=7.5.0
cd /home/amadmin/box4s
cd Filebeat
sudo cp * / -R

# Install Heartbeat
waitForNet
sudo apt install -y heartbeat-elastic=7.5.0
cd /home/amadmin/box4s
cd Heartbeat
sudo cp * / -R

#Install logstash
waitForNet
sudo apt install -y logstash=1:7.5.0-1
cd /home/amadmin/box4s
cd Logstash
sudo cp * / -R
sudo chown logstash /etc/logstash/ -R
sudo chown logstash /var/log/logstash/ -R
echo "Erstelle Links"
cd /etc/logstash/conf.d/
cd suricata
ln -s ../general/AM-special.conf  30-4s_Special.conf
cd ..
cd filebeat
ln -s  ../general/AM-special.conf 21-4s_Special.conf
cd ..
cd nmap
ln -s  ../general/AM-special.conf 21-4s_Special.conf
ln -s ../general/dns_resolv.conf 22-dns_resolv.conf
cd ..
cd openvas
ln -s ../general/AM-special.conf 15-4s_Special.conf
cd ..
cd winlogbeat
ln -s ../general/dns_resolv.conf 15-dns_resolv.conf
cd ..
cd metricbeat
ln -s ../general/dns_resolv.conf 15-dns_resolv.conf
cd ..
cd packetbeat
ln -s ../general/dns_resolv.conf 21-dns_resolv.conf
ln -s ../general/AM-special.conf 25-4s_Special.conf
cd /home/amadmin/box4s
waitForNet
sudo apt install -y msmtp msmtp-mta landscape-common
sudo mkdir /home/downloads
cd /home/downloads
sudo chmod -R 777 /home/downloads/*
waitForNet
sudo apt download dnsmasq dns-root-data dnsmasq dnsmasq-base resolvconf dns-root-data dnsmasq-base
sudo systemctl stop systemd-resolved
sudo systemctl disable systemd-resolved
sudo systemctl stop bind9
sudo systemctl disable bind9
PACKAGE=$(ls | grep dns-root-data)
sudo dpkg -i $PACKAGE
PACKAGE=$(ls | grep resolvconf_)
sudo dpkg -i $PACKAGE
PACKAGE=$(ls | grep dnsmasq-base_)
sudo dpkg -i $PACKAGE
PACKAGE=$(ls | grep dnsmasq)
sudo dpkg -i $PACKAGE
cd /home/amadmin/box4s
sudo cp System/etc/* /etc/ -R
sudo cp System/home/amadmin/* /home/amadmin -R
sudo mkdir /var/log/dnsmasq
sudo systemctl start dnsmasq
sudo systemctl restart dnsmasq
sudo systemctl enable dnsmasq
waitForNet
sudo apt install -y mc htop zsh vim libpcre3 libpcre3-dbg libpcre3-dev \
build-essential autoconf automake libtool libpcap-dev libnet1-dev \
libyaml-0-2 libyaml-dev pkg-config zlib1g zlib1g-dev libcap-ng-dev \
libcap-ng0 make libmagic-dev git-core libnetfilter-queue-dev \
libnetfilter-queue1 libnfnetlink-dev libnfnetlink0 libluajit-5.1-dev \
libhtp-dev libnss3-dev libnspr4-dev libjansson-dev libhyperscan-dev \
libmaxminddb-dev rustc cargo

# Prepare launch of script after reboot
sudo bash -c 'crontab -l > /tmp/crontab.root'
sudo bash -c 'echo SHELL=/bin/bash >> /tmp/crontab.root'
ESCAPED_LOG_FILE=$(echo $LOG_FILE | sed 's/\//\\\//g')
cp /home/amadmin/box4s/BOX4s-main/install_system_after_reboot.sh /home/amadmin/
sudo chmod +x /home/amadmin/install_system_after_reboot.sh
sed -i '2s/.*$/LOG_FILE="'$ESCAPED_LOG_FILE'"/g' /home/amadmin/install_system_after_reboot.sh
sed -i '3s/.*$/BRANCH="'$TAG'"/g' /home/amadmin/install_system_after_reboot.sh
LOADER="@reboot /home/amadmin/install_system_after_reboot.sh"
echo $LOADER | sudo tee -a /tmp/crontab.root
sudo crontab /tmp/crontab.root
sudo rm /tmp/crontab.root
echo "Setze Interfaces"
# Find dhcp and remove everything after
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
