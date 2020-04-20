FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt install alien rpm nsis python openvas=9.0.3 -y -o Dpkg::Options::=--force-confnew && rm -rf /var/lib/apt/lists/*
RUN openvasmd --create-user amadmin
RUN openvasmd --user=amadmin --new-password=27d55284-90c8-4cc6-9a3e-01763bdab69a

ADD etc/ /etc/openvas/
ADD etc/vuln_openvas.ini /usr/local/etc/
ADD scripts/ /root/

RUN mkdir -p /var/run/redis
RUN chmod +x /root/start.sh
RUN chmod +x /root/update.sh
RUN sed -i 's/--listen=127.0.0.1/--listen=0.0.0.0/g' /lib/systemd/system/openvas-manager.service
RUN sed -i 's/--listen=127.0.0.1/--listen=0.0.0.0/g' /lib/systemd/system/greenbone-security-assistant.service
RUN service openvas-manager restart && \
    service greenbone-security-assistant restart
RUN openvas-check-setup

CMD /root/start.sh
