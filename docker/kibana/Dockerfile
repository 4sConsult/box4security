FROM docker.elastic.co/kibana/kibana:7.6.2

ARG ELASTIC_VERSION=7.6.2
ARG WAZUH_VERSION=3.12.1
ARG WAZUH_APP_VERSION="${WAZUH_VERSION}_${ELASTIC_VERSION}"

COPY --chown=kibana:kibana etc/* /usr/share/kibana/config/

USER kibana
WORKDIR /usr/share/kibana
RUN     ./bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-${WAZUH_APP_VERSION}.zip && \
        mkdir /usr/share/kibana/optimize/wazuh && \
        mkdir /usr/share/kibana/optimize/wazuh/config && \
        echo "hosts:\n  - default:\n     url: https://${INT_IP}\n     port: 55000\n     user: box4s\n     password: wa3hz0hPW\n" > /usr/share/kibana/optimize/wazuh/config/wazuh.yml

USER root
RUN chown -f kibana:kibana /usr/share/kibana/optimize/wazuh/config

HEALTHCHECK --retries=50 CMD curl -s -XGET 'http://127.0.0.1:5601/kibana/api/status' | grep -v "Kibana server is not ready yet" || exit 1
STOPSIGNAL SIGKILL
USER kibana:kibana
