FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ADD etc/ /root/etc

RUN apt update && \
  apt install -y metricbeat=7.6.2 && \
  rm -rf /var/lib/apt/lists/* && \
  cp /root/etc/* /etc/metricbeat/ -R && \
  mkdir -p /var/log/metricbeat

CMD ["/usr/share/metricbeat/bin/metricbeat", "-e", "-c", "/etc/metricbeat/metricbeat.yml", "-path.home", "/usr/share/metricbeat", "-path.config", "/etc/metricbeat", "-path.data", "/var/lib/metricbeat", "-path.logs", "/var/log/metricbeat"]
