FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ENV DEBIAN_FRONTEND=noninteractive
ADD etc/vuln_openvas.ini /etc/vulnwhisperer/vulnwhisperer.ini
ADD etc/ /etc/openvas/
ADD scripts/ /root/

RUN apt update && \
    apt install git zlib1g-dev libxml2-dev libxslt1-dev virtualenv python python3-venv python-pip net-tools alien rpm nsis openvas=9.0.3 -y -o Dpkg::Options::=--force-confnew && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /var/lib/logstash/openvas && \
    mkdir -p /var/lib/logstash/database && \
    git clone https://github.com/box4s/VulnWhisperer.git /opt/VulnWhisperer/
WORKDIR /opt/VulnWhisperer/
RUN pip install -r requirements.txt && \
    python setup.py install && \
    chmod +x /root/insertconfig.sh && \
    chmod +x /root/start.sh && \
    chmod +x /root/update.sh && \
    chmod +x /root/vulnwhisp.sh && \
    service redis-server stop && \
    openvas-stop

EXPOSE 9392
HEALTHCHECK --retries=10 CMD curl -s -XGET 'http://127.0.0.1:9392'
CMD /root/start.sh
