FROM ubuntu:19.10
RUN	apt update && \
	apt install -y curl wget apt-transport-https openjdk-11-jre gnupg && \
	rm -rf /var/lib/apt/lists/*

RUN	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
	apt update && \	
	apt install -y elasticsearch=7.6.2 && \
	rm -rf /var/lib/apt/lists/*

ADD etc/ /root/etc/
RUN cp /root/etc/elasticsearch/* /etc/elasticsearch/ -R

HEALTHCHECK --retries=10 CMD curl -s -XGET 'http://127.0.0.1:9200/_cat/health'
USER elasticsearch:elasticsearch
CMD ["/usr/share/elasticsearch/bin/elasticsearch"] 
