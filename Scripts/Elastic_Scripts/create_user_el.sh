# Authentication may be required, append with --user
curl  -X POST localhost:9200/_xpack/security/user/logstash_internal -H 'Content-Type: application/json' -d '
{
  "password" : "changeme",
  "roles" : [ "logstash_writer"],
  "full_name" : "Internal Logstash User"
}
'
