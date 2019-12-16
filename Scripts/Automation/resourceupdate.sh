# Updating ASN und GEOIPDB Dictionaries
rm -rf $BASEDIR/synlite_suricata # In case initial setup was missing
git clone https://github.com/robcowart/synesis_lite_suricata.git $BASEDIR/synlite_suricata
cd $BASEDIR/synlite_suricata
systemctl stop logstash
rm -rf /etc/logstash/synlite_suricata/dictionaries
rm -rf /etc/logstash/synlite_suricata/geoipdbs

cp -r $BASEDIR/synlite_suricata/logstash/synlite_suricata/dictionaries /etc/logstash/synlite_suricata/
cp -r $BASEDIR/synlite_suricata/logstash/synlite_suricata/geoipdbs /etc/logstash/synlite_suricata/

systemctl start logstash

# Updating Suricata Rules
suricata-update
systemctl restart suricata

# Updating OpenVAS
/usr/sbin/greenbone-nvt-sync --verbose --progress
/usr/sbin/greenbone-certdata-sync --verbose --progress
/usr/sbin/greenbone-scapdata-sync --verbose --progress
/usr/sbin/openvasmd --update --verbose --progress
