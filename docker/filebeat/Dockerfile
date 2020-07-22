FROM docker.elastic.co/beats/filebeat:7.6.2

COPY --chown=filebeat:filebeat etc/* /usr/share/filebeat/
RUN chmod go-w /usr/share/filebeat/filebeat.yml
