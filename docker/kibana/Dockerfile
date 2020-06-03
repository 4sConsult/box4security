FROM registry.gitlab.com/4sconsult/box4s/baseimage:dev

ARG ELASTIC_VERSION=7.6.2
ARG WAZUH_VERSION=3.12.1
ARG WAZUH_APP_VERSION="${WAZUH_VERSION}_${ELASTIC_VERSION}"

ADD etc/ /root/etc/

RUN     wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | apt-key add - && \
        echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | tee -a /etc/apt/sources.list.d/elastic-7.x.list && \
        apt update && \
        apt install -y kibana=${ELASTIC_VERSION} && \
        mkdir -p /var/log/kibana && \
        chown kibana:kibana /var/log/kibana -R && \
        rm -rf /var/lib/apt/lists/* && \
        cp /root/etc/kibana/* /etc/kibana/ -R

USER kibana
WORKDIR /usr/share/kibana
RUN     ./bin/kibana-plugin install https://packages.wazuh.com/wazuhapp/wazuhapp-${WAZUH_APP_VERSION}.zip
RUN     mkdir /usr/share/kibana/optimize/wazuh && \
        mkdir /usr/share/kibana/optimize/wazuh/config

USER root
COPY ./entry.sh /entrypoint.sh
RUN chown -f kibana:kibana /usr/share/kibana/optimize/wazuh/config
RUN chmod +x /entrypoint.sh

HEALTHCHECK --retries=50 CMD curl -s -XGET 'http://127.0.0.1:5601/kibana/api/status' | grep -v "Kibana server is not ready yet" || exit 1
STOPSIGNAL SIGKILL
USER kibana:kibana
ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/share/kibana/bin/kibana"]
