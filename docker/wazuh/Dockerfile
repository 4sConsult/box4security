FROM	wazuh/wazuh:3.12.3_7.6.2
COPY	config/entrypoint.sh /entrypoint.sh
RUN	chmod 755 /entrypoint.sh
HEALTHCHECK --retries=10 CMD curl -k -u box4s:wa3hz0hPW -XGET https://localhost:55000 && exit 0 || exit 1
