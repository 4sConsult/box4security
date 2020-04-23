FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ENV DEBIAN_FRONTEND=noninteractive

ADD etc/ /etc/openvas/
ADD scripts/ /root/

RUN apt update && \
    apt install python python3-venv python-pip net-tools alien rpm nsis openvas=9.0.3 -y -o Dpkg::Options::=--force-confnew && rm -rf /var/lib/apt/lists/* && \
    chmod +x /root/run-OpenVASinsertConf.sh && \
    chmod +x /root/start.sh && \
    chmod +x /root/update.sh && \
    cp /lib/systemd/system/greenbone-security-assistant.service /etc/systemd/system/ && \
    openvas-setup && \
    service redis-server stop && \
    openvas-stop
EXPOSE 9392

CMD /root/start.sh
