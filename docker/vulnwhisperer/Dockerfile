FROM hasecuritysolutions/vulnwhisperer:latest

ADD etc/vuln_openvas.ini /opt/VulnWhisperer/vulnwhisperer.ini
RUN mkdir -p /var/lib/logstash/openvas && \
    mkdir -p /var/lib/logstash/database

ENTRYPOINT ["vuln_whisperer", "-c", "/opt/VulnWhisperer/vulnwhisperer.ini", "-s", "openvas", "-F"]
