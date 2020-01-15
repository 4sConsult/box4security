#!/bin/bash
script_dir="/home/amadmin/Elastic_Scripts/"

if [[ $EUID -ne 0 ]]; then
  echo "IPtables Manipulation erfordert root-Privilegien" 1>&2
  exit 1
fi
if [[ -z $1 ]]; then
  echo "Kein Parameter angegeben. Usage: ./setreporting up/down."
  exit 1
fi
case $1 in
    "up" )
        MOD="D"
echo "Aktualisiere Schwachstellendatenbank"
sudo greenbone-nvt-sync
sudo greenbone-certdata-sync && sudo greenbone-scapdata-sync
sudo openvasmd --update
echo "Starte Systemdienste"
systemctl enable elasticsearch.service
systemctl enable suricata.service
systemctl enable filebeat
systemctl enable logstash.service
systemctl enable packetbeat.service
$($script_dir/service-startstop.sh start)
 ;;
    "down" )
        MOD="A"
systemctl disable elasticsearch.service
systemctl disable suricata.service
systemctl disable logstash.service
systemctl disable packetbeat.service
systemctl disable filebeat.service
$($script_dir/service-startstop.sh stop)
      ;;
esac
iptables -$MOD INPUT -i ens160 -p tcp --destination-port 9200 -j DROP
