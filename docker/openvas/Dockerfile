FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install python python3-venv python-pip net-tools alien rpm nsis openvas=9.0.3 -y -o Dpkg::Options::=--force-confnew && rm -rf /var/lib/apt/lists/* && \
    cp /lib/systemd/system/greenbone-security-assistant.service /etc/systemd/system/ && \
    service redis-server stop && \
    openvas-stop && \
    mkdir -p /usr/share/openvas/gsa/locale

ADD etc/ /etc/openvas/
ADD scripts/ /root/
ADD etc/vuln_openvas.ini /opt/VulnWhisperer/vulnwhisperer.ini

RUN chmod +x /root/run-OpenVASinsertConf.sh && \
    chmod +x /root/start.sh && \
    chmod +x /root/update.sh && \
    chmod +x /root/vulnwhisp.sh && \
    /root/run-OpenVASinsertConf.sh

WORKDIR /opt/
RUN apt update && \
    apt install -y zlib1g-dev libxml2-dev libxslt1-dev && \
    apt-get install -y virtualenv python-pip python3-pip && \
    git clone https://github.com/box4s/VulnWhisperer.git && \
    cd VulnWhisperer/ && \
    pip install -r requirements.txt && \
    python setup.py install && \
    mkdir -p /var/lib/logstash/openvas && \
    mkdir -p /var/lib/logstash/database

EXPOSE 9392

CMD /root/start.sh
