#!/bin/bash

if [[ $EUID -ne 0 ]]; then
  echo "Bereinigung des Systems erfordert root-Privilegien" 1>&2
  exit 1
fi


script_dir=$BASEDIR/$GITDIR"/scripts/Elastic_Scripts"
if [ "$1" == '--bitte-reinigen' ]
then
echo "Das System wird bereinigt"
systemctl stop suricata
systemctl stop logstash
systemctl stop packetbeat
echo "Bereinige die Datenbank"
$script_dir/delete_index.sh packetbeat-*
$script_dir/delete_index.sh suricata-*
$script_dir/delete_index.sh logstash-heartbeat-*
$script_dir/delete_index.sh logstash-*
$script_dir/delete_index.sh filebeat-*
$script_dir/delete_index.sh suricata-*
$script_dir/delete_index.sh suricata_stats-*
$script_dir/delete_index.sh .monitoring-*
$script_dir/delete_index.sh metricbeat-*
echo "Verbleibende Indizes"
$script_dir/list_indexes.sh
echo "Rufe Start-Stop mit Stop auf"
$script_dir/service-startstop.sh stop
echo "Lösche Openvas Daten"
rm /var/lib/logstash/openvas/* -v
rm /var/lib/logstash/openvas/database/* -v
rm /var/lib/logstash/openvas_sincedb -v
echo "Lösche suricata Daten"
rm /var/lib/logstash/suricata_sincedb -v
rm /var/log/suricata/* -v
rm /data/suricata/* -v
echo "Lösche Logs"
rm /var/log/elasticsearch/* -v
rm /var/log/logstash/* -v
find /var/log/ -type f | xargs rm -v

echo "System von Daten bereinigt. Installation kann erfolgen."
exit 0
else
	echo "Dieses Script löscht ALLE aufgenommenen Daten aus dem System"
	echo "Wenn Du sicher bist gebe Ausdruck: --bitte-reinigen an"
fi
