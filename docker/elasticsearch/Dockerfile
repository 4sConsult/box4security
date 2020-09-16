FROM docker.elastic.co/elasticsearch/elasticsearch:7.9.0

RUN	mkdir -p /var/log/elasticsearch/ && \
	mkdir -p /data && \
	touch /var/log/elasticsearch/gc.log && \
	chown elasticsearch:elasticsearch -R /var/log/elasticsearch/
COPY --chown=elasticsearch:elasticsearch etc/* /usr/share/elasticsearch/config/

HEALTHCHECK --retries=10 CMD curl -s -XGET 'http://127.0.0.1:9200/_cat/health'
