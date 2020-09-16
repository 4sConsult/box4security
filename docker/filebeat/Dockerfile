FROM docker.elastic.co/beats/filebeat:7.9.0
USER root
COPY --chown=root:root etc/* /usr/share/filebeat/
RUN chmod go-w /usr/share/filebeat/filebeat.yml
