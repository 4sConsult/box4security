FROM docker.elastic.co/beats/metricbeat:7.6.2

ADD etc/ /tmp/etc/
USER root
RUN mkdir -p /usr/share/metricbeat/config/ && cp -R /tmp/etc/* /usr/share/metricbeat/config/