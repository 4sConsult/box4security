# Updating ASN und GEOIPDB Dictionaries
#!/bin/bash
systemctl start logstash

# Updating Suricata Rules
/usr/local/bin/suricata-update
systemctl restart suricata

# Updating OpenVAS
/usr/sbin/greenbone-nvt-sync --verbose --progress
/usr/sbin/greenbone-certdata-sync --verbose --progress
/usr/sbin/greenbone-scapdata-sync --verbose --progress
/usr/sbin/openvasmd --update --verbose --progress
