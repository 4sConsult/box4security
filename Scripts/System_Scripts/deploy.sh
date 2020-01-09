#!/bin/bash
# Purpose: Deploy the downloaded git repo to the config folders
# Make sure to have updated the repo before.
echo
echo "This script is deprecated and will be removed soon, in a future release."
echo
if [[ $EUID -ne 0 ]]; then
       	echo "Deploy erfordert root-Privilegien" 1>&2
	exit 1
fi

rm -rf $BASEDIR/synlite_suricata
git clone https://github.com/robcowart/synesis_lite_suricata.git $BASEDIR/synlite_suricata

#Elasticsearch
cp -v $BASEDIR/$GITDIR/Elasticsearch/elasticsearch.yml /etc/elasticsearch/elasticsearch.yml

#Filebeat
cp -v $BASEDIR/$GITDIR/Filebeate/filebeat.yml /etc/filebeat/filebeat.yml

#Heartbeat
cp -v $BASEDIR/$GITDIR/Heartbeat/heartbeat.yml /etc/heartbeat/heartbeat.yml
rm -rfv /etc/heartbeat/monitors.d
cp -rv $BASEDIR/$GITDIR/Heartbeat/monitors.d /etc/heartbeat/

#Kibana
cp -v $BASEDIR/$GITDIR/Kibana/kibana.yml /etc/kibana/kibana.yml

# Logstash
rm -rfv /etc/logstash/conf.d/*
cp -rv $BASEDIR/$GITDIR/Logstash/conf.d/* /etc/logstash/conf.d/

# Metricbeat
cp -v $BASEDIR/$GITDIR/Metricbeat/metricbeat.yml /etc/metricbeat/metricbeat.yml
# Suricata
cp -v $BASEDIR/$GITDIR/Suricata/suricata.yaml /etc/suricata/suricata.yaml
cp -v $BASEDIR/$GITDIR/Suricata/quickcheck.rules /var/lib/suricata/rules/quickcheck.rules

#Packetbeat
cp -v $BASEDIR/$GITDIR/Packetbeat/packetbeat.yml /etc/packetbeat/packetbeat.yml
echo "To apply changes restart services"
