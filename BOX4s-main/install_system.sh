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

sudo apt update
waitForNet

#Install Elasticsearch
waitForNet
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
waitForNet
sudo apt install -y apt-transport-https
echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
waitForNet
sudo apt update && sudo apt install -y elasticsearch=7.5.0
sudo mkdir /data/elasticsearch -p
sudo mkdir /data/elasticsearch_backup/Snapshots -p
sudo chown elasticsearch:elasticsearch /data/elasticsearch_backup/ -R
sudo chown elasticsearch:elasticsearch /data/elasticsearch/ -R
cd /home/amadmin/box4s
cd Elasticsearch
sudo cp * / -R


sudo apt install -y rpm nsis alien openvas=9.0.3
#No update openvas -> update system @te
sudo openvasmd --create-user amadmin
sudo openvasmd --user=amadmin --new-password=27d55284-90c8-4cc6-9a3e-01763bdab69a
sudo openvasmd --rebuild --progress
waitForNet
sudo apt install -y net-tools
#Install vulnWhisperer
waitForNet
sudo apt install -y  zlib1g-dev libxml2-dev libxslt1-dev virtualenv net-tools ifupdown python-pip python3-pip
cd /home/amadmin/box4s
waitForNet
git clone https://github.com/box4s/VulnWhisperer.git
cd VulnWhisperer/
virtualenv venv
source venv/bin/activate
waitForNet
pip install -r requirements.txt
python setup.py install
deactivate

cd /home/amadmin/box4s
cd OpenVAS
sudo cp * / -R

waitForNet
sudo apt -y install openjdk-8-jre

# Install nginx
sudo systemctl stop apache2
sudo apt remove -y apache2
waitForNet
sudo apt install -y nginx php7.3 php7.3-fpm php-pgsql
cd /home/amadmin/box4s
cd Nginx
PHPVER=$(php -v | grep -Po '(PHP) \K([0-9]\.[0-9]+)') # e.g. 7.3
sudo cp /lib/systemd/system/php$PHPVER-fpm.service /etc/systemd/system/
sudo sed -i '/\[Service\]/a EnvironmentFile=\/etc\/environment' /etc/systemd/system/php$PHPVER-fpm.service
sudo systemctl daemon-reload
sudo sed -i 's/;clear_env = no/clear_env = no/g' /etc/php/$PHPVER/fpm/pool.d/www.conf
sudo systemctl reload php$PHPVER-fpm.service
sed -i "s/php[0-9]\.[0-9]-fpm/php$PHPVER-fpm/g" etc/nginx/sites-available/default
sudo cp * / -R
# Copy certificates over
sudo mkdir -p /etc/nginx/certs
sudo chown www-data:www-data /etc/nginx/certs
sudo cp /home/amadmin/box4s/BOX4s-main/ssl/*.pem /etc/nginx/certs
sudo chmod 500 /etc/nginx/certs/box4security.key.pem

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

#Install Kibana
waitForNet
sudo apt install -y kibana=7.5.0
cd /home/amadmin/box4s
cd Kibana
sudo mkdir -p /var/log/kibana
sudo cp * / -R
sudo chown kibana:kibana /etc/kibana/ -R
sudo chown kibana:kibana /var/log/kibana/ -R

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
# Install System depedencies
# Install suricata
# Kernel necessary
# Reboot required
#sudo apt remove -yy -qq linux-image* linux-headers* linux-modules* amd64-microcode intel-microcode iucode-tool
cd /home/amadmin/box4s
sudo cp System/boot/* /boot/ -R
sudo update-grub
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
waitForNet
sudo apt install -y mc htop zsh vim libpcre3 libpcre3-dbg libpcre3-dev \
build-essential autoconf automake libtool libpcap-dev libnet1-dev \
libyaml-0-2 libyaml-dev pkg-config zlib1g zlib1g-dev libcap-ng-dev \
libcap-ng0 make libmagic-dev git-core libnetfilter-queue-dev \
libnetfilter-queue1 libnfnetlink-dev libnfnetlink0 libluajit-5.1-dev \
libhtp-dev libnss3-dev libnspr4-dev libjansson-dev libhyperscan-dev \
libmaxminddb-dev rustc cargo
waitForNet
sudo apt install -y postgresql
sudo systemctl enable postgresql
sudo systemctl start postgresql
echo "ALTER USER postgres WITH ENCRYPTED PASSWORD 'zgJnwauCAsHrR6JB';" | sudo -u postgres psql
#Enable Tools
sudo systemctl enable dnsmasq
sudo systemctl enable elasticsearch
sudo systemctl enable kibana

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
#TODO: Commando ip wrorg. Use: cat /proc/net/dev -> dhcp is set by ubuntu setup. Not necessary
# TODO: Use: cat /proc/net/dev
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
