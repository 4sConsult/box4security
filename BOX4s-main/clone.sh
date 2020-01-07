#!/bin/bash

# Clone Script
# Clones all module repos to $BASEDIR$GITDIR e.g. /home/amadmin/qc_git/siem
# It will ask once for authentication to gitlab and save credentials in cache for 15 minutes
# If the siem folder exists and is not empty, it will ask to overwrite or alternatively exit
GITLAB=https://lockedbox-bugtracker.am-gmbh.de
if [[ $EUID -ne 0 ]]; then
  # root check
  echo "Clone-Prozess erfordert Root-Privilegien." 1>&2
  exit 1
fi

if [ -z "$1" ]
then
	echo "Keine Branch angegeben:  $0 [BRANCH]"
  read -p "Welche Branch/Tag soll modulübergreifend gecloned werden z.B. v1.4?`echo $'\n> '`" BRANCH
else
	BRANCH=$1
fi
if [ -z "$BRANCH" ]
then
  BRANCH="master"
fi
echo "Clone Branch $BRANCH".


git config --global credential.helper cache
if [[ ! -d "$BASEDIR$GITDIR" ]]; then
  # Folder does not exist.
  mkdir -pv $BASEDIR$GITDIR
else
  if [[ "$(find $BASEDIR$GITDIR -mindepth 1 -maxdepth 1 | wc -l)" -gt 0 ]]; then
    read -p "$BASEDIR$GITDIR ist nicht leer. Soll das Verzeichnis überschrieben [y] oder beendet werden?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[YyjJ]$ ]]
    then
      rm -r $BASEDIR$GITDIR/*
    else
      echo "Dem Überschreiben nicht zugestimmt. Beende."
      exit
    fi
  fi
fi
cd $BASEDIR$GITDIR
git clone $GITLAB/AM-GmbH/box4security/elasticsearch --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/fetch-qc --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/filebeat --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/heartbeat --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/kibana --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/logstash --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/metricbeat --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/nginx --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/openvas --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/packetbeat --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/scripts --branch $BRANCH
#git clone $GITLAB/AM-GmbH/box4security/startpage --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/suricata --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/system --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/elastalert --branch $BRANCH
git clone $GITLAB/AM-GmbH/box4security/auditbeat --branch $BRANCH
