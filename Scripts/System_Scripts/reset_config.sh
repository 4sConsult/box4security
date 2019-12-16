#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "Update-Prozess erfordert Root-Privilegien." 1>&2
  exit 1
fi
if [[ $1 = --help ]]; then
	echo "Dieses Script resettet logstash und network konfiguration"
	exit 1;
fi
cd $BASEDIR/$GITDIR
cp Logstash/*.conf /etc/logstash/conf.d/


