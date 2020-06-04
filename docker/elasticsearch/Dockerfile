FROM docker.elastic.co/elasticsearch/elasticsearch:7.6.2
RUN	mkdir -p /var/log/elasticsearch/ && \
	mkdir -p /data && \
	touch /var/log/elasticsearch/gc.log && \
	chown elasticsearch:elasticsearch -R /var/log/elasticsearch/
COPY --chown=elasticsearch:elasticsearch etc/* /usr/share/elasticsearch/config/
