FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive
ADD etc/vuln_openvas.ini /etc/vulnwhisperer/vulnwhisperer.ini
ADD etc/ /etc/openvas/
ADD scripts/ /root/

RUN apt update && \
    apt install curl apt-transport-https software-properties-common git zlib1g-dev libxml2-dev libxslt1-dev virtualenv python python2 python3-venv python3-pip net-tools alien rpm nsis openvas -y -o Dpkg::Options::=--force-confnew && \
    rm -rf /var/lib/apt/lists/* && \
    curl https://bootstrap.pypa.io/get-pip.py --output get-pip.py && \
    python2 get-pip.py && \
    mkdir -p /var/lib/logstash/openvas && \
    mkdir -p /var/lib/logstash/database && \
    chmod 777 -R /var/lib/logstash && \
    git clone https://github.com/box4s/VulnWhisperer.git /opt/VulnWhisperer/
WORKDIR /opt/VulnWhisperer/
RUN pip2 install -r requirements.txt && \
    python setup.py install && \
    chmod +x /root/insertconfig.sh && \
    chmod +x /root/start.sh && \
    chmod +x /root/update.sh && \
    chmod +x /root/vulnwhisp.sh && \
    service redis-server stop && \
    openvas-stop

EXPOSE 9392
HEALTHCHECK --retries=10 CMD curl -s -XGET 'https://127.0.0.1:9392'
CMD /root/start.sh
