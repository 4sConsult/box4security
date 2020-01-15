


packetbeat setup --dashboards -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'
auditbeat setup --dashboards -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'
metricbeat setup --dashboards -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'
heartbeat setup --dashboards -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'
filebeat setup --dashboards -E output.logstash.enabled=false -E 'output.elasticsearch.hosts=["localhost:9200"]'
