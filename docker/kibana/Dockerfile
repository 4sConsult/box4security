FROM ubuntu:19.10
RUN	apt update && \
	apt upgrade -y && \
	apt install -y wget apt-transport-https openjdk-11-jre gnupg && \
	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
	apt update && \
	apt install -y kibana=7.5.0 && \
	mkdir -p /var/log/kibana && \
	chown kibana:kibana /var/log/kibana/ -R

ADD etc/ /root/etc/ 
ADD home/ /root/home/
RUN cp /root/etc/kibana/* /etc/kibana/ -R

EXPOSE 5601
HEALTHCHECK --retries=10 CMD curl -s -XGET 'http://127.0.0.1:5601'
STOPSIGNAL SIGKILL
USER kibana:kibana
CMD ["/usr/share/kibana/bin/kibana"]
