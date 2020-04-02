FROM ubuntu:19.10
RUN	apt update && \
	apt install -y curl wget apt-transport-https openjdk-11-jre gnupg && \
	rm -rf /var/lib/apt/lists/*

RUN	wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
	echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
	apt update && \
	apt install -y logstash=1:7.6.2-1 && \
	mkdir -p /var/log/logstash && \
	mkdir -p /etc/box4s && \
	chown logstash:logstash /var/log/logstash -R && \
	chown logstash:logstash /etc/box4s -R && \
	rm -rf /var/lib/apt/lists/*

ADD	etc/ /root/etc/
RUN	mv /root/etc/logstash/* /etc/logstash/ && \
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/suricata/30-4s_Special.conf && \
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/filebeat/21-4s_Special.conf && \
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/nmap/21-4s_Special.conf && \
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/nmap/22-dns_resolv.conf && \
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/openvas/15-4s_Special.conf && \
	ln -s /etc/logstash/conf.d/general/dns_resolv.conf /etc/logstash/conf.d/winlogbeat/15-dns_resolv.conf && \
	ln -s /etc/logstash/conf.d/general/dns_resolv.conf /etc/logstash/conf.d/metricbeat/15-dns_resolv.conf && \
	ln -s /var/lib/box4s/15_logstash_suppress.conf /etc/logstash/conf.d/suricata/15_logstash_suppress.conf && \
	/usr/share/logstash/bin/logstash-plugin remove logstash-codec-nmap && \
	/usr/share/logstash/bin/logstash-plugin install logstash-codec-nmap && \
	/usr/share/logstash/bin/logstash-plugin remove logstash-filter-json_encode && \
	/usr/share/logstash/bin/logstash-plugin install logstash-filter-json_encode && \
	/usr/share/logstash/bin/logstash-plugin remove logstash-output-jdbc && \
	/usr/share/logstash/bin/logstash-plugin install logstash-output-jdbc && \
	/usr/share/logstash/bin/logstash-plugin remove logstash-filter-ip2location && \
	/usr/share/logstash/bin/logstash-plugin install logstash-filter-ip2location

HEALTHCHECK --retries=10 CMD curl -s -XGET '127.0.0.1:9600/?pretty'
USER logstash:logstash
CMD ["/usr/share/logstash/bin/logstash"]
