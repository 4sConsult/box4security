FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ADD etc/ /root/etc/

RUN apt update && \
	  apt install -y auditbeat=7.6.2 && \
    rm -rf /var/lib/apt/lists/* && \
    cp /root/etc/* /etc/auditbeat/ -R && \
    mkdir -p /var/log/auditbeat

CMD ["/usr/share/auditbeat/bin/auditbeat", "-e", "-c", "/etc/auditbeat/auditbeat.yml", "-path.home", "/usr/share/auditbeat", "-path.config", "/etc/auditbeat", "-path.data", "/var/lib/auditbeat", "-path.logs", "/var/log/auditbeat"]
