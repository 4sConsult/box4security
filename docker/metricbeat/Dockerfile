FROM registry.gitlab.com/4sconsult/box4s/baseimage:dev

ADD etc/ /root/etc

RUN apt-fast update && \
  apt-fast install -y metricbeat=7.6.2 && \
  rm -rf /var/lib/apt/lists/* && \
  cp /root/etc/* /etc/metricbeat/ -R && \
  mkdir -p /var/log/metricbeat

CMD ["/usr/share/metricbeat/bin/metricbeat", "-e", "-c", "/etc/metricbeat/metricbeat.yml", "-path.home", "/usr/share/metricbeat", "-path.config", "/etc/metricbeat", "-path.data", "/var/lib/metricbeat", "-path.logs", "/var/log/metricbeat"]
