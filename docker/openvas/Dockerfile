FROM docker-registry.am-gmbh.de/it-security/b4s/baseimage:dev

ENV DEBIAN_FRONTEND=noninteractive

ADD etc/ /etc/openvas/
ADD etc/vuln_openvas.ini /usr/local/etc/
ADD scripts/start.sh /root/start.sh

RUN apt update
RUN apt install openvas=9.0.3 -y -o Dpkg::Options::=--force-confnew && rm -rf /var/lib/apt/lists/*
RUN openvasmd --create-user amadmin
RUN openvasmd --user=amadmin --new-password=27d55284-90c8-4cc6-9a3e-01763bdab69a
RUN openvasmd --rebuild --progress
RUN chmod +x /root/start.sh
RUN chmod +x /root/update.sh

CMD /root/start.sh
