#!/bin/bash

/opt/elasticsearch-curator/curator_cli delete_indices --filter_list '
[
  {
    "filtertype": "age",
    "source": "creation_date",
    "direction": "older",
    "unit": "days",
    "unit_count": 14
  },
  {
    "filtertype": "pattern",
    "kind": "prefix",
    "value": "logstash*"
  }
]
'
