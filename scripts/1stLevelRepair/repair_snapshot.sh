#$1 contains name of the snapshot to restore
snaplocation="/var/lib/box4s/snapshots"
#check if snap has .zip ending or not
snap="$snaplocation/$1"
directory="${1%.*}"
tempDir="/tmp"
snapDir="$tempDir/$directory"
#Unzip snapshot
sudo unzip $snap -d $tempDir
#check version for equality
if ! cmp -s /var/lib/box4s/VERSION $snapDir/VERSION
then
  #versions not equal, exit
  exit 1
fi

#move saved files and change permissions
sudo cp -rf $snapDir/etc /
sudo cp -rf $snapDir/var /

#### /etc/box4s ####
sudo chown root:root /etc/box4s/
sudo chmod -R 777 /etc/box4s/
sudo chown -R root:44269 /etc/box4s/logstash
sudo chmod 760 -R /etc/box4s/logstash

#### /var/lib/box4s ####
sudo chown root:root /var/lib/box4s
sudo chmod -R 777 /var/lib/box4s

#### /var/lib/postgresql ####
sudo chown -R root:44269 /var/lib/postgresql/data
sudo chmod 760 -R /var/lib/postgresql/data

#### /var/lib/box4s_suricata_rules ####
sudo chown root:root /var/lib/box4s_suricata_rules/
sudo chmod -R 777 /var/lib/box4s_suricata_rules/

#### /var/lib/logstash ####
sudo chown root:root /var/lib/logstash
sudo chmod -R 777 /var/lib/logstash

#### /var/lib/elastalert ####
sudo chown root:root /var/lib/elastalert/rules
sudo chmod -R 777 /var/lib/elastalert/rules

#### /var/lib/box4s_docs ####
sudo chown root:root /var/lib/box4s_docs
sudo chmod -R 777 /var/lib/box4s_docs

sudo rm $snapDir -r
