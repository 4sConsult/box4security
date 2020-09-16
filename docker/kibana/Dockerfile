FROM docker.elastic.co/kibana/kibana:7.9.0

ARG ELASTIC_VERSION=7.9.0
ARG WAZUH_VERSION=3.13.1
ARG WAZUH_APP_VERSION="${WAZUH_VERSION}_${ELASTIC_VERSION}"

COPY --chown=kibana:kibana etc/* /usr/share/kibana/config/
COPY --chown=root:root ./entry.sh /entrypoint.sh

USER root
RUN mkdir -p /usr/share/kibana/optimize/wazuh/config && \
  mkdir -p /var/log/kibana/ && \
	mkdir -p /var/lib/kibana && \
	touch /var/log/kibana/kibana.log && \
  chown -f kibana:kibana /usr/share/kibana/optimize/wazuh/config && \
	chown kibana:kibana -R /var/log/kibana/ && \
  chown kibana:kibana -R /var/lib/kibana/ && \
  chown -R kibana:kibana /opt/kibana/optimize && \
  chmod g+s /opt/kibana/optimize && \
  chmod +x /entrypoint.sh

RUN echo 'NODE_OPTIONS="--max-old-space-size=2048"' >> /etc/default/kibana

USER kibana
WORKDIR /usr/share/kibana
RUN     ./bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-${WAZUH_APP_VERSION}.zip && \
        echo -e "hosts:\n  - default:\n     url: https://${INT_IP}\n     port: 55000\n     user: ${WAZUH_USER}\n     password: ${WAZUH_PASS}\n" > /usr/share/kibana/optimize/wazuh/config/wazuh.yml

HEALTHCHECK --retries=50 CMD curl -s -XGET 'http://127.0.0.1:5601/kibana/api/status' | grep -v "Kibana server is not ready yet" || exit 1
USER kibana:kibana
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/share/kibana/bin/kibana"]
