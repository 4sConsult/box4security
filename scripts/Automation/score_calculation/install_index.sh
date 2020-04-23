#!/bin/bash

DIR=$(echo "/home/amadmin/box4s/scripts/Automation/score_calculation")

# Install the index
echo "Install the 'scores' index"
curl -s -X DELETE http://localhost:9200/scores
curl -s -H "Content-type: application/json" -X PUT http://localhost:9200/scores --data-binary @$DIR/res/index_settings.json
curl -s -H "Content-type: application/json" -X PUT http://localhost:9200/scores/_mapping --data-binary @$DIR/res/index_mapping.json
