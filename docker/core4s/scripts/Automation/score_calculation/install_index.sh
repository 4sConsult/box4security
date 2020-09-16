#!/bin/bash

DIR=$(echo "/core4s/scripts/Automation/score_calculation")

echo "Install the 'scores' index"
# Delete an old index, which might exist, so there is no conflict
curl -s -X DELETE http://elasticsearch:9200/scores > /dev/null
# Create a new index called 'scores' with specific settings configured in index_settings.json.
# Also apply a specific mapping, so everything stays the same all the time
curl -s -H "Content-type: application/json" -X PUT http://elasticsearch:9200/scores --data-binary @$DIR/res/index_settings.json
curl -s -H "Content-type: application/json" -X PUT http://elasticsearch:9200/scores/_mapping --data-binary @$DIR/res/index_mapping.json

# Create an suricata index of the current month. score calculation will fail without an existing index.
curl -sLkX PUT elasticsearch:9200/suricata-$(date +%Y.%m) > /dev/null
