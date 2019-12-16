# Authentication may be required, append with --user
curl -X POST "localhost:9200/_xpack/security/role/logstash_writer" -H 'Content-Type: application/json' -d' {"cluster": ["manage_index_templates", "monitor"],  "indices": [ {"names": [ "*" ],"privileges": ["write","delete","create_index"]} ]}'
