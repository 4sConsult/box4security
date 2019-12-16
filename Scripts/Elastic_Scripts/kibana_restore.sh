#!/bin/bash
# This script uses the snapshot_1 stored in elasticsearch_backup/kibana to restore the index.
curl -X POST "localhost:9200/_snapshot/kibana/$1/_restore"
