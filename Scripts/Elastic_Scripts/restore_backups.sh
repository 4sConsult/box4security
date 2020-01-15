# Authentication may be required, append with --user
curl -X POST "localhost:9200/_snapshot/my_backup/$1/_restore"
