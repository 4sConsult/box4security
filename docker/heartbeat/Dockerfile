FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ADD etc/ /root/etc/

RUN apt update && \
	  apt install -y heartbeat-elastic=7.6.2 && \
    rm -rf /var/lib/apt/lists/* && \
    cp /root/etc/* /etc/heartbeat/ -R && \
    mkdir -p /var/log/filebeat

CMD ["/usr/share/heartbeat/bin/heartbeat", "-e", "-c", "/etc/heartbeat/heartbeat.yml", "-path.home", "/usr/share/heartbeat", "-path.config", "/etc/heartbeat", "-path.data", "/var/lib/heartbeat", "-path.logs", "/var/log/heartbeat"]
