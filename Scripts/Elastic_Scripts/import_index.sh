# Authentication may be required, append with --user
curl -XPUT localhost:9200/_bulk --data-binary @$1
