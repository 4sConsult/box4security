#!/bin/bash

DIR=$(echo "/home/amadmin/box4s/scripts/Automation/score_calculation")

echo "Install the 'scores' index"
# Delete an old index, which might exist, so there is no conflict
curl -s -X DELETE http://localhost:9200/scores

# Create a new index called 'scores' with specific settings configured in index_settings.json.
# Also apply a specific mapping, so everything stays the same all the time
curl -s -H "Content-type: application/json" -X PUT http://localhost:9200/scores --data-binary @$DIR/res/index_settings.json
curl -s -H "Content-type: application/json" -X PUT http://localhost:9200/scores/_mapping --data-binary @$DIR/res/index_mapping.json
