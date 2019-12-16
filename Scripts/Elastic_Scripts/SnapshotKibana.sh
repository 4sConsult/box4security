#!/bin/bash
if [[ $EUID -ne 0 ]]; then
  echo "Snapshot-Erstellung erfordert Root-Privilegien" 1>&2
  exit 1
fi
if [[ -z $1 ]]; then
  echo "Kein Parameter angegeben. Usage: $0 backup/restore."
  exit 1
fi
case $1 in
    "backup" )
    read -p "Namen für Snapshot angeben (z.B. kibanav1.4)`echo $'\n> '`" snname
    echo "Verwende $snname.tar.gz für Snapshotarchiv."
    echo "Prüfe auf Elastic-Snapshotrepository"
    status_code=$(curl -XGET localhost:9200/_snapshot/kibana --write-out %{http_code} --silent --output /dev/null)
    if [[ "$status_code" -ne 200 ]] ; then
      echo "Kibana Snapshotrepository existiert nicht. Wird erstellt."
      curl -XPUT localhost:9200/_snapshot/kibana -H "Content-Type: application/json" -d '{"type":"fs", "settings":{"location":"kibana"}}'
    fi
    curl -XPOST "localhost:9200/_snapshot/kibana/$snname?wait_for_completion=true" -d '{"indices":".kibana*"}'
    echo "Elasticsearch Snapshot erstellt."
    tar -czvf $snname.tar.gz -C /data/elasticsearch_backup/Snapshots/ kibana
    echo "Archiv erstellt als $snname.tar.gz"
    ;;
    "restore" )
    if [[ -z $2 ]]; then
      echo "Kein Archiv via $0 $1 archivname.tar.gz angegeben."
      read -p "Namen/Pfad des Snapshotarchivs angeben (z.B. kibanav1.4.tar.gz)`echo $'\n> '`" archname
    else
      archname=$2
    fi
    echo "Verwende $archname für Restoreprozess."
    echo "Prüfe auf Elastic-Snapshotrepository"
    status_code=$(curl -XGET localhost:9200/_snapshot/kibana --write-out %{http_code} --silent --output /dev/null)
    if [[ "$status_code" -ne 200 ]] ; then
      echo "Kibana Snapshotrepository existiert nicht. Wird erstellt."
      curl -XPUT localhost:9200/_snapshot/kibana -H "Content-Type: application/json" -d '{"type":"fs", "settings":{"location":"kibana"}}'
    fi
    read -p "Fortfahren? Bestehende Kibana-Indizes werden gelöscht.(j/n)`echo $'\n> '`" yn
    case $yn in
        [YyjJ]* );;
        * ) echo "Abbruch."; exit;;
    esac
    echo "Beende Kibana."
    systemctl stop kibana
    echo "Lösche bestehende Kibana-Indices"
    curl -XDELETE localhost:9200/.kibana*
    echo "Entpacke Archiv"
    tar -xzvf $archname
    cp -vr kibana /data/elasticsearch_backup/Snapshots/
    rm -vr kibana
    curl -XGET localhost:9200/_snapshot/kibana/_all?pretty --silent | grep '"snapshot" :'
    read -p "Welcher Snapshot soll wiederhergestellt werden?`echo $'\n> '`" snname
    echo "Stelle $snname wieder her."
    curl -XPOST localhost:9200/_snapshot/kibana/$snname/_restore
    echo "Snapshot wiederhergestellt"
    echo "Starte Kibana"
    systemctl start kibana
    ;;
esac
