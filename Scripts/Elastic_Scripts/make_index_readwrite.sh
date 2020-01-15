curl -H'Content-Type: application/json' -XPUT localhost:9200/.kibana*/_settings?pretty -d' {"index":{"blocks.read_only":false}}'
