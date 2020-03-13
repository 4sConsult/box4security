#!/bin/bash
if [ $# -eq 1 ]
then
service suricata $1 2>&1 
service logstash $1 2>&1 
service packetbeat $1 2>&1 
service kibana $1 2>&1 
service elasticsearch $1 2>&1 
service metricbeat $1 2>&1 
service filebeat $1 2>&1 
service heartbeat-elastic $1 2>&1 
else
	echo "Bitte Parameter 1 start oder stop eingeben"
fi

