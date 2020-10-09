FROM docker.elastic.co/logstash/logstash:7.9.0

USER root
COPY --chown=logstash:logstash etc/ /etc/logstash/
COPY --chown=logstash:logstash etc/ /usr/share/logstash/config/
RUN	curl https://jdbc.postgresql.org/download/postgresql-42.2.8.jar --output /usr/share/logstash/logstash-core/lib/jars/postgresql-42.2.8.jar && \
	mkdir -p /var/log/logstash && \
	mkdir -p /etc/box4s && \
	# Filebeat
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/filebeat/21-4s_Special.conf && \
	# OpenVAS
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/openvas/15-4s_Special.conf && \
	ln -s /etc/logstash/conf.d/general/20-preBOX4s.conf /etc/logstash/conf.d/openvas/30-preBOX4s.conf && \
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/openvas/40-BOX4sspecial.conf && \
	ln -s /etc/logstash/conf.d/general/dns_resolv.conf /etc/logstash/conf.d/openvas/50-DNS_Resolv.conf && \
	# Suricata
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/suricata/25-4s_Special.conf && \
	ln -s /etc/logstash/conf.d/general/20-preBOX4s.conf /etc/logstash/conf.d/suricata/30-preBOX4s.conf && \
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/suricata/40-BOX4sspecial.conf && \
	# Metricbeat
	ln -s /etc/logstash/conf.d/general/dns_resolv.conf /etc/logstash/conf.d/metricbeat/15-dns_resolv.conf && \
	ln -s /etc/logstash/conf.d/general/beat_add_clientIP.conf /etc/logstash/conf.d/metricbeat/20-BeatClientIP.conf && \
	ln -s /etc/logstash/conf.d/general/20-preBOX4s.conf /etc/logstash/conf.d/metricbeat/30-preBOX4s.conf && \
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/metricbeat/40-BOX4sspecial.conf && \
	ln -s /etc/logstash/conf.d/general/dns_resolv.conf /etc/logstash/conf.d/metricbeat/50-DNS_Resolv.conf && \
	# Heartbeat
	ln -s /etc/logstash/conf.d/general/beat_add_clientIP.conf /etc/logstash/conf.d/heartbeat/20-BeatClientIP.conf && \
	ln -s /etc/logstash/conf.d/general/20-preBOX4s.conf /etc/logstash/conf.d/heartbeat/30-preBOX4s.conf && \
	ln -s /etc/logstash/conf.d/general/BOX4s-special.conf /etc/logstash/conf.d/heartbeat/40-BOX4sspecial.conf && \
	ln -s /etc/logstash/conf.d/general/dns_resolv.conf /etc/logstash/conf.d/heartbeat/50-DNS_Resolv.conf && \
	# Dynamic configuration for suricata
	ln -s /var/lib/box4s/15_logstash_suppress.conf /etc/logstash/conf.d/suricata/15_logstash_suppress.conf && \
	/usr/share/logstash/bin/logstash-plugin install logstash-filter-json_encode && \
	/usr/share/logstash/bin/logstash-plugin install logstash-output-jdbc && \
	/usr/share/logstash/bin/logstash-plugin install logstash-filter-ip2location && \
	chown logstash:logstash /usr/share/logstash/logstash-core/lib/jars/postgresql-42.2.8.jar && \
	chown logstash:logstash /var/log/logstash -R && \
	chown logstash:logstash /usr/share/logstash/config -R && \
	chown logstash:logstash /etc/logstash -R

USER logstash:logstash
HEALTHCHECK --retries=10 CMD curl -s -XGET '127.0.0.1:9600/?pretty'
CMD ["/usr/share/logstash/bin/logstash" , "--path.settings", "/etc/logstash"]
