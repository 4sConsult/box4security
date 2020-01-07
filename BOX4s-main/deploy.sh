#!/bin/bash

# Deploy Script
# Asks if previously run the clone script
# Copies config files in their respective folder

if [[ $EUID -ne 0 ]]; then
       	echo "Deploy erfordert root-Privilegien" 1>&2
	exit 1
fi
echo "Script requires updates repository folders."
read -p "Did you clone before? Press [y] to continue." -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then

  crontab crontab/root.crontab
  su amadmin -c "crontab crontab/amadmin.crontab"
  echo "Crontabs installed"

  cd $BASEDIR$GITDIR
  cd elasticsearch
  echo "Applying Elasticsearch config."
  cp -vr * /

  cd $BASEDIR$GITDIR
  cd filebeat
  echo "Applying Filebeat config."
  rm -vrf /etc/filebeat/modules.d
  cp -vr * /

  cd $BASEDIR$GITDIR
  cd heartbeat
  echo "Applying Heartbeat config."
  rm -vrf /etc/heartbeat/monitors.d
  cp -vr * /

  cd $BASEDIR$GITDIR
  cd kibana
  echo "Applying Kibana config."
  cp -vr etc / # excluding Kibana Dashboards

  cd $BASEDIR$GITDIR
  cd logstash
  echo "Applying Logstash config."
  rm -rfv /etc/logstash/conf.d/*
  cp -vr * /

  cd $BASEDIR$GITDIR
  cd metricbeat
  echo "Applying Metricbeat config."
  cp -vr * /

  cd $BASEDIR$GITDIR
  cd openvas
  echo "Applying Openvas config."
  cp -vr * /

  cd $BASEDIR$GITDIR
  cd packetbeat
  echo "Applying Packetbeat config."
  cp -vr * /

  cd $BASEDIR$GITDIR
  cd suricata
  echo "Applying Suricata config."
  cp -vr * /

  cd $BASEDIR$GITDIR
  cd nginx
  echo "Applying Nginx config and reloading."
  cp -vr * /
  systemctl reload nginx

  cd $BASEDIR$GITDIR
  cd system
  echo "Applying System config."
  cp -vr * /
  chown amadmin:amadmin /home/amadmin/.msmtprc

  systemctl daemon-reload
  echo "Done."
  echo "You can enable the system now."
else
  echo "Did not agree to continue. Quitting."
  exit 1
fi
