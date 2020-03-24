FROM ubuntu:19.10
RUN 	apt update && \
	apt upgrade -y && \
	apt install -y curl wget apt-transport-https openjdk-11-jre gnupg && \
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
	apt update && \
	apt install -y elasticsearch=7.5.0

ADD etc/ /root/etc/
RUN cp /root/etc/elasticsearch/* /etc/elasticsearch/ -R

EXPOSE 9200
HEALTHCHECK --retries=10 CMD curl -s -XGET 'http://127.0.0.1:9200/_cat/health'
USER elasticsearch:elasticsearch
CMD ["/usr/share/elasticsearch/bin/elasticsearch"] 
