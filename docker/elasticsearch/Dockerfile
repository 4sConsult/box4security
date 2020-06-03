FROM registry.gitlab.com/4sconsult/box4s/baseimage:dev

ADD etc/ /root/etc/
RUN	apt update && \
	apt install -y elasticsearch=7.6.2 && \
	rm -rf /var/lib/apt/lists/* && \
	cp /root/etc/elasticsearch/* /etc/elasticsearch/ -R

HEALTHCHECK --retries=10 CMD curl -s -XGET 'http://127.0.0.1:9200/_cat/health'
USER elasticsearch:elasticsearch
CMD ["/usr/share/elasticsearch/bin/elasticsearch"]
