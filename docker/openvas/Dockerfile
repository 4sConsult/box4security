FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install alien rpm nsis python openvas=9.0.3 -y -o Dpkg::Options::=--force-confnew && rm -rf /var/lib/apt/lists/*
RUN openvasmd --create-user amadmin
RUN openvasmd --user=amadmin --new-password=27d55284-90c8-4cc6-9a3e-01763bdab69a

ADD etc/ /etc/openvas/
ADD etc/vuln_openvas.ini /usr/local/etc/
ADD scripts/ /root/

RUN chmod +x /root/start.sh
RUN chmod +x /root/update.sh
RUN cp /etc/openvas/greenbone-security-assistant.service /etc/systemd/system/
RUN service redis-server stop && \
    openvas-stop

CMD /root/start.sh
