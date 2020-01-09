curl -X POST 'localhost:5601/api/saved_objects/_import' -H 'kbn-xsrf: true' --form file=@$BASEDIR$GITDIR/Kibana/home/amadmin/kibana-dashboard_v1.5.0.ndjson
