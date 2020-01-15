# Authentication may be required, append with --user
#url -X PUT "localhost:9200/_snapshot/my_backup{  'type': 'fs',  'settings': {    'location': '/data/elasticsearch_backup'  }}"
curl -X PUT "localhost:9200/PUT /_snapshot/my_backup/snapshot_2?wait_for_completion=true
{
  "indices": "packetbeat-*,logstash-suricata-*",
  "ignore_unavailable": true,
  "include_global_state": false
}

curl -X GET "localhost:9200/_snapshot/my_backup/_all"
