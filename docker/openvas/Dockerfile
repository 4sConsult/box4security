FROM securecompliance/gvm:20.08-v1

ADD etc/ /etc/openvas/
ADD scripts/ /root/

RUN chmod +x /root/insertconfig.sh && \
    chmod +x /root/start.sh && \
    chmod +x /root/update.sh && \
    chmod +x /root/vulnwhisp.sh

EXPOSE 9392
EXPOSE 9393
HEALTHCHECK --retries=10 CMD curl -sLk -XGET 'https://127.0.0.1:9392'
CMD /root/start.sh
