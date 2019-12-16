# Authentication may be required, append with --user
curl -XPUT  -H 'Content-Type: application/json' 'localhost:9200/_template/logstash-vulnwhisperer' -d@$1
