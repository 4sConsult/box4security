#!/bin/bash
# PLATZHALTER LOG_FILE
# PLAZHALTER BRANCH
#
#
function testNet() {
  # Returns 0 for successful internet connection and dns resolution, 1 else
  if ping -q -c 1 -W 1 google.com >/dev/null; then
  return 0
else
  return 1
fi
}

function waitForNet() {
  while ! testNet; do
    # while testNet returns non zero value
    echo "No internet connectivity or dns resolution, sleeping for 15s"
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
cd /home/amadmin/box4s

sudo systemctl stop irqbalance
sudo systemctl disable irqbalance
echo "Installiere Suricata Deps"
echo
echo
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
echo
echo
#Remove standard ubuntu kernel
#sudo apt -y remove linux-generic linux-headers-generic linux-image-generic amd64-microcode iucode-tool intel-microcode libpcre16*
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
echo
echo
cd /home/amadmin/suricata-src
waitForNet
git clone https://github.com/libbpf/libbpf.git
cd libbpf/src/
make -j8
sudo make install
sudo make install_headers
sudo ldconfig
echo "Installiere Suricata"
echo
echo
cd /home/amadmin/suricata-src
waitForNet
git clone https://github.com/OISF/suricata.git --branch suricata-5.0.1 suricata-git
cd suricata-git
echo "Hole libhtp"
echo
echo
sudo apt remove -y libhtp2
waitForNet
git clone https://github.com/OISF/libhtp.git -b 0.5.x libhtp-git
cd libhtp-git
echo "Installiere libhtp"
echo
echo
./autogen.sh
./configure
make -j8
sudo make install
cd ..
cd ..
echo "Installiere Hyperscan"
echo
echo
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
echo "Installiere suricata"
echo
echo
cd /home/amadmin/suricata-src/suricata-git
./autogen.sh
./configure \
--prefix=/usr/ --sysconfdir=/etc/ --localstatedir=/var/ \
--enable-nfqueue --disable-gccmarch-native  --enable-non-bundled-htp --with-libhtp-includes=/usr/local/lib/ \
--enable-geoip --enable-gccprotect  --enable-luajit --enable-pie --enable-ebpf --enable-ebpf-build
make clean
make -j8
echo
echo
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
echo "Installiere suricata update"
echo
echo
waitForNet
pip3 install suricata-update
cd /home/amadmin/box4s
cd Suricata
echo "Setze Suricata interfaces"
echo
echo
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
#Installation Dashboards
echo "Install Dashboards"
echo ""
echo
echo
cd /home/amadmin/box4s
systemctl is-active --quiet elasticsearch
if [ $? -ne 0 ]
then
  echo
  echo
  echo
  echo "Elasticsearch not running. Restarting the service and waiting for 90s before continuing!!"
  systemctl restart elasticsearch
  sleep 90
fi
status_code=$(curl -XGET localhost:9200/_snapshot/kibana --write-out %{http_code} --silent --output /dev/null)
if [[ "$status_code" -ne 200 ]] ; then
	curl -XPUT localhost:9200/_snapshot/kibana -H "Content-Type: application/json" -d '{"type":"fs", "settings":{"location":"kibana"}}'
fi
sudo systemctl stop kibana
curl -XDELETE localhost:9200/.kibana*
cd /home/amadmin/box4s/Kibana/home/amadmin
tar -xzf kibana.tar.gz
sudo cp -r kibana /data/elasticsearch_backup/Snapshots/
rm -r kibana
SNAPNAME=$(curl -XGET localhost:9200/_snapshot/kibana/_all?pretty --silent | grep '"snapshot" :' | tail -n 1 | grep -Po ': "\K.*(?=")')
curl -XPOST localhost:9200/_snapshot/kibana/$SNAPNAME/_restore
sudo systemctl start kibana

echo "Hole fetchqc"
echo
echo
# curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@home/amadmin/kibana-dashboard_v1.5.0.ndjson
# Remove Cron entry
echo "CREATE DATABASE \"box4S_db\" OWNER postgres;" | sudo -u postgres psql
cd /home/amadmin/box4s
cd FetchQC
python3 -m venv .venv
source .venv/bin/activate
waitForNet
pip install -r requirements.txt
alembic upgrade head
deactivate
chmod +x -R $BASEDIR$GITDIR/Scripts
cd $BASEDIR$GITDIR/Scripts/Automation
./run-OpenVASinsertConf.sh
echo
echo
echo "Install Crontab"
cd /home/amadmin/box4s/BOX4s-main/crontab
su - amadmin -c "crontab ~/box4s/BOX4s-main/crontab/amadmin.crontab"
sudo crontab root.crontab
echo "Initialisiere Datenbanken"
echo
echo
cd /tmp/
waitForNet
curl -O -s https://iptoasn.com/data/ip2asn-combined.tsv.gz
gunzip -f ip2asn-combined.tsv.gz

if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw ASN_lookup_test;then
	echo "DROP table asn; CREATE table asn (range_start INET,range_end INET, AS_number VARCHAR(10) ,country_code VARCHAR(7),AS_description VARCHAR(250)); COPY asn FROM '/tmp/ip2asn-combined.tsv' DELIMITER E'\t';" |sudo -u postgres psql ASN_lookup_test
else
	echo "CREATE DATABASE \"ASN_lookup_test\" OWNER postgres;" |sudo -u postgres psql
	echo "CREATE table asn (range_start INET,range_end INET, AS_number VARCHAR(10) ,country_code VARCHAR(7),AS_description VARCHAR(250)); COPY asn FROM '/tmp/ip2asn-combined.tsv' DELIMITER E'\t';" |sudo -u postgres psql ASN_lookup_test

echo "CREATE SEQUENCE public.uniquevulns_vul_id_seq
    INCREMENT 1
    START 27275
    MINVALUE 1
    MAXVALUE 2147483647
    CACHE 1;

ALTER SEQUENCE public.uniquevulns_vul_id_seq
    OWNER TO postgres;"  |sudo -u postgres psql box4S_db

echo "CREATE TABLE public.uniquevulns
 (
     vul_id integer NOT NULL DEFAULT nextval('uniquevulns_vul_id_seq'::regclass),
     uniqueidentifier character varying(50) COLLATE pg_catalog."default" NOT NULL,
     CONSTRAINT uniquevulns_pkey PRIMARY KEY (vul_id),
     CONSTRAINT uniquevulns_uniqueidentifier_key UNIQUE (uniqueidentifier)

 )
 WITH (
     OIDS = FALSE
 )
 TABLESPACE pg_default;

 ALTER TABLE public.uniquevulns
     OWNER to postgres;"  |sudo -u postgres psql box4S_db
# Filter Functionality
sudo mkdir /var/www/kibana/ebpf -p
sudo touch /var/www/kibana/ebpf/bypass_filter.bpf
sudo chown suri:www-data /var/www/kibana/ebpf/bypass_filter.bpf
sudo chmod 664 /var/www/kibana/ebpf/bypass_filter.bpf
echo "CREATE TABLE blocks_by_bpffilter
       (
           src_ip inet,
           src_port integer,
           dst_ip inet,
           dst_port integer,
           proto  varchar(4)
       )
       WITH (
           OIDS = FALSE
       )
       TABLESPACE pg_default;
       ALTER TABLE blocks_by_bpffilter
           OWNER to postgres;" | sudo -u postgres psql box4S_db
echo "not (src host 127.0.0.1) and"  | sudo tee -a  /var/www/kibana/ebpf/bypass_filter.bpf
echo "not (dst host 127.0.0.1) and"  | sudo tee -a  /var/www/kibana/ebpf/bypass_filter.bpf
echo "INSERT INTO blocks_by_bpffilter VALUES ('127.0.0.1',0,'0.0.0.0',0,'');" | sudo -u postgres psql box4S_db
echo "INSERT INTO blocks_by_bpffilter VALUES ('0.0.0.0',0,'127.0.0.1',0,'');" | sudo -u postgres psql box4S_db
echo "CREATE TABLE blocks_by_logstashfilter
             (
                 src_ip inet,
                 src_port integer,
                 dst_ip inet,
                 dst_port integer,
                 proto  varchar(4),
                 signature_id varchar(10),
                 signature varchar(256)
             )
             WITH (
                 OIDS = FALSE
             )
             TABLESPACE pg_default;
             ALTER TABLE blocks_by_logstashfilter
                 OWNER to postgres;" | sudo -u postgres psql box4S_db
sudo touch /var/www/kibana/ebpf/15_kibana_filter.conf
sudo chown logstash:www-data /var/www/kibana/ebpf/15_kibana_filter.conf
sudo chmod 0664 /var/www/kibana/ebpf/15_kibana_filter.conf
sudo ln -s /var/www/kibana/ebpf/15_kibana_filter.conf /etc/logstash/conf.d/suricata/15_kibana_filter.conf

sudo -u postgres psql -U postgres -d postgres -c "alter user postgres with password 'zgJnwauCAsHrR6JB';"
fi
rm ip2asn-combined.tsv
#Add Int IP
echo "Initialisiere Systemvariablen"
echo
echo
IPINFO=$(ip a | grep -E "inet [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}" | grep -v "host lo")
IPINFO2=$(echo $IPINFO | awk  '{print substr($IPINFO, 6, length($IPINFO))}')
INT_IP=$(echo $IPINFO2 | sed 's/\/.*//')
echo INT_IP="$INT_IP" | sudo tee -a /etc/default/logstash /etc/environment
source /etc/environment
echo KUNDE="NEWSYSTEM" | sudo tee -a /etc/default/logstash
# Set INT-IP as --allow-header-host
sed -ie "s/--allow-header-host [0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}/--allow-header-host $INT_IP/g" /etc/systemd/system/greenbone-security-assistant.service
sudo systemctl daemon-reload
#Ignore own INT_IP
echo "not (src host $INT_IP) and" | sudo tee -a /var/www/kibana/ebpf/bypass_filter.bpf
echo "not (dst host $INT_IP)"  | sudo tee -a  /var/www/kibana/ebpf/bypass_filter.bpf
echo "INSERT INTO blocks_by_bpffilter VALUES ('"$INT_IP"',0,'0.0.0.0',0,'');" | sudo -u postgres psql box4S_db
echo "INSERT INTO blocks_by_bpffilter VALUES ('0.0.0.0',0,'"$INT_IP"',0,'');" | sudo -u postgres psql box4S_db
#Copy postgres driver
sudo cp /etc/logstash/BOX4s/postgresql-42.2.8.jar /usr/share/logstash/logstash-core/lib/jars/
# make /data writeable to Elasticsearch
sudo chown elasticsearch:elasticsearch /data/elasticsearch -R
sudo chown suri:suri /data/suricata/ -R
#Updating System with openvas and installing necessary logstash plugins

echo
echo "Installiere Elastic Curator"
pip3 install elasticsearch-curator --user

echo "Initialisiere Schwachstellendatenbank und hole aktuelle Angriffspattern"
echo
echo
waitForNet
/home/amadmin/box4s/Scripts/System_Scripts/update_system.sh
# apply network/interfaces

# Install the scores index
/home/amadmin/box4s/Scripts/Automation/score_calculation/install_index.sh
# Import BI Dashboards
curl -X POST "localhost:5601/api/saved_objects/_import" -H "kbn-xsrf: true" --form file=@/home/amadmin/box4s/Scripts/Automation/score_calculation/BIDashboards.ndjson

sudo systemctl restart networking
sudo systemctl enable heartbeat-elastic
sudo systemctl enable suricata
sudo systemctl enable logstash
sudo systemctl enable metricbeat
sudo systemctl enable filebeat
sudo systemctl enable openvas-scanner
sudo systemctl enable openvas-manager
sudo systemctl enable greenbone-security-assistant
sudo systemctl enable logstash
sudo systemctl start logstash metricbeat filebeat openvas-scanner openvas-manager greenbone-security-assistant heartbeat-elastic suricata
echo "BOX4security installiert."
