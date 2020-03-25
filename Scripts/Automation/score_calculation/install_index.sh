#!/bin/bash

# Install the index
echo "Install the 'scores' index"
curl -s -H "Content-type: application/json" -X PUT http://localhost:9200/scores --data-binary @index_settings.json
curl -s -H "Content-type: application/json" -X PUT http://localhost:9200/scores/_mapping --data-binary @index_mapping.json
