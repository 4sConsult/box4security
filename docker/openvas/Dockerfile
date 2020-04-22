FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ENV DEBIAN_FRONTEND=noninteractive
ARG INT_IP

ADD etc/ /etc/openvas/
ADD etc/vuln_openvas.ini /usr/local/etc/
ADD scripts/ /root/

RUN apt update && \
    apt install net-tools alien rpm nsis python openvas=9.0.3 -y -o Dpkg::Options::=--force-confnew && rm -rf /var/lib/apt/lists/* && \
    openvasmd --create-user amadmin && \
    openvasmd --user=amadmin --new-password=27d55284-90c8-4cc6-9a3e-01763bdab69a && \
    chmod +x /root/start.sh && \
    chmod +x /root/update.sh && \
    cp /lib/systemd/system/greenbone-security-assistant.service /etc/systemd/system/ && \
    service redis-server stop && \
    openvas-stop

CMD /root/start.sh
