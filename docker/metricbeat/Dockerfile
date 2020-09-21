FROM docker.elastic.co/beats/metricbeat:7.9.1

ADD etc/ /tmp/etc/
USER root
RUN cp -R /tmp/etc/* /usr/share/metricbeat/
