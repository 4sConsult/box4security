curl -X POST http://localhost:5601/api/saved_objects/_export -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d' { type: index-pattern }' | sudo tee -a $BASEDIR$GITDIR/Kibana/home/amadmin/kibana-dashboard_v1.5.0.ndjson

curl -X POST http://localhost:5601/api/saved_objects/_export -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d' { type: dashboard }' | sudo tee -a $BASEDIR$GITDIR/Kibana/home/amadmin/kibana-dashboard_v1.5.0.ndjson

#curl -X POST http://localhost:5601/api/saved_objects/_export -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d' { type: visualisation }' | sudo tee -a $BASEDIR$GITDIR/Kibana/home/amadmin/kibana-dashboard_v1.5.0.ndjson
