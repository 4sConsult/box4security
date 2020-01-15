#!/bin/bash
# This Script exports Kibana Data to Elasticsearch Snapshot Dir
KIBANA_INDEX=$1
if [ $# -eq 1 ]
then
read -p "Use $KIBANA_INDEX? (y/n)? " answer
if [[ "$answer" =~ ^(nN)$ ]]; then
  read -p "Enter Kibana Index:" KIBANA_INDEX
  echo "Using $KIBANA_INDEX"
fi
echo "Creating Snapshot Repository"
curl -X PUT "localhost:9200/_snapshot/kibana" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "kibana"
  }
}
'
echo "Scheduling Kibana Snapshot"
curl -X PUT "localhost:9200/_snapshot/kibana/snapshot_$(date +%s)?wait_for_completion=true" -H 'Content-Type: application/json' -d'
{
  "indices": "'"$KIBANA_INDEX"'",
  "ignore_unavailable": false,
  "include_global_state": false
}
'
echo "Done"
else
	echo "Parameter Indexname eingeben"
fi

