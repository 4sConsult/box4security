#!/bin/bash

# Make the commands a little easier to read by putting the much used path into a variable
DIR=$(echo "/home/amadmin/box4s/scripts/Automation/score_calculation")

# Get the data for the alert score
curl -s -H "Content-type: application/json" -X POST http://localhost:9200/_sql --data-binary @$DIR/res/alert_score.json > $DIR/alert_score_result.json

# Get the data for the vuln score
curl -s -H "Content-type: application/json" -X POST http://localhost:9200/logstash-vulnwhisperer-*/_search --data-binary @$DIR/res/cvss_buckets.query.json > $DIR/cvss_buckets.json

# Calculate the scores and current time
EPOCHTIMESTAMP=$(($(date +%s%N)/1000000))
ALERTSCORE=$(python3 $DIR/calculate_alert_score.py)

# Print the scores just in case for debugging

# Copy the template, insert time and value and post the data to elasticsearch for ...
# ... the alertscore
cp $DIR/res/insert_template.json $DIR/insert_alert_score.json
sed -i 's/%1/alert_score/g' $DIR/insert_alert_score.json
sed -i "s/%2/$ALERTSCORE/g" $DIR/insert_alert_score.json
sed -i "s/%3/$EPOCHTIMESTAMP/g" $DIR/insert_alert_score.json
curl -s -H "Content-type: application/json" -X POST http://localhost:9200/scores/_doc --data-binary @$DIR/insert_alert_score.json
echo "Alertscore: $ALERTSCORE"

# ... the vulnscore
VULNSCORE=$(python3 $DIR/calculate_vuln_score.py)
curl -s -H "Content-type: application/json" -X POST http://localhost:9200/scores/_doc --data-binary @/tmp/vuln.scores.json
echo "Vulnscore: $VULNSCORE"

ITSECSCORE=$(echo "scale=2; ($ALERTSCORE + $VULNSCORE) / 2" | bc)
# and the it-sec-score
cp $DIR/res/insert_template.json $DIR/insert_itsec_score.json
sed -i 's/%1/itsec_score/g' $DIR/insert_itsec_score.json
sed -i "s/%2/$ITSECSCORE/g" $DIR/insert_itsec_score.json
sed -i "s/%3/$EPOCHTIMESTAMP/g" $DIR/insert_itsec_score.json
curl -s -H "Content-type: application/json" -X POST http://localhost:9200/scores/_doc --data-binary @$DIR/insert_itsec_score.json
echo "IT-Sec-Score $ITSECSCORE"

# Delete all temp files to keep the directory clean
rm $DIR/alert_score_result.json
rm $DIR/cvss_buckets.json
rm $DIR/insert_alert_score.json
rm /tmp/vuln.scores.json
rm $DIR/insert_itsec_score.json
