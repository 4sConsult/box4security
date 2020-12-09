#!/bin/bash

# Make the commands a little easier to read by putting the much used path into a variable
DIR=$(echo "/core4s/scripts/Automation/score_calculation")

# Get the data for the alert score
curl -s -H "Content-type: application/json" -X POST http://elasticsearch:9200/suricata*/_search --data-binary @$DIR/res/alerts_buckets.query.json > $DIR/alerts_buckets.json
# Social Media count of last 24hr:
curl -s -H "Content-type: application/json" -X POST http://elasticsearch:9200/suricata*/_count --data-binary @$DIR/res/social_media.query.json > $DIR/social_media_count.json

# Get the data for the vuln score
curl -s -H "Content-type: application/json" -X POST http://elasticsearch:9200/logstash-vulnwhisperer-*/_search --data-binary @$DIR/res/cvss_buckets.query.json > $DIR/cvss_buckets.json

# Calulate, echo and post value for ...
# ... the alertscore
ALERTSCORE=$(python3 $DIR/calculate_alert_score.py)
curl -s -H "Content-type: application/json" -X POST http://elasticsearch:9200/scores/_doc --data-binary @/tmp/alerts.scores.json > /dev/null
echo "Alertscore: $ALERTSCORE"

# ... the vulnscore
VULNSCORE=$(python3 $DIR/calculate_vuln_score.py)
curl -s -H "Content-type: application/json" -X POST http://elasticsearch:9200/scores/_doc --data-binary @/tmp/vuln.scores.json > /dev/null
echo "Vulnscore: $VULNSCORE"

# Delete all temp files to keep the directory clean
rm $DIR/cvss_buckets.json
rm $DIR/alerts_buckets.json
rm $DIR/social_media_count.json
rm /tmp/alerts.scores.json
rm /tmp/vuln.scores.json
