FROM bitsensor/elastalert:3.0.0-beta.0

USER root
ADD etc/ /root/etc/
RUN cp /root/etc/elastalert-server/config.yaml /opt/elastalert-server/config/config.yaml && \
  cp /root/etc/elastalert-server/config.yaml /opt/elastalert-server/config/elastalert-test.yaml && \
  cp /root/etc/elastalert-server/config.yaml /opt/elastalert-server/config/elastalert.yaml && \
  cp /root/etc/elastalert-server/config.json /opt/elastalert-server/config/config.json && \
  cp /root/etc/elastalert/config.yaml /opt/elastalert/config.yaml && \
  cp /root/etc/elastalert/smtp_auth_file.yaml /opt/elastalert/smtp_auth_file.yaml
