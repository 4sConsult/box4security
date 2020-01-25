#!/bin/bash

# Get the data for the alert score
curl -s -H "Content-type: application/json" -X POST http://localhost:9200/_sql --data-binary @alert_score.json > alert_score_result.json

# Get the data for the vuln score
curl -s -H "Content-type: application/json" -X POST http://localhost:9200/_sql --data-binary @vuln_score.json > vuln_score_result.json

# Calculate the alertscore and post it to elasticsearch
EPOCHTIMESTAMP=$(($(date +%s%N)/1000000))
ALERTSCORE=$(python calculate_alert_score.py)
VULNSCORE=$(python calculate_vuln_score.py)
ITSECSCORE=$(echo "scale=2; $ALERTSCORE / $VULNSCORE" | bc)

cp insert_template.json insert_alert_score.json
sed -i 's/%1/alert_score/g' insert_alert_score.json
sed -i "s/%2/$ALERTSCORE/g" insert_alert_score.json
sed -i "s/%3/$EPOCHTIMESTAMP/g" insert_alert_score.json
curl -s -H "Content-type: application/json" -X POST http://localhost:9200/scores/_doc --data-binary @insert_alert_score.json

cp insert_template.json insert_vuln_score.json
sed -i 's/%1/vuln_score/g' insert_vuln_score.json
sed -i "s/%2/$VULNSCORE/g" insert_vuln_score.json
sed -i "s/%3/$EPOCHTIMESTAMP/g" insert_vuln_score.json
curl -s -H "Content-type: application/json" -X POST http://localhost:9200/scores/_doc --data-binary @insert_vuln_score.json

cp insert_template.json insert_itsec_score.json
sed -i 's/%1/vuln_score/g' insert_itsec_score.json
sed -i "s/%2/$ITSECSCORE/g" insert_itsec_score.json
sed -i "s/%3/$EPOCHTIMESTAMP/g" insert_itsec_score.json
curl -s -H "Content-type: application/json" -X POST http://localhost:9200/scores/_doc --data-binary @insert_itsec_score.json

# Delete all temp data
rm alert_score_result.json
rm vuln_score_result.json
rm insert_alert_score.json
rm insert_vuln_score.json
rm insert_itsec_score.json
