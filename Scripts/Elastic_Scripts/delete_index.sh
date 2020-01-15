#!/bin/bash
# Authentication may be required, append with --user
if [ $# -eq 1 ]
then
curl -X DELETE "localhost:9200/$1"
else
echo "Bitte Indexname angeben"
fi

