FROM docker.elastic.co/beats/filebeat:7.6.2
USER root
COPY --chown=root:root etc/* /usr/share/filebeat/
RUN chmod go-w /usr/share/filebeat/filebeat.yml
