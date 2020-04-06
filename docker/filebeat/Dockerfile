FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ADD etc/ /root/etc/

RUN apt update && \
	  apt install -y filebeat=7.6.2 && \
    rm -rf /var/lib/apt/lists/* && \
    cp /root/etc/* /etc/filebeat/ -R && \
    mkdir -p /var/log/filebeat && \
    chown filebeat:filebeat /etc/filebeat -R && \
    chown filebeat:filebeat /usr/share/filebeat -R && \
    chown filebeat:filebeat /var/lib/filebeat -R && \
    chown filebeat:filebeat /var/log/filebeat -R

USER filebeat:filebeat
CMD ["/usr/share/filebeat/bin/filebeat", "-e", "-c", "/etc/filebeat/filebeat.yml", "-path.home", "/usr/share/filebeat", "-path.config", "/etc/filebeat", "-path.data", "/var/lib/filebeat", "path.logs", "/var/log/filebeat"]
