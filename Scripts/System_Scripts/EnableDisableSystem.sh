#!/bin/bash
script_dir=$BASEDIR/$GITDIR"scripts/Elastic_Scripts/"

if [[ $EUID -ne 0 ]]; then
  echo "Enabe / Disable System erfordert root-Privilegien" 1>&2
  exit 1
fi
if [[ ! -d /data/elasticsearch ]]; then
  mkdir -p /data/elasticsearch
fi
if [[ ! -d /data/elasticsearch_backup/Snapshots ]]; then
  mkdir -p /data/elasticsearch_backup/Snapshots
fi
if [[ $(stat -c %U /data/elasticsearch) != "elasticsearch" ]] || [[ $(stat -c %U /data/elasticsearch_backup) != "elasticsearch" ]]; then
  chown -R elasticsearch:elasticsearch /data/elasticsearch*
fi
if [[ -z $1 ]]; then
  echo "Kein Parameter angegeben. Usage: $0 up/down."
  exit 1
fi
case $1 in
    "up" )
        MOD="A"
echo "Aktualisiere Schwachstellendatenbank"
sudo greenbone-nvt-sync --verbose --progress
sudo greenbone-certdata-sync --verbose --progress && sudo greenbone-scapdata-sync --verbose --progress
sudo openvasmd --update --verbose --progress
echo "Starte Systemdienste"
systemctl enable elasticsearch.service
systemctl enable suricata.service
systemctl enable filebeat
systemctl enable logstash.service
systemctl enable packetbeat.service
systemctl enable heartbeat-elastic.service
$($script_dir/service-startstop.sh start)
 ;;
    "down" )
        MOD="D"
systemctl disable elasticsearch.service
systemctl disable suricata.service
systemctl disable logstash.service
systemctl disable packetbeat.service
systemctl disable filebeat.service
systemctl disable heartbeat-elastic.service
$($script_dir/service-startstop.sh stop)
  ;;
esac
