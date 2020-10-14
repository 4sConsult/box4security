FROM	wazuh/wazuh:3.13.1_7.8.0
COPY	config/entrypoint.sh /entrypoint.sh
RUN	chmod 755 /entrypoint.sh
HEALTHCHECK --retries=10 CMD curl -k -u ${WAZUH_USER}:${WAZUH_PASS} -XGET https://localhost:55000 && exit 0 || exit 1
