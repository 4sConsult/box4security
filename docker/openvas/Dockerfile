FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ENV DEBIAN_FRONTEND=noninteractive

ADD etc/ /etc/openvas/
ADD etc/vuln_openvas.ini /usr/local/etc/
ADD scripts/ /root/

RUN apt update
RUN apt install python openvas=9.0.3 -y -o Dpkg::Options::=--force-confnew && rm -rf /var/lib/apt/lists/*
RUN openvasmd --create-user amadmin
RUN openvasmd --user=amadmin --new-password=27d55284-90c8-4cc6-9a3e-01763bdab69a
RUN wget -q --no-check-certificate https://raw.githubusercontent.com/kurobeats/OpenVas-Management-Scripts/master/openvas-check-setup -O /openvas-check-setup && chmod +x /openvas-check-setup
RUN chmod +x /root/start.sh
RUN chmod +x /root/update.sh
RUN service openvas-scanner stop && \
    service openvas-manager stop && \
    service openvas-gsa stop && \
    service redis-server stop
RUN cat /etc/systemd/system/openvas-scanner.service
RUN cat /etc/systemd/system/openvas-manager.service
RUN cat /etc/systemd/system/greenbone-security-assistant.service

CMD /root/start.sh
