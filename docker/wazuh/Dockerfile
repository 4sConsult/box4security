FROM	wazuh/wazuh:3.12.1_7.6.2
ENV     BOX4s_WAZUH false
COPY	config/entrypoint.sh /entrypoint.sh
RUN	chmod 755 /entrypoint.sh
HEALTHCHECK --retries=10 CMD curl -k -u ${WAZUH_USER}:${WAZUH_PASS} -XGET https://localhost:55000 || exit 1
