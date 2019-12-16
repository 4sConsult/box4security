# Authentication may be required, append with --user
#url -X PUT "localhost:9200/_snapshot/my_backup{  'type': 'fs',  'settings': {    'location': '/data/elasticsearch_backup'  }}"
curl -X PUT "localhost:9200/_snapshot/my_backup" -H 'Content-Type: application/json' -d'
 {
   "type": "fs",
   "settings": {
     "location": "my_backup"
   }
 }
 '

curl -X GET "localhost:9200/_snapshot/my_backup/_all"
